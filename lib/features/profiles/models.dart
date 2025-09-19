import 'package:equatable/equatable.dart';

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

  SearchFilters copyWith({
    Object? query = _unset,
    Object? minAge = _unset,
    Object? maxAge = _unset,
    Object? city = _unset,
    Object? country = _unset,
    Object? sort = _unset,
    Object? cursor = _unset,
    Object? pageSize = _unset,
  }) => SearchFilters(
    query: query == _unset ? this.query : query as String?,
    minAge: minAge == _unset ? this.minAge : minAge as int?,
    maxAge: maxAge == _unset ? this.maxAge : maxAge as int?,
    city: city == _unset ? this.city : city as String?,
    country: country == _unset ? this.country : country as String?,
    sort: sort == _unset ? this.sort : sort as String?,
    cursor: cursor == _unset ? this.cursor : cursor as String?,
    pageSize: pageSize == _unset ? this.pageSize : pageSize as int?,
  );

  bool get hasQuery => query?.trim().isNotEmpty ?? false;

  bool get hasFieldFilters =>
      minAge != null ||
      maxAge != null ||
      (city?.trim().isNotEmpty ?? false) ||
      (country?.trim().isNotEmpty ?? false) ||
      (sort?.trim().isNotEmpty ?? false);

  bool get hasCriteria => hasQuery || hasFieldFilters;

  Map<String, dynamic> toQuery() {
    final m = <String, dynamic>{};
    final q = query?.trim();
    final c = city?.trim();
    final countryValue = country?.trim();
    final s = sort?.trim();
    final cur = cursor?.trim();

    if (q != null && q.isNotEmpty) m['q'] = q;
    if (minAge != null) m['ageMin'] = minAge;
    if (maxAge != null) m['ageMax'] = maxAge;
    if (c != null && c.isNotEmpty) m['city'] = c;
    if (countryValue != null && countryValue.isNotEmpty)
      m['country'] = countryValue;
    if (s != null && s.isNotEmpty) m['sort'] = s;
    if (cur != null && cur.isNotEmpty) m['cursor'] = cur;
    if (pageSize != null && pageSize! > 0) m['pageSize'] = pageSize;
    return m;
  }
}
