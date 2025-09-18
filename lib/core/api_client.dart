import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'env.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'dart:io';

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
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(CookieManager(_cookieJar));

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
        options.headers['Authorization'] = 'Bearer $token';
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

/// FirebaseAuth-backed token provider to mirror RN bearer token approach
class FirebaseAuthTokenProvider implements AuthTokenProvider {
  final fb.FirebaseAuth _auth;
  FirebaseAuthTokenProvider([fb.FirebaseAuth? auth])
    : _auth = auth ?? fb.FirebaseAuth.instance;

  @override
  Future<String?> getToken({bool forceRefresh = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      return await user.getIdToken(forceRefresh);
    } catch (_) {
      return null;
    }
  }
}
