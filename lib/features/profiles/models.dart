import 'package:equatable/equatable.dart';

/// Cultural and religious profile information for compatibility matching
class CulturalProfile extends Equatable {
  const CulturalProfile({
    required this.religion,
    required this.religiousPractice,
    required this.motherTongue,
    required this.languages,
    required this.familyValues,
    required this.marriageViews,
    required this.traditionalValues,
    required this.familyApprovalImportance,
    this.religionImportance = 5,
    this.cultureImportance = 5,
    this.familyBackground,
    this.ethnicity,
  });

  final String? religion; // islam, christianity, hinduism, etc.
  final String? religiousPractice; // very_practicing, moderately_practicing, not_practicing, etc.
  final String? motherTongue; // native language
  final List<String> languages; // languages spoken
  final String? familyValues; // traditional, modern, mixed
  final String? marriageViews; // love_marriage, arranged_marriage, both
  final String? traditionalValues; // importance of traditions
  final String? familyApprovalImportance; // very_important, somewhat_important, not_important
  final int religionImportance; // 1-10 scale
  final int cultureImportance; // 1-10 scale
  final String? familyBackground; // description of family
  final String? ethnicity; // ethnic background

  CulturalProfile copyWith({
    String? religion,
    String? religiousPractice,
    String? motherTongue,
    List<String>? languages,
    String? familyValues,
    String? marriageViews,
    String? traditionalValues,
    String? familyApprovalImportance,
    int? religionImportance,
    int? cultureImportance,
    String? familyBackground,
    String? ethnicity,
  }) => CulturalProfile(
    religion: religion ?? this.religion,
    religiousPractice: religiousPractice ?? this.religiousPractice,
    motherTongue: motherTongue ?? this.motherTongue,
    languages: languages ?? this.languages,
    familyValues: familyValues ?? this.familyValues,
    marriageViews: marriageViews ?? this.marriageViews,
    traditionalValues: traditionalValues ?? this.traditionalValues,
    familyApprovalImportance: familyApprovalImportance ?? this.familyApprovalImportance,
    religionImportance: religionImportance ?? this.religionImportance,
    cultureImportance: cultureImportance ?? this.cultureImportance,
    familyBackground: familyBackground ?? this.familyBackground,
    ethnicity: ethnicity ?? this.ethnicity,
  );

