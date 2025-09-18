import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/core/api_client.dart';

import 'models.dart';

final profilesRepositoryProvider = Provider<ProfilesRepository>(
  (ref) => ProfilesRepository(),
);

class ProfilesRepository {
  ProfilesRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<PagedResponse<ProfileSummary>> getMatches({
    int page = 1,
    int pageSize = 20,
    String? sort,
  }) async {
    try {
      final res = await _dio.get(
        '/profiles/matches',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (sort != null) 'sort': sort,
        },
      );
      return _parsePaged(res);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final res = await _dio.get(
          '/matches',
          queryParameters: {
            'page': page,
            'pageSize': pageSize,
            if (sort != null) 'sort': sort,
          },
        );
        return _parsePaged(res);
      }
      rethrow;
    }
  }

  Future<PagedResponse<ProfileSummary>> search({
    required SearchFilters filters,
    int page = 1,
    int pageSize = 20,
  }) async {
    final qp = filters.toQuery();
    qp['page'] = page;
    qp['pageSize'] = pageSize;
    Response res;
    // Try canonical generic /search first per aroosi-mobile
    try {
      res = await _dio.get('/search', queryParameters: qp);
      return _parsePaged(res);
    } catch (_) {}
    // Fallback: profiles search
    try {
      res = await _dio.get('/profiles/search', queryParameters: qp);
      return _parsePaged(res);
    } catch (_) {}
    // Fallback: users search
    try {
      res = await _dio.get('/users/search', queryParameters: qp);
      return _parsePaged(res);
    } catch (_) {}
    // Fallback: profiles listing with q filter
    try {
      res = await _dio.get('/profiles', queryParameters: qp);
      return _parsePaged(res);
    } catch (e) {
      // Last resort: empty
      return const PagedResponse(items: [], page: 1, pageSize: 0, total: 0);
    }
  }

  Future<PagedResponse<ProfileSummary>> getFavorites({
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _dio.get(
      '/profiles/favorites',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return _parsePaged(res);
  }

  Future<PagedResponse<ProfileSummary>> getShortlist({
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _dio.get(
      '/profiles/shortlist',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return _parsePaged(res);
  }

  Future<bool> toggleFavorite(String profileId) async {
    final res = await _dio.post('/profiles/$profileId/favorite');
    return res.statusCode == 200;
  }

  Future<bool> toggleShortlist(String profileId) async {
    final res = await _dio.post('/profiles/$profileId/shortlist');
    return res.statusCode == 200;
  }

  Future<bool> boostProfile() async {
    try {
      final res = await _dio.post('/profile/boost');
      final status = res.statusCode ?? 200;
      if (status >= 200 && status < 300) {
        return true;
      }
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 500;
      if (code >= 200 && code < 300) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  // Send an "interest" (like) to a profile. Web-first endpoint with graceful fallbacks.
  Future<bool> sendInterest(String profileId) async {
    try {
      Response res;
      try {
        res = await _dio.post(
          '/interests',
          data: {'action': 'send', 'targetUserId': profileId},
        );
        final status = res.statusCode ?? 200;
        if (status >= 200 && status < 300) {
          return true;
        }
      } catch (_) {}

      res = await _dio.post('/profiles/$profileId/interest');
      var status = res.statusCode ?? 200;
      if (status >= 200 && status < 300) {
        return true;
      }

      res = await _dio.post('/likes', data: {'profileId': profileId});
      status = res.statusCode ?? 200;
      if (status >= 200 && status < 300) {
        return true;
      }

      res = await _dio.post('/profiles/$profileId/like');
      status = res.statusCode ?? 200;
      return status >= 200 && status < 300;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 201 || code == 204) {
        return true;
      }
      rethrow;
    }
  }

  // Interests taxonomy/options for user to pick from
  Future<List<String>> getInterestOptions() async {
    try {
      final res = await _dio.get('/profiles/interests/options');
      final data = res.data;
      if (data is List) {
        return data.map((e) => e.toString()).toList();
      }
      if (data is Map<String, dynamic>) {
        final list = (data['options'] as List?) ?? data['items'] as List?;
        if (list != null) {
          return list.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}
    try {
      final res = await _dio.get('/interests');
      final data = res.data;
      if (data is List) {
        return data.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    // Sensible default in absence of API
    return const [
      'Arts & Culture',
      'Travel',
      'Fitness',
      'Music',
      'Foodie',
      'Tech',
      'Outdoors',
    ];
  }

  // Fetch currently selected interests for the logged-in user
  Future<Set<String>> getSelectedInterests() async {
    try {
      final res = await _dio.get('/profiles/me/interests');
      final data = res.data;
      if (data is List) {
        return data.map((e) => e.toString()).toSet();
      }
      if (data is Map<String, dynamic>) {
        final list = (data['interests'] as List?) ?? data['data'] as List?;
        if (list != null) {
          return list.map((e) => e.toString()).toSet();
        }
      }
    } catch (_) {
      try {
        final res = await _dio.get('/users/me/interests');
        final data = res.data;
        if (data is List) {
          return data.map((e) => e.toString()).toSet();
        }
        if (data is Map<String, dynamic>) {
          final list = (data['interests'] as List?) ?? data['data'] as List?;
          if (list != null) {
            return list.map((e) => e.toString()).toSet();
          }
        }
      } catch (_) {}
    }
    return <String>{};
  }

  // Save selected interests for the logged-in user
  Future<bool> saveSelectedInterests(Set<String> interests) async {
    try {
      Response res = await _dio.post(
        '/profiles/me/interests',
        data: {'interests': interests.toList()},
      );
      return (res.statusCode ?? 200) >= 200 && (res.statusCode ?? 200) < 300;
    } catch (_) {
      try {
        final res = await _dio.post(
          '/users/me/interests',
          data: {'interests': interests.toList()},
        );
        return (res.statusCode ?? 200) >= 200 && (res.statusCode ?? 200) < 300;
      } catch (e) {
        return false;
      }
    }
  }

  Future<Map<String, dynamic>?> getProfileById(String id) async {
    try {
      final res = await _dio.get('/profile-detail/$id');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
    } catch (_) {}
    try {
      final res = await _dio.get('/profiles/$id');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
    } catch (_) {}
    try {
      final res = await _dio.get('/profile', queryParameters: {'userId': id});
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  PagedResponse<ProfileSummary> _parsePaged(Response res) {
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final items =
          (data['items'] as List? ??
                  data['data'] as List? ??
                  data['profiles'] as List? ??
                  [])
              .map((e) => ProfileSummary.fromJson(e as Map<String, dynamic>))
              .toList();
      final total = (data['total'] as num? ?? items.length).toInt();
      final page = (data['page'] as num? ?? 1).toInt();
      final pageSize = (data['pageSize'] as num? ?? items.length).toInt();
      // Some endpoints provide hasMore directly
      final hasMore = data['hasMore'] == true || (page * pageSize) < total;
      return PagedResponse(
        items: items,
        page: page,
        pageSize: pageSize,
        total: hasMore ? total : items.length,
      );
    }
    // As a fallback when server responds with array only
    if (data is List) {
      final items = data
          .map((e) => ProfileSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      return PagedResponse(
        items: items,
        page: 1,
        pageSize: items.length,
        total: items.length,
      );
    }
    return const PagedResponse(items: [], page: 1, pageSize: 0, total: 0);
  }
}
