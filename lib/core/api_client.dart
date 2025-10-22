import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'env.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'dart:io';
import '../utils/debug_logger.dart';

class ApiClient {
  ApiClient._();

  static final PersistCookieJar _cookieJar = PersistCookieJar(
    ignoreExpires: false,
    storage: FileStorage(_cookiesDirPath()),
  );

  static final Dio dio = Dio(
        BaseOptions(
          baseUrl: Env.apiBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: {
            'Content-Type': 'application/json',
            'x-flutter-client': 'true', // Identify as Flutter client
            'Accept': 'application/json',
          },
        ),
      )
        ..interceptors.add(CookieManager(_cookieJar))
        ..interceptors.add(_ApiLoggingInterceptor());

  static String _cookiesDirPath() {
    // Use a subfolder in system temp to avoid needing platform channels; sufficient for our auth cookies.
    final base = Directory.systemTemp.path;
    final path = '$base/aroosi_cookies';
    Directory(path).createSync(recursive: true);
    return path;
  }

  /// Call if you need to change base URL dynamically (e.g., env switch in tests)
  static void reconfigureBaseUrl() {
    dio.options.baseUrl = Env.apiBaseUrl;
  }
}

/// Optional bearer-token support mirroring RN mobile Axios client.
/// Provide an implementation of [AuthTokenProvider] at app start if needed.
abstract class AuthTokenProvider {
  Future<String?> getToken({bool forceRefresh});
  Future<fb.User?> getCurrentUser();
}

class _BearerTokenInterceptor extends Interceptor {
  final AuthTokenProvider provider;
  _BearerTokenInterceptor(this.provider);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await provider.getToken(forceRefresh: false);
      if (token != null && token.isNotEmpty) {
        // Set Authorization header for Next.js compatibility
        options.headers['Authorization'] = 'Bearer $token';

        // Set additional headers that Next.js APIs expect
        final user = await provider.getCurrentUser();
        if (user != null) {
          options.headers['x-user-id'] = user.uid;
          options.headers['x-user-email'] = user.email ?? '';

          // Set user role if available (default to 'user')
          options.headers['x-user-role'] = 'user'; // This would be determined from user document
        }
      }
    } catch (_) {}
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final original = err.requestOptions;
      if (original.extra['retried'] == true) {
        return handler.next(err);
      }
      original.extra['retried'] = true;
      try {
        final fresh = await provider.getToken(forceRefresh: true);
        if (fresh != null && fresh.isNotEmpty) {
          original.headers['Authorization'] = 'Bearer $fresh';

          // Update additional headers on retry
          final user = await provider.getCurrentUser();
          if (user != null) {
            original.headers['x-user-id'] = user.uid;
            original.headers['x-user-email'] = user.email ?? '';
            original.headers['x-user-role'] = 'user';
          }

          final clone = await ApiClient.dio.fetch(original);
          return handler.resolve(clone);
        }
      } catch (_) {}
    }
    handler.next(err);
  }
}

/// Call this to enable bearer-token auth for the current runtime.
void enableBearerTokenAuth(AuthTokenProvider provider) {
  // Remove any existing bearer token interceptor to avoid duplicates
  ApiClient.dio.interceptors.removeWhere((i) => i is _BearerTokenInterceptor);
  ApiClient.dio.interceptors.add(_BearerTokenInterceptor(provider));
}

/// Comprehensive API logging interceptor for debugging all HTTP requests
class _ApiLoggingInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final method = options.method.toUpperCase();
    final url = options.uri.toString();
    final headers = options.headers;
    final hasAuth = headers['Authorization'] != null;

    logApi('🚀 $method $url | Auth: ${hasAuth ? "Yes" : "No"}');

    // Log request body if present (but truncate large payloads)
    if (options.data != null) {
      String bodyStr = options.data.toString();
      if (bodyStr.length > 200) {
        bodyStr =
            '${bodyStr.substring(0, 200)}... [truncated, ${bodyStr.length} chars]';
      }
      logApi('📦 Request Body: $bodyStr');
    }

    // Log query parameters if present
    if (options.queryParameters.isNotEmpty) {
      logApi('🔍 Query Params: ${options.queryParameters}');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final method = response.requestOptions.method.toUpperCase();
    final url = response.requestOptions.uri.toString();
    final status = response.statusCode;
    final duration =
        response.requestOptions.receiveTimeout?.inMilliseconds ?? 0;

    logApi('✅ $method $url | Status: $status | Duration: ${duration}ms');

    // Log response data if present (but truncate large responses)
    if (response.data != null) {
      String dataStr = response.data.toString();
      if (dataStr.length > 300) {
        dataStr =
            '${dataStr.substring(0, 300)}... [truncated, ${dataStr.length} chars]';
      }
      logApi('📄 Response Data: $dataStr');
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final method = err.requestOptions.method.toUpperCase();
    final url = err.requestOptions.uri.toString();
    final status = err.response?.statusCode ?? 'UNKNOWN';
    final errorType = err.type.toString();

    logApi('❌ $method $url | Status: $status | Type: $errorType');

    // Log error details
    if (err.error != null) {
      logApi('💥 Error: ${err.error}');
    }

    // Log response error data if present
    if (err.response?.data != null) {
      String errorDataStr = err.response!.data.toString();
      if (errorDataStr.length > 300) {
        errorDataStr =
            '${errorDataStr.substring(0, 300)}... [truncated, ${errorDataStr.length} chars]';
      }
      logApi('📄 Error Response: $errorDataStr');
    }

    handler.next(err);
  }
}

/// FirebaseAuth-backed token provider to match Next.js auth requirements
class FirebaseAuthTokenProvider implements AuthTokenProvider {
  final fb.FirebaseAuth _auth;
  FirebaseAuthTokenProvider([fb.FirebaseAuth? auth])
    : _auth = auth ?? fb.FirebaseAuth.instance;

  @override
  Future<String?> getToken({bool forceRefresh = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
            return null;
      }

      final idToken = await user.getIdToken(forceRefresh);
        return idToken;
    } catch (e) {
          return null;
    }
  }

  @override
  Future<fb.User?> getCurrentUser() async {
    try {
      return _auth.currentUser;
    } catch (e) {
          return null;
    }
  }
}