  static CulturalProfile fromJson(Map<String, dynamic> json) => CulturalProfile(
    religion: json['religion']?.toString(),
    religiousPractice: json['religiousPractice']?.toString(),
    motherTongue: json['motherTongue']?.toString(),
    languages: (json['languages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    familyValues: json['familyValues']?.toString(),
    marriageViews: json['marriageViews']?.toString(),
    traditionalValues: json['traditionalValues']?.toString(),
    familyApprovalImportance: json['familyApprovalImportance']?.toString(),
    religionImportance: json['religionImportance'] is int ? json['religionImportance'] : 5,
    cultureImportance: json['cultureImportance'] is int ? json['cultureImportance'] : 5,
    familyBackground: json['familyBackground']?.toString(),
    ethnicity: json['ethnicity']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    if (religion != null) 'religion': religion,
    if (religiousPractice != null) 'religiousPractice': religiousPractice,
    if (motherTongue != null) 'motherTongue': motherTongue,
    'languages': languages,
    if (familyValues != null) 'familyValues': familyValues,
    if (marriageViews != null) 'marriageViews': marriageViews,
    if (traditionalValues != null) 'traditionalValues': traditionalValues,
    if (familyApprovalImportance != null) 'familyApprovalImportance': familyApprovalImportance,
    'religionImportance': religionImportance,
    'cultureImportance': cultureImportance,
    if (familyBackground != null) 'familyBackground': familyBackground,
    if (ethnicity != null) 'ethnicity': ethnicity,
  };

  @override
  List<Object?> get props => [
    religion,
    religiousPractice,
    motherTongue,
    languages,
    familyValues,
    marriageViews,
    traditionalValues,
    familyApprovalImportance,
    religionImportance,
    cultureImportance,
    familyBackground,
    ethnicity,
  ];
}

/// Family approval workflow for traditional matchmaking
class FamilyApprovalRequest extends Equatable {
  const FamilyApprovalRequest({
    required this.id,
    required this.requesterId,
    required this.targetUserId,
    required this.status,
    required this.createdAt,
    required this.message,
    this.familyMemberId,
    this.familyMemberName,
    this.familyMemberRelation,
    this.response,
    this.respondedAt,
    this.approved = false,
  });

  final String id;
  final String requesterId;
  final String targetUserId;
  final String status; // 'pending', 'approved', 'rejected', 'cancelled'
  final int createdAt;
  final String message;
  final String? familyMemberId;
  final String? familyMemberName;
  final String? familyMemberRelation;
  final String? response;
  final int? respondedAt;
  final bool approved;

  FamilyApprovalRequest copyWith({
    String? id,
    String? requesterId,
    String? targetUserId,
    String? status,
    int? createdAt,
    String? message,
    String? familyMemberId,
    String? familyMemberName,
    String? familyMemberRelation,
    String? response,
    int? respondedAt,
    bool? approved,
  }) => FamilyApprovalRequest(
    id: id ?? this.id,
    requesterId: requesterId ?? this.requesterId,
    targetUserId: targetUserId ?? this.targetUserId,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    message: message ?? this.message,
    familyMemberId: familyMemberId ?? this.familyMemberId,
    familyMemberName: familyMemberName ?? this.familyMemberName,
    familyMemberRelation: familyMemberRelation ?? this.familyMemberRelation,
    response: response ?? this.response,
    respondedAt: respondedAt ?? this.respondedAt,
    approved: approved ?? this.approved,
  );

  static FamilyApprovalRequest fromJson(Map<String, dynamic> json) => FamilyApprovalRequest(
    id: json['id']?.toString() ?? '',
    requesterId: json['requesterId']?.toString() ?? '',
    targetUserId: json['targetUserId']?.toString() ?? '',
    status: json['status']?.toString() ?? 'pending',
    createdAt: json['createdAt'] is int ? json['createdAt'] : DateTime.now().millisecondsSinceEpoch,
    message: json['message']?.toString() ?? '',
    familyMemberId: json['familyMemberId']?.toString(),
    familyMemberName: json['familyMemberName']?.toString(),
    familyMemberRelation: json['familyMemberRelation']?.toString(),
    response: json['response']?.toString(),
    respondedAt: json['respondedAt'] is int ? json['respondedAt'] : null,
    approved: json['approved'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'requesterId': requesterId,
    'targetUserId': targetUserId,
    'status': status,
    'createdAt': createdAt,
    'message': message,
    if (familyMemberId != null) 'familyMemberId': familyMemberId,
    if (familyMemberName != null) 'familyMemberName': familyMemberName,
    if (familyMemberRelation != null) 'familyMemberRelation': familyMemberRelation,
    if (response != null) 'response': response,
    if (respondedAt != null) 'respondedAt': respondedAt,
    'approved': approved,
  };

  @override
  List<Object?> get props => [
    id,
    requesterId,
    targetUserId,
    status,
    createdAt,
    message,
    familyMemberId,
    familyMemberName,
    familyMemberRelation,
    response,
    respondedAt,
    approved,
  ];
}

/// Supervised communication for traditional courtship
class SupervisedConversation extends Equatable {
  const SupervisedConversation({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    required this.supervisorId,
    required this.status,
    required this.createdAt,
    this.conversationId,
    this.rules,
    this.timeLimit,
    this.topicRestrictions,
    this.lastActivity,
  });

  final String id;
  final String participant1Id;
  final String participant2Id;
  final String supervisorId;
  final String status; // 'active', 'paused', 'completed', 'terminated'
  final int createdAt;
  final String? conversationId;
  final List<String>? rules; // communication rules
  final int? timeLimit; // minutes per day
  final List<String>? topicRestrictions; // forbidden topics
  final int? lastActivity;

  SupervisedConversation copyWith({
    String? id,
    String? participant1Id,
    String? participant2Id,
    String? supervisorId,
    String? status,
    int? createdAt,
    String? conversationId,
    List<String>? rules,
    int? timeLimit,
    List<String>? topicRestrictions,
    int? lastActivity,
  }) => SupervisedConversation(
    id: id ?? this.id,
    participant1Id: participant1Id ?? this.participant1Id,
    participant2Id: participant2Id ?? this.participant2Id,
    supervisorId: supervisorId ?? this.supervisorId,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    conversationId: conversationId ?? this.conversationId,
    rules: rules ?? this.rules,
    timeLimit: timeLimit ?? this.timeLimit,
    topicRestrictions: topicRestrictions ?? this.topicRestrictions,
    lastActivity: lastActivity ?? this.lastActivity,
  );

  static SupervisedConversation fromJson(Map<String, dynamic> json) => SupervisedConversation(
    id: json['id']?.toString() ?? '',
    participant1Id: json['participant1Id']?.toString() ?? '',
    participant2Id: json['participant2Id']?.toString() ?? '',
    supervisorId: json['supervisorId']?.toString() ?? '',
    status: json['status']?.toString() ?? 'active',
    createdAt: json['createdAt'] is int ? json['createdAt'] : DateTime.now().millisecondsSinceEpoch,
    conversationId: json['conversationId']?.toString(),
    rules: (json['rules'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    timeLimit: json['timeLimit'] is int ? json['timeLimit'] : null,
    topicRestrictions: (json['topicRestrictions'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    lastActivity: json['lastActivity'] is int ? json['lastActivity'] : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'participant1Id': participant1Id,
    'participant2Id': participant2Id,
    'supervisorId': supervisorId,
    'status': status,
    'createdAt': createdAt,
    if (conversationId != null) 'conversationId': conversationId,
    if (rules != null) 'rules': rules,
    if (timeLimit != null) 'timeLimit': timeLimit,
    if (topicRestrictions != null) 'topicRestrictions': topicRestrictions,
    if (lastActivity != null) 'lastActivity': lastActivity,
  };

  @override
  List<Object?> get props => [
    id,
    participant1Id,
    participant2Id,
    supervisorId,
    status,
    createdAt,
    conversationId,
    rules,
    timeLimit,
    topicRestrictions,
    lastActivity,
  ];
}

class ShortlistEntry extends Equatable {
  const ShortlistEntry({
    required this.userId,
    required this.createdAt,
    this.fullName,
    this.profileImageUrls,
    this.note,
  });

  final String userId;
  final int createdAt; // epoch millis
  final String? fullName;
  final List<String>? profileImageUrls;
  final String? note;

  ShortlistEntry copyWith({
    String? userId,
    int? createdAt,
    String? fullName,
    List<String>? profileImageUrls,
    String? note,
  }) => ShortlistEntry(
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    fullName: fullName ?? this.fullName,
    profileImageUrls: profileImageUrls ?? this.profileImageUrls,
    note: note ?? this.note,
  );

  static ShortlistEntry fromJson(Map<String, dynamic> json) {
    return ShortlistEntry(
      userId: json['userId']?.toString() ?? '',
      createdAt: json['createdAt'] is int
          ? json['createdAt']
          : int.tryParse(json['createdAt']?.toString() ?? '') ??
                DateTime.now().millisecondsSinceEpoch,
      fullName: json['fullName']?.toString(),
      profileImageUrls: json['profileImageUrls'] is List
          ? (json['profileImageUrls'] as List).map((e) => e.toString()).toList()
          : null,
      note: json['note']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
    userId,
    createdAt,
    fullName,
    profileImageUrls,
    note,
  ];
}

class ProfileSummary extends Equatable {
  const ProfileSummary({
    required this.id,
    required this.displayName,
    this.age,
    this.city,
    this.avatarUrl,
    this.isFavorite = false,
    this.isShortlisted = false,
    this.lastActive,
  });

  final String id;
  final String displayName;
  final int? age;
  final String? city;
  final String? avatarUrl;
  final bool isFavorite;
  final bool isShortlisted;
  final DateTime? lastActive;

  ProfileSummary copyWith({
    String? id,
    String? displayName,
    int? age,
    String? city,
    String? avatarUrl,
    bool? isFavorite,
    bool? isShortlisted,
    DateTime? lastActive,
  }) => ProfileSummary(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    age: age ?? this.age,
    city: city ?? this.city,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    isFavorite: isFavorite ?? this.isFavorite,
    isShortlisted: isShortlisted ?? this.isShortlisted,
    lastActive: lastActive ?? this.lastActive,
  );

  static ProfileSummary fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map<String, dynamic>
        ? (json['profile'] as Map).cast<String, dynamic>()
        : null;

    final id =
        _firstNonEmpty([
          json['userId'],
          json['id'],
          json['_id'],
          json['profileId'],
          profile?['id'],
          profile?['_id'],
        ])?.toString() ??
        '';

    final displayName = _firstNonEmpty([
      profile?['fullName'],
      json['fullName'],
      json['name'],
      profile?['displayName'],
    ])?.toString().trim();

    final city = _firstNonEmpty([
      profile?['city'],
      json['city'],
      profile?['location'],
    ])?.toString();

    final avatar = _resolveAvatarUrl(json, profile);

    // Robust age extraction avoiding nested string interpolation quoting issues
    final dynamic ageRawCandidate = json['age'] ?? profile?['age'];
    int? explicitAge;
    if (ageRawCandidate is int) {
      explicitAge = ageRawCandidate;
    } else if (ageRawCandidate is String) {
      explicitAge = int.tryParse(ageRawCandidate.trim());
    }

    final dob = _firstNonEmpty([
      profile?['dateOfBirth'],
      profile?['dob'],
      json['dateOfBirth'],
      json['dob'],
    ])?.toString();
    final calculatedAge = _ageFromDob(dob) ?? explicitAge;

    final lastActiveRaw = _firstNonEmpty([
      json['lastActive'],
      profile?['lastActive'],
    ])?.toString();

    return ProfileSummary(
      id: id,
      displayName: (displayName == null || displayName.isEmpty)
          ? 'Unknown'
          : displayName,
      age: calculatedAge,
      city: city?.isEmpty ?? true ? null : city,
      avatarUrl: avatar,
      isFavorite: json['isFavorite'] == true || json['favorite'] == true,
      isShortlisted:
          json['isShortlisted'] == true || json['shortlisted'] == true,
      lastActive: lastActiveRaw != null
          ? DateTime.tryParse(lastActiveRaw)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    displayName,
    age,
    city,
    avatarUrl,
    isFavorite,
    isShortlisted,
    lastActive,
  ];
}

String? _firstNonEmpty(Iterable<dynamic> values) {
  for (final value in values) {
    if (value == null) continue;
    final str = value.toString();
    if (str.trim().isEmpty) continue;
    return str;
  }
  return null;
}

int? _ageFromDob(String? isoString) {
  if (isoString == null || isoString.isEmpty) return null;
  final dob = DateTime.tryParse(isoString);
  if (dob == null) return null;
  final now = DateTime.now();
  int age = now.year - dob.year;
  final hasHadBirthday =
      now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
  if (!hasHadBirthday) age -= 1;
  if (age < 0) return null;
  return age;
}

String? _resolveAvatarUrl(
  Map<String, dynamic> json,
  Map<String, dynamic>? profile,
) {
  String? fromList(List<dynamic>? list) {
    if (list == null) return null;
    for (final entry in list) {
      if (entry == null) continue;
      final url = entry.toString();
      if (url.trim().isNotEmpty) return url;
    }
    return null;
  }

  final urls = [
    fromList(json['profileImageUrls'] as List<dynamic>?),
    fromList(profile?['profileImageUrls'] as List<dynamic>?),
    fromList(json['images'] as List<dynamic>?),
    fromList(profile?['images'] as List<dynamic>?),
    json['avatar']?.toString(),
    json['avatarUrl']?.toString(),
    profile?['avatar']?.toString(),
    profile?['avatarUrl']?.toString(),
  ];
  return _firstNonEmpty(urls);
}

class MatchEntry extends Equatable {
  const MatchEntry({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.status,
    required this.createdAt,
    required this.conversationId,
    this.lastMessageText,
    this.lastMessageAt,
    this.otherUserId,
    this.otherUserName,
    this.otherUserImage,
    this.unreadCount = 0,
    this.isMutual = false,
    this.isBlocked = false,
  });

  final String id;
  final String user1Id;
  final String user2Id;
  final String status;
  final int createdAt; // epoch millis
  final String conversationId;
  final String? lastMessageText;
  final int? lastMessageAt;
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserImage;
  final int unreadCount;
  final bool isMutual;
  final bool isBlocked;

  MatchEntry copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    String? status,
    int? createdAt,
    String? conversationId,
    String? lastMessageText,
    int? lastMessageAt,
    String? otherUserId,
    String? otherUserName,
    String? otherUserImage,
    int? unreadCount,
    bool? isMutual,
    bool? isBlocked,
  }) => MatchEntry(
    id: id ?? this.id,
    user1Id: user1Id ?? this.user1Id,
    user2Id: user2Id ?? this.user2Id,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    conversationId: conversationId ?? this.conversationId,
    lastMessageText: lastMessageText ?? this.lastMessageText,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    otherUserId: otherUserId ?? this.otherUserId,
    otherUserName: otherUserName ?? this.otherUserName,
    otherUserImage: otherUserImage ?? this.otherUserImage,
    unreadCount: unreadCount ?? this.unreadCount,
    isMutual: isMutual ?? this.isMutual,
    isBlocked: isBlocked ?? this.isBlocked,
  );

  static MatchEntry fromJson(Map<String, dynamic> json) {
    // Handle NextJS API response format: { userId, fullName, profileImageUrls, createdAt }
    final userId = json['userId']?.toString() ?? json['id']?.toString() ?? '';
    final fullName = json['fullName']?.toString() ?? '';
    final profileImageUrls = json['profileImageUrls'] as List<dynamic>? ?? [];
    final avatarUrl = profileImageUrls.isNotEmpty ? profileImageUrls.first.toString() : null;
    
    return MatchEntry(
      id: userId.isNotEmpty ? 'match_$userId' : json['id']?.toString() ?? '',
      user1Id: userId, // Assume current user is user1 for simplicity
      user2Id: userId,
      status: 'matched', // NextJS only returns matched profiles
      createdAt: json['createdAt'] is int
          ? json['createdAt']
          : int.tryParse(json['createdAt']?.toString() ?? '') ??
                DateTime.now().millisecondsSinceEpoch,
      conversationId: '', // Would need separate API call or conversation logic
      lastMessageText: json['lastMessageText']?.toString(),
      lastMessageAt: json['lastMessageAt'] is int
          ? json['lastMessageAt']
          : int.tryParse(json['lastMessageAt']?.toString() ?? ''),
      otherUserId: userId,
      otherUserName: fullName,
      otherUserImage: avatarUrl,
      unreadCount: json['unreadCount'] is int ? json['unreadCount'] : 0,
      isMutual: json['isMutual'] == true || json['mutual'] == true,
      isBlocked: json['isBlocked'] == true || json['blocked'] == true,
    );
  }

  @override
  List<Object?> get props => [
    id,
    user1Id,
    user2Id,
    status,
    createdAt,
    conversationId,
    lastMessageText,
    lastMessageAt,
    otherUserId,
    otherUserName,
    otherUserImage,
    unreadCount,
    isMutual,
    isBlocked,
  ];
}

class InterestEntry extends Equatable {
  const InterestEntry({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.fromSnapshot,
    this.toSnapshot,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final String
  status; // 'pending', 'accepted', 'rejected', 'reciprocated', 'withdrawn'
  final int createdAt; // epoch millis
  final int updatedAt; // epoch millis
  final Map<String, dynamic>? fromSnapshot;
  final Map<String, dynamic>? toSnapshot;

  InterestEntry copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? status,
    int? createdAt,
    int? updatedAt,
    Map<String, dynamic>? fromSnapshot,
    Map<String, dynamic>? toSnapshot,
  }) => InterestEntry(
    id: id ?? this.id,
    fromUserId: fromUserId ?? this.fromUserId,
    toUserId: toUserId ?? this.toUserId,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    fromSnapshot: fromSnapshot ?? this.fromSnapshot,
    toSnapshot: toSnapshot ?? this.toSnapshot,
  );

  static InterestEntry fromJson(Map<String, dynamic> json) {
    return InterestEntry(
      id: json['id']?.toString() ?? '',
      fromUserId: json['fromUserId']?.toString() ?? '',
      toUserId: json['toUserId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt'] is int
          ? json['createdAt']
          : int.tryParse(json['createdAt']?.toString() ?? '') ??
                DateTime.now().millisecondsSinceEpoch,
      updatedAt: json['updatedAt'] is int
          ? json['updatedAt']
          : int.tryParse(json['updatedAt']?.toString() ?? '') ??
                DateTime.now().millisecondsSinceEpoch,
      fromSnapshot: json['fromSnapshot'] as Map<String, dynamic>?,
      toSnapshot: json['toSnapshot'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fromUserId,
    toUserId,
    status,
    createdAt,
    updatedAt,
    fromSnapshot,
    toSnapshot,
  ];
}

class PagedResponse<T> {
  const PagedResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    this.nextPage,
    this.nextCursor,
    bool? hasMore,
  }) : _hasMoreOverride = hasMore;

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
  final int? nextPage;
  final String? nextCursor;
  final bool? _hasMoreOverride;

  bool get hasMore {
    if (_hasMoreOverride != null) {
      return _hasMoreOverride!; // ignore: unnecessary_non_null_assertion
    }
    if (nextCursor != null && nextCursor!.isNotEmpty) return true;
    final np = nextPage;
    if (np != null) return np > page;
    return items.length < total;
  }
}

class SearchFilters {
  const SearchFilters({
    this.query,
    this.minAge,
    this.maxAge,
    this.city,
    this.country,
    this.sort,
    this.cursor,
    this.pageSize,
    this.preferredGender,
    // Cultural compatibility filters
    this.religion,
    this.religiousPractice,
    this.motherTongue,
    this.languages,
    this.familyValues,
    this.marriageViews,
    this.ethnicity,
    this.minReligionImportance,
    this.maxReligionImportance,
    this.minCultureImportance,
    this.maxCultureImportance,
  });

  static const Object _unset = Object();

  final String? query;
  final int? minAge;
  final int? maxAge;
  final String? city;
  final String? country;
  final String? sort; // e.g., 'recent', 'distance', 'newest'
  final String? cursor;
  final int? pageSize;
  final String? preferredGender;
  // Cultural compatibility filters
  final String? religion;
  final String? religiousPractice;
  final String? motherTongue;
  final List<String>? languages;
  final String? familyValues;
  final String? marriageViews;
  final String? ethnicity;
  final int? minReligionImportance;
  final int? maxReligionImportance;
  final int? minCultureImportance;
  final int? maxCultureImportance;

  SearchFilters copyWith({
    Object? query = _unset,
    Object? minAge = _unset,
    Object? maxAge = _unset,
    Object? city = _unset,
    Object? country = _unset,
    Object? sort = _unset,
    Object? cursor = _unset,
    Object? pageSize = _unset,
    Object? preferredGender = _unset,
    // Cultural compatibility filters
    Object? religion = _unset,
    Object? religiousPractice = _unset,
    Object? motherTongue = _unset,
    Object? languages = _unset,
    Object? familyValues = _unset,
    Object? marriageViews = _unset,
    Object? ethnicity = _unset,
    Object? minReligionImportance = _unset,
    Object? maxReligionImportance = _unset,
    Object? minCultureImportance = _unset,
    Object? maxCultureImportance = _unset,
  }) => SearchFilters(
    query: query == _unset ? this.query : query as String?,
    minAge: minAge == _unset ? this.minAge : minAge as int?,
    maxAge: maxAge == _unset ? this.maxAge : maxAge as int?,
    city: city == _unset ? this.city : city as String?,
    country: country == _unset ? this.country : country as String?,
    sort: sort == _unset ? this.sort : sort as String?,
    cursor: cursor == _unset ? this.cursor : cursor as String?,
    pageSize: pageSize == _unset ? this.pageSize : pageSize as int?,
    preferredGender: preferredGender == _unset
        ? this.preferredGender
        : preferredGender as String?,
    // Cultural compatibility filters
    religion: religion == _unset ? this.religion : religion as String?,
    religiousPractice: religiousPractice == _unset ? this.religiousPractice : religiousPractice as String?,
    motherTongue: motherTongue == _unset ? this.motherTongue : motherTongue as String?,
    languages: languages == _unset ? this.languages : languages as List<String>?,
    familyValues: familyValues == _unset ? this.familyValues : familyValues as String?,
    marriageViews: marriageViews == _unset ? this.marriageViews : marriageViews as String?,
    ethnicity: ethnicity == _unset ? this.ethnicity : ethnicity as String?,
    minReligionImportance: minReligionImportance == _unset ? this.minReligionImportance : minReligionImportance as int?,
    maxReligionImportance: maxReligionImportance == _unset ? this.maxReligionImportance : maxReligionImportance as int?,
    minCultureImportance: minCultureImportance == _unset ? this.minCultureImportance : minCultureImportance as int?,
    maxCultureImportance: maxCultureImportance == _unset ? this.maxCultureImportance : maxCultureImportance as int?,
  );

  bool get hasQuery => query?.trim().isNotEmpty ?? false;

  bool get hasFieldFilters =>
      minAge != null ||
      maxAge != null ||
      (city?.trim().isNotEmpty ?? false) ||
      (country?.trim().isNotEmpty ?? false) ||
      (sort?.trim().isNotEmpty ?? false) ||
      (preferredGender?.trim().isNotEmpty ?? false) ||
      // Cultural compatibility filters
      (religion?.trim().isNotEmpty ?? false) ||
      (religiousPractice?.trim().isNotEmpty ?? false) ||
      (motherTongue?.trim().isNotEmpty ?? false) ||
      (languages?.isNotEmpty ?? false) ||
      (familyValues?.trim().isNotEmpty ?? false) ||
      (marriageViews?.trim().isNotEmpty ?? false) ||
      (ethnicity?.trim().isNotEmpty ?? false) ||
      minReligionImportance != null ||
      maxReligionImportance != null ||
      minCultureImportance != null ||
      maxCultureImportance != null;

  bool get hasCriteria => hasQuery || hasFieldFilters;

  Map<String, dynamic> toQuery() {
    final m = <String, dynamic>{};
    final q = query?.trim();
    final c = city?.trim();
    final countryValue = country?.trim();
    final s = sort?.trim();
    final cur = cursor?.trim();
    final pg = preferredGender?.trim();

    // Basic filters
    if (q != null && q.isNotEmpty) m['q'] = q;
    if (minAge != null) m['ageMin'] = minAge;
    if (maxAge != null) m['ageMax'] = maxAge;
    if (c != null && c.isNotEmpty) m['city'] = c;
    if (countryValue != null && countryValue.isNotEmpty) {
      m['country'] = countryValue;
    }
    if (s != null && s.isNotEmpty) m['sort'] = s;
    if (cur != null && cur.isNotEmpty) m['cursor'] = cur;
    if (pg != null && pg.isNotEmpty) m['gender'] = pg;
    if (pageSize != null && pageSize! > 0) m['pageSize'] = pageSize;

    // Cultural compatibility filters
    final r = religion?.trim();
    final rp = religiousPractice?.trim();
    final mt = motherTongue?.trim();
    final fv = familyValues?.trim();
    final mv = marriageViews?.trim();
    final eth = ethnicity?.trim();

    if (r != null && r.isNotEmpty) m['religion'] = r;
    if (rp != null && rp.isNotEmpty) m['religiousPractice'] = rp;
    if (mt != null && mt.isNotEmpty) m['motherTongue'] = mt;
    if (languages != null && languages!.isNotEmpty) m['languages'] = languages;
    if (fv != null && fv.isNotEmpty) m['familyValues'] = fv;
    if (mv != null && mv.isNotEmpty) m['marriageViews'] = mv;
    if (eth != null && eth.isNotEmpty) m['ethnicity'] = eth;
    if (minReligionImportance != null) m['minReligionImportance'] = minReligionImportance;
    if (maxReligionImportance != null) m['maxReligionImportance'] = maxReligionImportance;
    if (minCultureImportance != null) m['minCultureImportance'] = minCultureImportance;
    if (maxCultureImportance != null) m['maxCultureImportance'] = maxCultureImportance;

    return m;
  }

  Map<String, dynamic> toJson() => {
    if (query != null) 'query': query,
    if (minAge != null) 'minAge': minAge,
    if (maxAge != null) 'maxAge': maxAge,
    if (city != null) 'city': city,
    if (country != null) 'country': country,
    if (sort != null) 'sort': sort,
    if (cursor != null) 'cursor': cursor,
    if (pageSize != null) 'pageSize': pageSize,
    if (preferredGender != null) 'preferredGender': preferredGender,
    if (religion != null) 'religion': religion,
    if (religiousPractice != null) 'religiousPractice': religiousPractice,
    if (motherTongue != null) 'motherTongue': motherTongue,
    if (languages != null) 'languages': languages,
    if (familyValues != null) 'familyValues': familyValues,
    if (marriageViews != null) 'marriageViews': marriageViews,
    if (ethnicity != null) 'ethnicity': ethnicity,
    if (minReligionImportance != null) 'minReligionImportance': minReligionImportance,
    if (maxReligionImportance != null) 'maxReligionImportance': maxReligionImportance,
    if (minCultureImportance != null) 'minCultureImportance': minCultureImportance,
    if (maxCultureImportance != null) 'maxCultureImportance': maxCultureImportance,
  };
}
