class AuthState {
  final String? token;
  final bool loading;
  final String? error;

  const AuthState({this.token, this.loading = false, this.error});

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  AuthState copyWith({String? token, bool? loading, String? error}) {
    return AuthState(
      token: token ?? this.token,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  static const unauthenticated = AuthState(token: null, loading: false);
}
