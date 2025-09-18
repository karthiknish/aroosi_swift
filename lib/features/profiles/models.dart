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
    return ProfileSummary(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      displayName: json['fullName']?.toString() ?? json['name']?.toString() ?? 'Unknown',
      age: json['age'] is int ? json['age'] as int : int.tryParse('${json['age']}'),
      city: json['city']?.toString(),
      avatarUrl: json['avatar']?.toString() ?? json['avatarUrl']?.toString(),
      isFavorite: json['isFavorite'] == true || json['favorite'] == true,
      isShortlisted: json['isShortlisted'] == true || json['shortlisted'] == true,
      lastActive: json['lastActive'] != null ? DateTime.tryParse(json['lastActive'].toString()) : null,
    );
  }

  @override
  List<Object?> get props => [id, displayName, age, city, avatarUrl, isFavorite, isShortlisted, lastActive];
}

class PagedResponse<T> {
  const PagedResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;

  bool get hasMore => items.length < total;
}

class SearchFilters {
  const SearchFilters({
    this.query,
    this.minAge,
    this.maxAge,
    this.city,
    this.sort,
  });

  final String? query;
  final int? minAge;
  final int? maxAge;
  final String? city;
  final String? sort; // e.g., 'recent', 'distance', 'newest'

  Map<String, dynamic> toQuery() {
    final m = <String, dynamic>{};
    if (query != null && query!.isNotEmpty) m['q'] = query;
    if (minAge != null) m['minAge'] = minAge;
    if (maxAge != null) m['maxAge'] = maxAge;
    if (city != null && city!.isNotEmpty) m['city'] = city;
    if (sort != null && sort!.isNotEmpty) m['sort'] = sort;
    return m;
  }
}
