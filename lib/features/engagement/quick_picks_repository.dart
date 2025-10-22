import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:aroosi_flutter/core/api_client.dart';
import 'package:aroosi_flutter/features/profiles/models.dart';

class QuickPicksRepository {
  QuickPicksRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  /// Fetch daily quick picks similar to aroosi-mobile.
  /// Returns a list of ProfileSummary items (normalized from API response).
  Future<List<ProfileSummary>> getQuickPicks({String? dayKey}) async {
    try {
      final path = '/engagement/quick-picks';
      final res = await _dio.get(
        path,
        queryParameters: dayKey != null && dayKey.trim().isNotEmpty
            ? {'day': dayKey}
            : null,
      );
      
      final data = res.data;
      // NextJS API returns: { success: true, data: { userIds: [...], profiles: [...] } }
      if (data is! Map || data['data'] is! Map || (data['data'] as Map)['profiles'] == null) {
        throw Exception('Invalid response format: expected { success: true, data: { profiles: [...] } }');
      }

      final responseData = data['data'] as Map<String, dynamic>;
      final profilesList = responseData['profiles'] as List<dynamic>;
      
      final profiles = profilesList.map((p) {
        try {
          if (p is Map) {
            final profileData = p['profile'] is Map ? p['profile'] as Map : p;

            final id = p['userId']?.toString() ?? p['id']?.toString() ?? '';
            final fullName = profileData['fullName']?.toString() ?? '';

            // Handle profileImageUrls more safely
            List<dynamic>? profileImageUrls;
            try {
              profileImageUrls = profileData['profileImageUrls'] as List<dynamic>?;
            } catch (e) {
              debugPrint('Failed to parse profileImageUrls: $e');
            }
            final avatarUrl = (profileImageUrls?.isNotEmpty ?? false) ? profileImageUrls!.first.toString() : null;

            // Calculate age from dateOfBirth if available
            int? age;
            if (profileData['dateOfBirth'] != null) {
              try {
                final dob = DateTime.parse(profileData['dateOfBirth'].toString());
                final now = DateTime.now();
                age = now.year - dob.year;
                if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
                  age = age - 1;
                }
              } catch (e) {
                debugPrint('Failed to parse dateOfBirth: $e');
              }
            }

            return ProfileSummary(
              id: id,
              displayName: fullName.isNotEmpty ? fullName : 'User $id',
              avatarUrl: avatarUrl,
              city: profileData['city']?.toString(),
              age: age,
              lastActive: p['createdAt'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(p['createdAt'] is int ? p['createdAt'] as int : 0)
                  : null,
            );
          } else {
            throw Exception('Invalid profile item format: $p');
          }
        } catch (e) {
          // Log parsing error but continue with other items
          debugPrint('Error parsing quick pick profile: $e');
          // Return a fallback profile instead of crashing
          return ProfileSummary(
            id: 'unknown',
            displayName: 'Unknown User',
          );
        }
      }).toList();

      return profiles;
    } catch (e) {
      // Return empty list on error to avoid breaking UI
      debugPrint('Error fetching quick picks: $e');
      return [];
    }
  }

  /// Act on a quick pick profile (like or skip)
  Future<void> actOnQuickPick(String toUserId, String action) async {
    try {
      await _dio.post('/engagement/quick-picks', data: {
        'toUserId': toUserId,
        'action': action, // 'like' or 'skip'
      });
    } catch (e) {
      throw Exception('Failed to $action profile: $e');
    }
  }
}
