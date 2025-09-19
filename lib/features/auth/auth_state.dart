class UserProfile {
  final String id;
  final String? fullName;
  final String? email;
  final bool? emailVerified;
  final String? plan;
  final String? avatarUrl;
  final DateTime? subscriptionExpiresAt;

  // Extended demographic & preference fields (parity with aroosi-mobile subset)
  final String? aboutMe;
  final String? city;
  final String? country;
  final int? height; // stored in centimeters
  final String? gender;
  final String? preferredGender;
  final String? maritalStatus;
  final String? physicalStatus;
  final String? education;
  final String? occupation;
  final int? annualIncome;
  final String? phoneNumber;
  final String? religion;
  final String? motherTongue;
  final String? ethnicity;
  final String? diet;
  final String? smoking;
  final String? drinking;
  final String? profileFor;
  final bool? hideFromFreeUsers;
  final DateTime? dateOfBirth;
  final int? partnerPreferenceAgeMin;
  final int? partnerPreferenceAgeMax;
  final List<String>? partnerPreferenceCity;
  final List<String>? interests;

  const UserProfile({
    required this.id,
    this.fullName,
    this.email,
    this.emailVerified,
    this.plan,
    this.avatarUrl,
    this.subscriptionExpiresAt,
    this.aboutMe,
    this.city,
    this.country,
    this.height,
    this.gender,
    this.preferredGender,
    this.maritalStatus,
    this.physicalStatus,
    this.education,
    this.occupation,
    this.annualIncome,
    this.phoneNumber,
    this.religion,
    this.motherTongue,
    this.ethnicity,
    this.diet,
    this.smoking,
    this.drinking,
    this.profileFor,
    this.hideFromFreeUsers,
    this.dateOfBirth,
    this.partnerPreferenceAgeMin,
    this.partnerPreferenceAgeMax,
    this.partnerPreferenceCity,
    this.interests,
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

    List<String>? parseStringList(dynamic v) {
      if (v == null) return null;
      if (v is List) {
        return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      if (v is String) {
        if (v.trim().isEmpty) return null;
        // Accept comma separated
        return v
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return null;
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final t = int.tryParse(v);
        return t;
      }
      return null;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    return UserProfile(
      // Accept multiple possible id keys returned by different backends.
      id:
          json['id']?.toString() ??
          json['_id']?.toString() ??
          json['userId']?.toString() ??
          json['uid']?.toString() ??
          '',
      fullName: json['fullName'] as String? ?? json['name'] as String?,
      email: json['email'] as String?,
      emailVerified: parseEmailVerified(json),
      plan: json['subscriptionPlan'] as String? ?? json['plan'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['photoUrl'] as String?,
      subscriptionExpiresAt: json['subscriptionExpiresAt'] != null
          ? DateTime.tryParse(json['subscriptionExpiresAt'].toString())
          : null,
      aboutMe: json['aboutMe'] as String? ?? json['about_me'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      height: parseInt(json['height']),
      gender: json['gender'] as String?,
      preferredGender:
          json['preferredGender'] as String? ??
          json['preferred_gender'] as String?,
      maritalStatus:
          json['maritalStatus'] as String? ?? json['marital_status'] as String?,
      physicalStatus:
          json['physicalStatus'] as String? ??
          json['physical_status'] as String?,
      education: json['education'] as String?,
      occupation: json['occupation'] as String?,
      annualIncome: parseInt(json['annualIncome'] ?? json['annual_income']),
      phoneNumber:
          json['phoneNumber'] as String? ?? json['phone_number'] as String?,
      religion: json['religion'] as String?,
      motherTongue:
          json['motherTongue'] as String? ?? json['mother_tongue'] as String?,
      ethnicity: json['ethnicity'] as String?,
      diet: json['diet'] as String?,
      smoking: json['smoking'] as String?,
      drinking: json['drinking'] as String?,
      profileFor:
          json['profileFor'] as String? ?? json['profile_for'] as String?,
      hideFromFreeUsers:
          json['hideFromFreeUsers'] as bool? ??
          json['hide_from_free_users'] as bool?,
      dateOfBirth: parseDate(json['dateOfBirth'] ?? json['date_of_birth']),
      partnerPreferenceAgeMin: parseInt(
        json['partnerPreferenceAgeMin'] ?? json['partner_preference_age_min'],
      ),
      partnerPreferenceAgeMax: parseInt(
        json['partnerPreferenceAgeMax'] ?? json['partner_preference_age_max'],
      ),
      partnerPreferenceCity: parseStringList(
        json['partnerPreferenceCity'] ?? json['partner_preference_city'],
      ),
      interests: parseStringList(json['interests']),
    );
  }

  bool get isSubscribed => plan != null && plan != 'free';
  bool get needsEmailVerification =>
      (email?.isNotEmpty ?? false) && (emailVerified == false);

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    bool? emailVerified,
    String? plan,
    String? avatarUrl,
    DateTime? subscriptionExpiresAt,
    String? aboutMe,
    String? city,
    String? country,
    int? height,
    String? gender,
    String? preferredGender,
    String? maritalStatus,
    String? physicalStatus,
    String? education,
    String? occupation,
    int? annualIncome,
    String? phoneNumber,
    String? religion,
    String? motherTongue,
    String? ethnicity,
    String? diet,
    String? smoking,
    String? drinking,
    String? profileFor,
    bool? hideFromFreeUsers,
    DateTime? dateOfBirth,
    int? partnerPreferenceAgeMin,
    int? partnerPreferenceAgeMax,
    List<String>? partnerPreferenceCity,
    List<String>? interests,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      plan: plan ?? this.plan,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      aboutMe: aboutMe ?? this.aboutMe,
      city: city ?? this.city,
      country: country ?? this.country,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      preferredGender: preferredGender ?? this.preferredGender,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      physicalStatus: physicalStatus ?? this.physicalStatus,
      education: education ?? this.education,
      occupation: occupation ?? this.occupation,
      annualIncome: annualIncome ?? this.annualIncome,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      religion: religion ?? this.religion,
      motherTongue: motherTongue ?? this.motherTongue,
      ethnicity: ethnicity ?? this.ethnicity,
      diet: diet ?? this.diet,
      smoking: smoking ?? this.smoking,
      drinking: drinking ?? this.drinking,
      profileFor: profileFor ?? this.profileFor,
      hideFromFreeUsers: hideFromFreeUsers ?? this.hideFromFreeUsers,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      partnerPreferenceAgeMin:
          partnerPreferenceAgeMin ?? this.partnerPreferenceAgeMin,
      partnerPreferenceAgeMax:
          partnerPreferenceAgeMax ?? this.partnerPreferenceAgeMax,
      partnerPreferenceCity:
          partnerPreferenceCity ?? this.partnerPreferenceCity,
      interests: interests ?? this.interests,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (fullName != null) 'fullName': fullName,
      if (email != null) 'email': email,
      if (emailVerified != null) 'emailVerified': emailVerified,
      if (plan != null) 'subscriptionPlan': plan,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (subscriptionExpiresAt != null)
        'subscriptionExpiresAt': subscriptionExpiresAt!.toIso8601String(),
      if (aboutMe != null) 'aboutMe': aboutMe,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (height != null) 'height': height,
      if (gender != null) 'gender': gender,
      if (preferredGender != null) 'preferredGender': preferredGender,
      if (maritalStatus != null) 'maritalStatus': maritalStatus,
      if (physicalStatus != null) 'physicalStatus': physicalStatus,
      if (education != null) 'education': education,
      if (occupation != null) 'occupation': occupation,
      if (annualIncome != null) 'annualIncome': annualIncome,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (religion != null) 'religion': religion,
      if (motherTongue != null) 'motherTongue': motherTongue,
      if (ethnicity != null) 'ethnicity': ethnicity,
      if (diet != null) 'diet': diet,
      if (smoking != null) 'smoking': smoking,
      if (drinking != null) 'drinking': drinking,
      if (profileFor != null) 'profileFor': profileFor,
      if (hideFromFreeUsers != null) 'hideFromFreeUsers': hideFromFreeUsers,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (partnerPreferenceAgeMin != null)
        'partnerPreferenceAgeMin': partnerPreferenceAgeMin,
      if (partnerPreferenceAgeMax != null)
        'partnerPreferenceAgeMax': partnerPreferenceAgeMax,
      if (partnerPreferenceCity != null)
        'partnerPreferenceCity': partnerPreferenceCity,
      if (interests != null) 'interests': interests,
    };
  }
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

  /// Simple profile completion heuristic: profile object exists and has an id.
  /// Extend this if you need required fields (e.g., fullName, gender, etc.).
  ///
  /// To enforce stricter onboarding you can change this to something like:
  ///   bool get isProfileComplete => profile != null &&
  ///       profile!.fullName != null && profile!.gender != null &&
  ///       profile!.dateOfBirth != null;
  /// and then adjust the router redirect logic accordingly.
  // Relaxed completeness: accept either a non-empty id OR a non-empty fullName.
  // This avoids false redirects if backend returns an alternate key we haven't mapped yet.
  bool get isProfileComplete =>
      profile != null &&
      ((profile!.id.isNotEmpty) ||
          ((profile!.fullName?.trim().isNotEmpty) ?? false));
}
