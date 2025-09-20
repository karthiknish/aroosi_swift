import 'package:equatable/equatable.dart';

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
    return MatchEntry(
      id: json['id']?.toString() ?? '',
      user1Id: json['user1Id']?.toString() ?? '',
      user2Id: json['user2Id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'matched',
      createdAt: json['createdAt'] is int
          ? json['createdAt']
          : int.tryParse(json['createdAt']?.toString() ?? '') ??
                DateTime.now().millisecondsSinceEpoch,
      conversationId: json['conversationId']?.toString() ?? '',
      lastMessageText: json['lastMessageText']?.toString(),
      lastMessageAt: json['lastMessageAt'] is int
          ? json['lastMessageAt']
          : int.tryParse(json['lastMessageAt']?.toString() ?? ''),
      otherUserId:
          json['userId']?.toString() ?? json['otherUserId']?.toString(),
      otherUserName:
          json['fullName']?.toString() ?? json['otherUserName']?.toString(),
      otherUserImage: json['profileImageUrls'] is List
          ? (json['profileImageUrls'] as List).isNotEmpty
                ? json['profileImageUrls'][0]?.toString()
                : null
          : json['otherUserImage']?.toString(),
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
  );

  bool get hasQuery => query?.trim().isNotEmpty ?? false;

  bool get hasFieldFilters =>
      minAge != null ||
      maxAge != null ||
      (city?.trim().isNotEmpty ?? false) ||
      (country?.trim().isNotEmpty ?? false) ||
      (sort?.trim().isNotEmpty ?? false) ||
      (preferredGender?.trim().isNotEmpty ?? false);

  bool get hasCriteria => hasQuery || hasFieldFilters;

  Map<String, dynamic> toQuery() {
    final m = <String, dynamic>{};
    final q = query?.trim();
    final c = city?.trim();
    final countryValue = country?.trim();
    final s = sort?.trim();
    final cur = cursor?.trim();
    final pg = preferredGender?.trim();

    if (q != null && q.isNotEmpty) m['q'] = q;
    if (minAge != null) m['ageMin'] = minAge;
    if (maxAge != null) m['ageMax'] = maxAge;
    if (c != null && c.isNotEmpty) m['city'] = c;
    if (countryValue != null && countryValue.isNotEmpty)
      m['country'] = countryValue;
    if (s != null && s.isNotEmpty) m['sort'] = s;
    if (cur != null && cur.isNotEmpty) m['cursor'] = cur;
    if (pg != null && pg.isNotEmpty) m['gender'] = pg;
    if (pageSize != null && pageSize! > 0) m['pageSize'] = pageSize;
    return m;
  }
}
