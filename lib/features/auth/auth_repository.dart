import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:aroosi_flutter/core/api_client.dart';
import 'package:aroosi_flutter/core/google_signin_helper.dart';

class AuthRepository {
  final Dio _dio;
  AuthRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio {
    // Ensure at least one usage to avoid unused warning; attach a no-op interceptor
    _dio.interceptors.removeWhere((i) => i.runtimeType.toString() == '_Noop');
  }

  // Helper no longer needed; keep repository minimal.

  // Removed legacy multi-method exchange helper; bearer-token auth is used now.

  /// Sign in with Google using Firebase (mirrors RN). Backend auth uses bearer tokens via interceptor.
  Future<void> signInWithGoogle() async {
    final googleSignIn = buildGoogleSignIn();
    GoogleSignInAccount? account = await googleSignIn.signIn();
    if (account == null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/google'),
        error: 'Google sign-in canceled',
      );
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    final accessToken = auth.accessToken;
    if (idToken == null && accessToken == null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/google'),
        error: 'Missing Google tokens',
      );
    }
    final credential = fb.GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );
    await fb.FirebaseAuth.instance.signInWithCredential(credential);
    // No direct backend call here; bearer token interceptor will authenticate subsequent requests.
  }

  /// Sign in with email/password via Firebase
  Future<void> signin({required String email, required String password}) async {
    try {
      await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on fb.FirebaseAuthException catch (e) {
      String msg = 'Sign in failed';
      if (e.code == 'user-not-found') msg = 'No account for this email';
      if (e.code == 'wrong-password') msg = 'Invalid password';
      if (e.code == 'too-many-requests') msg = 'Too many attempts. Try later';
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        error: msg,
      );
    }
  }

  /// Sign up and create a profile (minimal fields for now)
  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _dio.post(
        '/auth/signup',
        data: {
          'email': email,
          'password': password,
          'fullName': name,
          // Optionally: include a minimal profile payload similar to RN
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      // Some backends require a subsequent reset-password to finalize password; skip unless needed.
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? ((e.response?.data as Map)['error'] ??
                (e.response?.data as Map)['message'] ??
                'Sign up failed')
          : 'Sign up failed';
      throw DioException(
        requestOptions: e.requestOptions,
        error: msg,
        response: e.response,
        type: e.type,
      );
    }
  }

  /// Check current session; returns true if authenticated
  Future<bool> me() async {
    try {
      // RN uses /api/auth/me with bearer; support both
      Response res;
      try {
        res = await _dio.get('/api/auth/me');
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          res = await _dio.get('/auth/me');
        } else {
          rethrow;
        }
      }
      return res.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return false;
      return false;
    }
  }

  /// Logout session (server clears cookies)
  Future<void> logout() async {
    try {
      // Best effort: clear Firebase session; backend uses bearer so no server logout needed
      try {
        await fb.FirebaseAuth.instance.signOut();
      } catch (_) {}
      // Try calling server logout if it exists (non-fatal)
      try {
        await _dio.post('/auth/logout');
      } catch (_) {}
    } catch (_) {
      // ignore
    }
  }

  /// Fetch the current user's profile
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      // RN updates profile via /api/user/me
      Response res;
      try {
        res = await _dio.get('/api/user/me');
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          res = await _dio.get('/profile');
        } else {
          rethrow;
        }
      }
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      rethrow;
    }
  }

  /// Request forgot password email
  Future<void> requestPasswordReset(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? ((e.response?.data as Map)['error'] ??
                (e.response?.data as Map)['message'] ??
                'Failed to request password reset')
          : 'Failed to request password reset';
      throw DioException(
        requestOptions: e.requestOptions,
        error: msg,
        response: e.response,
        type: e.type,
      );
    }
  }

  /// Reset password directly
  Future<void> resetPassword(String email, String password) async {
    try {
      await _dio.post(
        '/auth/reset-password',
        data: {'email': email, 'password': password},
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? ((e.response?.data as Map)['error'] ??
                (e.response?.data as Map)['message'] ??
                'Failed to reset password')
          : 'Failed to reset password';
      throw DioException(
        requestOptions: e.requestOptions,
        error: msg,
        response: e.response,
        type: e.type,
      );
    }
  }

  /// Resend the email verification link. Returns true if the request appears successful.
  Future<bool> resendEmailVerification() async {
    final paths = <String>[
      '/auth/email/resend',
      '/auth/resend-verification',
      '/auth/verify-email/resend',
      '/email/verify/resend',
    ];
    for (final p in paths) {
      try {
        final res = await _dio.post(p);
        if (res.statusCode != null &&
            res.statusCode! >= 200 &&
            res.statusCode! < 300)
          return true;
      } on DioException catch (e) {
        // try next path on 404/405, otherwise rethrow on hard failures
        final sc = e.response?.statusCode ?? 0;
        if (sc == 404 || sc == 405) {
          continue;
        }
        // some backends return 200 with error body; continue fallbacks on 4xx
        if (sc >= 400 && sc < 500) continue;
      }
    }
    return false;
  }

  /// Reload the user's email verification status by refetching profile.
  /// Returns true if the refreshed profile indicates verified.
  Future<bool> refreshEmailVerified() async {
    try {
      final profile = await getProfile();
      if (profile == null) return false;
      final v =
          profile['emailVerified'] ??
          profile['isEmailVerified'] ??
          profile['verified'] ??
          profile['isVerified'];
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String)
        return v.toLowerCase() == 'true' || v.toLowerCase() == 'yes';
      final needs = profile['needsEmailVerification'];
      if (needs is bool) return !needs;
      return false;
    } catch (_) {
      return false;
    }
  }
}
