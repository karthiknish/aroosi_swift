class UserProfile {
  final String id;
  final String? fullName;
  final String? email;
  final bool? emailVerified;
  final String? plan;
  final String? avatarUrl;
  final DateTime? subscriptionExpiresAt;

  const UserProfile({
    required this.id,
    this.fullName,
    this.email,
    this.emailVerified,
    this.plan,
    this.avatarUrl,
    this.subscriptionExpiresAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Tolerant parsing for email verification flags across backends
    bool? parseEmailVerified(Map<String, dynamic> j) {
      final v =
          j['emailVerified'] ??
          j['isEmailVerified'] ??
          j['verified'] ??
          j['isVerified'];
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase();
        if (s == 'true' || s == 'yes') return true;
        if (s == 'false' || s == 'no') return false;
      }
      // Some APIs expose the negative flag `needsEmailVerification`
      final needs = j['needsEmailVerification'];
      if (needs is bool) return !needs;
      return null;
    }

    return UserProfile(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      emailVerified: parseEmailVerified(json),
      plan: json['subscriptionPlan'] as String? ?? json['plan'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['photoUrl'] as String?,
      subscriptionExpiresAt: json['subscriptionExpiresAt'] != null
          ? DateTime.tryParse(json['subscriptionExpiresAt'].toString())
          : null,
    );
  }

  bool get isSubscribed => plan != null && plan != 'free';
  bool get needsEmailVerification =>
      (email?.isNotEmpty ?? false) && (emailVerified == false);
}

class AuthState {
  final bool isAuthenticated;
  final bool loading;
  final String? error;
  final String? token; // optional: may store a token when available
  final UserProfile? profile;

  const AuthState({
    this.isAuthenticated = false,
    this.loading = false,
    this.error,
    this.token,
    this.profile,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? loading,
    String? error,
    String? token,
    UserProfile? profile,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      loading: loading ?? this.loading,
      error: error,
      token: token ?? this.token,
      profile: profile ?? this.profile,
    );
  }

  static const unauthenticated = AuthState(
    isAuthenticated: false,
    loading: false,
  );
}
