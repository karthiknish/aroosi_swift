import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repo;

  @override
  AuthState build() {
    _repo = ref.read(authRepositoryProvider);
    // Start loading then bootstrap token
    _bootstrap();
    return const AuthState(loading: true);
  }

  Future<void> _bootstrap() async {
    final token = await _repo.loadToken();
    state = AuthState(token: token, loading: false);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final token = await _repo.login(email: email, password: password);
      await _repo.saveToken(token);
      state = AuthState(token: token, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> signup(String name, String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final token = await _repo.signup(name: name, email: email, password: password);
      await _repo.saveToken(token);
      state = AuthState(token: token, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _repo.clearToken();
    state = const AuthState(token: null, loading: false);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
