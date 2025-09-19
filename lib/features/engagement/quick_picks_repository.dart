import 'package:dio/dio.dart';

import 'package:aroosi_flutter/core/api_client.dart';
import 'package:aroosi_flutter/features/profiles/models.dart';

class QuickPicksRepository {
  QuickPicksRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  /// Fetch daily quick picks similar to aroosi-mobile.
  /// Returns a list of ProfileSummary items (normalized from API response).
  Future<List<ProfileSummary>> getQuickPicks({String? dayKey}) async {
    try {
      final path = dayKey == null || dayKey.trim().isEmpty
          ? '/engagement/quick-picks'
          : '/engagement/quick-picks';
      final res = await _dio.get(
        path,
        queryParameters: dayKey != null && dayKey.trim().isNotEmpty
            ? {'day': dayKey}
            : null,
      );
      final data = res.data;
      // Expected shapes:
      // { data: { profiles: [...] } }
      // { profiles: [...] }
      // [ ... ]
      dynamic envelope = data;
      if (data is Map && data['data'] != null) envelope = data['data'];
      final list = envelope is Map && envelope['profiles'] is List
          ? envelope['profiles'] as List
          : (envelope is List ? envelope : <dynamic>[]);
      return list
          .whereType<Map>()
          .map((e) => ProfileSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const <ProfileSummary>[];
    }
  }
}
