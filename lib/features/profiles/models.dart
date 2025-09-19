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
    if (_hasMoreOverride != null)
      return _hasMoreOverride!; // ignore: unnecessary_non_null_assertion
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
    this.gender,
    this.sort,
    this.cursor,
    this.pageSize,
    this.maritalStatus,
    this.education,
    this.occupation,
    this.diet,
    this.smoking,
    this.drinking,
    this.ethnicity,
    this.motherTongue,
    this.language,
    this.annualIncomeMin,
    this.heightMin,
    this.heightMax,
  });

  static const Object _unset = Object();

  final String? query;
  final int? minAge;
  final int? maxAge;
  final String? city;
  final String? country;
  final String? gender;
  final String? sort; // e.g., 'recent', 'distance', 'newest'
  final String? cursor;
  final int? pageSize;
  final List<String>? maritalStatus;
  final List<String>? education;
  final List<String>? occupation;
  final List<String>? diet;
  final List<String>? smoking;
  final List<String>? drinking;
  final String? ethnicity;
  final String? motherTongue;
  final String? language;
  final int? annualIncomeMin;
  final String? heightMin;
  final String? heightMax;

  SearchFilters copyWith({
    Object? query = _unset,
    Object? minAge = _unset,
    Object? maxAge = _unset,
    Object? city = _unset,
    Object? country = _unset,
    Object? gender = _unset,
    Object? sort = _unset,
    Object? cursor = _unset,
    Object? pageSize = _unset,
    Object? maritalStatus = _unset,
    Object? education = _unset,
    Object? occupation = _unset,
    Object? diet = _unset,
    Object? smoking = _unset,
    Object? drinking = _unset,
    Object? ethnicity = _unset,
    Object? motherTongue = _unset,
    Object? language = _unset,
    Object? annualIncomeMin = _unset,
    Object? heightMin = _unset,
    Object? heightMax = _unset,
  }) => SearchFilters(
    query: query == _unset ? this.query : query as String?,
    minAge: minAge == _unset ? this.minAge : minAge as int?,
    maxAge: maxAge == _unset ? this.maxAge : maxAge as int?,
    city: city == _unset ? this.city : city as String?,
    country: country == _unset ? this.country : country as String?,
    gender: gender == _unset ? this.gender : gender as String?,
    sort: sort == _unset ? this.sort : sort as String?,
    cursor: cursor == _unset ? this.cursor : cursor as String?,
    pageSize: pageSize == _unset ? this.pageSize : pageSize as int?,
    maritalStatus: maritalStatus == _unset
        ? _cloneList(this.maritalStatus)
        : _cloneList(maritalStatus as List<String>?),
    education: education == _unset
        ? _cloneList(this.education)
        : _cloneList(education as List<String>?),
    occupation: occupation == _unset
        ? _cloneList(this.occupation)
        : _cloneList(occupation as List<String>?),
    diet: diet == _unset
        ? _cloneList(this.diet)
        : _cloneList(diet as List<String>?),
    smoking: smoking == _unset
        ? _cloneList(this.smoking)
        : _cloneList(smoking as List<String>?),
    drinking: drinking == _unset
        ? _cloneList(this.drinking)
        : _cloneList(drinking as List<String>?),
    ethnicity: ethnicity == _unset ? this.ethnicity : ethnicity as String?,
    motherTongue:
        motherTongue == _unset ? this.motherTongue : motherTongue as String?,
    language: language == _unset ? this.language : language as String?,
    annualIncomeMin: annualIncomeMin == _unset
        ? this.annualIncomeMin
        : annualIncomeMin as int?,
    heightMin: heightMin == _unset ? this.heightMin : heightMin as String?,
    heightMax: heightMax == _unset ? this.heightMax : heightMax as String?,
  );

  bool get hasQuery => query?.trim().isNotEmpty ?? false;

  bool get hasFieldFilters =>
      minAge != null ||
      maxAge != null ||
      _hasText(city) ||
      _hasText(country) ||
      _hasMeaningfulChoice(gender) ||
      (sort?.trim().isNotEmpty ?? false) ||
      (maritalStatus?.isNotEmpty ?? false) ||
      (education?.isNotEmpty ?? false) ||
      (occupation?.isNotEmpty ?? false) ||
      (diet?.isNotEmpty ?? false) ||
      (smoking?.isNotEmpty ?? false) ||
      (drinking?.isNotEmpty ?? false) ||
      _hasMeaningfulChoice(ethnicity) ||
      _hasMeaningfulChoice(motherTongue) ||
      _hasMeaningfulChoice(language) ||
      annualIncomeMin != null ||
      _hasText(heightMin) ||
      _hasText(heightMax);

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
    if (countryValue != null && countryValue.isNotEmpty) m['country'] = countryValue;
    final g = gender?.trim();
    if (_hasMeaningfulChoice(g)) {
      m['preferredGender'] = g;
    }
    if (s != null && s.isNotEmpty) m['sort'] = s;
    if (cur != null && cur.isNotEmpty) m['cursor'] = cur;
    if (pageSize != null && pageSize! > 0) m['pageSize'] = pageSize;
    if (maritalStatus != null && maritalStatus!.isNotEmpty) {
      m['maritalStatus'] = List<String>.from(maritalStatus!);
    }
    if (education != null && education!.isNotEmpty) {
      m['education'] = List<String>.from(education!);
    }
    if (occupation != null && occupation!.isNotEmpty) {
      m['occupation'] = List<String>.from(occupation!);
    }
    if (diet != null && diet!.isNotEmpty) {
      m['diet'] = List<String>.from(diet!);
    }
    if (smoking != null && smoking!.isNotEmpty) {
      m['smoking'] = List<String>.from(smoking!);
    }
    if (drinking != null && drinking!.isNotEmpty) {
      m['drinking'] = List<String>.from(drinking!);
    }
    final eth = ethnicity?.trim();
    if (_hasMeaningfulChoice(eth)) {
      m['ethnicity'] = eth;
    }
    final mt = motherTongue?.trim();
    if (_hasMeaningfulChoice(mt)) {
      m['motherTongue'] = mt;
    }
    final lang = language?.trim();
    if (_hasMeaningfulChoice(lang)) {
      m['language'] = lang;
    }
    if (annualIncomeMin != null && annualIncomeMin! > 0) {
      m['annualIncomeMin'] = annualIncomeMin;
    }
    final hMin = heightMin?.trim();
    if (hMin != null && hMin.isNotEmpty) {
      m['heightMin'] = hMin;
    }
    final hMax = heightMax?.trim();
    if (hMax != null && hMax.isNotEmpty) {
      m['heightMax'] = hMax;
    }
    return m;
  }
}

List<String>? _cloneList(List<String>? value) {
  if (value == null) return null;
  return List<String>.from(value);
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

bool _hasMeaningfulChoice(String? value) {
  if (!_hasText(value)) return false;
  return value!.trim().toLowerCase() != 'any';
}
