import 'package:dio/dio.dart';

import 'package:aroosi_flutter/core/api_client.dart';

class SafetyRepository {
  SafetyRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;
  final Dio _dio;

  Future<bool> reportUser({
    required String userId,
    required String reason,
    String? details,
  }) async {
    try {
      final res = await _dio.post(
        '/safety/report',
        data: {
          'userId': userId,
          'reason': reason,
          if (details != null && details.isNotEmpty) 'details': details,
        },
      );
      return (res.statusCode ?? 200) >= 200 && (res.statusCode ?? 200) < 300;
    } on DioException catch (_) {
      // Fallback
      try {
        final res = await _dio.post(
          '/report',
          data: {
            'userId': userId,
            'reason': reason,
            if (details != null && details.isNotEmpty) 'details': details,
          },
        );
        return (res.statusCode ?? 200) >= 200 && (res.statusCode ?? 200) < 300;
      } catch (_) {
        return false;
      }
    }
  }

  Future<bool> blockUser(String userId) async {
    try {
      final res = await _dio.post(
        '/safety/block',
        data: {'blockedUserId': userId},
      );
      return (res.statusCode ?? 200) >= 200 && (res.statusCode ?? 200) < 300;
    } on DioException catch (_) {
      try {
        final res = await _dio.post('/block', data: {'userId': userId});
        return (res.statusCode ?? 200) >= 200 && (res.statusCode ?? 200) < 300;
      } catch (_) {
        return false;
      }
    }
  }

  Future<bool> unblockUser(String userId) async {
    try {
      final res = await _dio.post(
        '/safety/unblock',
        data: {'blockedUserId': userId},
      );
      return (res.statusCode ?? 200) >= 200 && (res.statusCode ?? 200) < 300;
    } on DioException catch (_) {
      try {
        final res = await _dio.post('/unblock', data: {'userId': userId});
        return (res.statusCode ?? 200) >= 200 && (res.statusCode ?? 200) < 300;
      } catch (_) {
        return false;
      }
    }
  }

  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    try {
      final res = await _dio.get('/safety/blocked');
      final data = res.data;
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      if (data is Map && data['items'] is List) {
        return (data['items'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (_) {
      try {
        final res = await _dio.get('/blocked');
        final data = res.data;
        if (data is List) {
          return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
    }
    return <Map<String, dynamic>>[];
  }

  Future<bool> isBlocked(String userId) async {
    try {
      final res = await _dio.get(
        '/safety/blocked/check',
        queryParameters: {'userId': userId},
      );
      final data = res.data;
      if (data is Map) {
        final m = Map<String, dynamic>.from(data);
        final v = m['blocked'] ?? m['isBlocked'];
        if (v is bool) return v;
        if (v is num) return v != 0;
        if (v is String) return v.toLowerCase() == 'true';
      }
    } catch (_) {
      try {
        final res = await _dio.get(
          '/blocked/check',
          queryParameters: {'userId': userId},
        );
        final data = res.data;
        if (data is Map) {
          final m = Map<String, dynamic>.from(data);
          final v = m['blocked'] ?? m['isBlocked'];
          if (v is bool) return v;
        }
      } catch (_) {}
    }
    return false;
  }
}
