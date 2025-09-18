import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repo;

  @override
  AuthState build() {
    _repo = ref.read(authRepositoryProvider);
    // Start loading then bootstrap session
    _bootstrap();
    return const AuthState(loading: true);
  }

  Future<void> _bootstrap() async {
    final ok = await _repo.me();
    if (ok) {
      final json = await _repo.getProfile();
      state = AuthState(
        isAuthenticated: true,
        loading: false,
        profile: json == null ? null : UserProfile.fromJson(json),
      );
    } else {
      state = const AuthState(isAuthenticated: false, loading: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.signin(email: email, password: password);
      final ok = await _repo.me();
      if (ok) {
        final json = await _repo.getProfile();
        state = AuthState(
          isAuthenticated: true,
          loading: false,
          profile: json == null ? null : UserProfile.fromJson(json),
        );
      } else {
        state = const AuthState(isAuthenticated: false, loading: false);
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.signInWithGoogle();
      final ok = await _repo.me();
      if (ok) {
        final json = await _repo.getProfile();
        state = AuthState(
          isAuthenticated: true,
          loading: false,
          profile: json == null ? null : UserProfile.fromJson(json),
        );
      } else {
        state = const AuthState(isAuthenticated: false, loading: false);
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> signup(String name, String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.signup(name: name, email: email, password: password);
      // After signup, some backends may not auto-login; attempt me() to detect session
      final ok = await _repo.me();
      if (ok) {
        final json = await _repo.getProfile();
        state = AuthState(
          isAuthenticated: true,
          loading: false,
          profile: json == null ? null : UserProfile.fromJson(json),
        );
      } else {
        state = const AuthState(isAuthenticated: false, loading: false);
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(isAuthenticated: false, loading: false);
  }

  Future<void> requestPasswordReset(String email) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.requestPasswordReset(email);
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> resetPassword(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.resetPassword(email, password);
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// Resend the email verification link; returns true if request accepted.
  Future<bool> resendEmailVerification() async {
    final ok = await _repo.resendEmailVerification();
    return ok;
  }

  /// Refresh the profile and update state; returns whether email is verified now.
  Future<bool> refreshAndCheckEmailVerified() async {
    try {
      final verified = await _repo.refreshEmailVerified();
      // Always refresh profile to update other fields too
      final json = await _repo.getProfile();
      state = state.copyWith(
        profile: json == null ? null : UserProfile.fromJson(json),
      );
      return verified;
    } catch (_) {
      return false;
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
