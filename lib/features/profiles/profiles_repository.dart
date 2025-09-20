import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:aroosi_flutter/core/api_client.dart';
import 'package:aroosi_flutter/utils/debug_logger.dart';

import 'models.dart';
import 'profile_image.dart';

final profilesRepositoryProvider = Provider<ProfilesRepository>(
  (ref) => ProfilesRepository(),
);

class ProfilesRepository {
  ProfilesRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  // region: Profile listing/search

  Future<PagedResponse<MatchEntry>> getMatches({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      // Match React app: /matches (base URL already includes /api)
      final res = await _dio.get(
        '/matches',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return _parseMatchesPaged(res);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Fallback to legacy endpoint
        final res = await _dio.get(
          '/matches',
          queryParameters: {'page': page, 'pageSize': pageSize},
        );
        return _parseMatchesPaged(res);
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

    logDebug(
      'Search API call',
      data: {
        'endpoint': 'search',
        'queryParameters': qp,
        'page': page,
        'pageSize': pageSize,
      },
    );

    Response res;
    String? lastError;

    // Try canonical generic /search first (Next.js API route)
    try {
      logDebug('Trying primary search endpoint: /search');
      res = await _dio.get('/search', queryParameters: qp);
      logDebug(
        'Search success: /search',
        data: {
          'status': res.statusCode,
          'dataKeys': res.data is Map
              ? (res.data as Map).keys.toList()
              : 'not_a_map',
        },
      );
      return _parsePaged(res);
    } catch (e, stackTrace) {
      lastError = 'Failed /search: ${e.toString()}';
      logDebug('Search failed: /search', error: e, stackTrace: stackTrace);
    }

    // Fallback: profiles search
    try {
      logDebug('Trying fallback endpoint: /profiles/search');
      res = await _dio.get('/profiles/search', queryParameters: qp);
      logDebug(
        'Search success: /profiles/search',
        data: {
          'status': res.statusCode,
          'dataKeys': res.data is Map
              ? (res.data as Map).keys.toList()
              : 'not_a_map',
        },
      );
      return _parsePaged(res);
    } catch (e, stackTrace) {
      lastError = 'Failed /profiles/search: ${e.toString()}';
      logDebug(
        'Search failed: /profiles/search',
        error: e,
        stackTrace: stackTrace,
      );
    }

    // Fallback: users search
    try {
      logDebug('Trying fallback endpoint: /users/search');
      res = await _dio.get('/users/search', queryParameters: qp);
      logDebug(
        'Search success: /users/search',
        data: {
          'status': res.statusCode,
          'dataKeys': res.data is Map
              ? (res.data as Map).keys.toList()
              : 'not_a_map',
        },
      );
      return _parsePaged(res);
    } catch (e, stackTrace) {
      lastError = 'Failed /users/search: ${e.toString()}';
      logDebug(
        'Search failed: /users/search',
        error: e,
        stackTrace: stackTrace,
      );
    }

    // Fallback: profiles listing with q filter
    try {
      logDebug('Trying fallback endpoint: /profiles');
      res = await _dio.get('/profiles', queryParameters: qp);
      logDebug(
        'Search success: /profiles',
        data: {
          'status': res.statusCode,
          'dataKeys': res.data is Map
              ? (res.data as Map).keys.toList()
              : 'not_a_map',
        },
      );
      return _parsePaged(res);
    } catch (e, stackTrace) {
      lastError = 'Failed /profiles: ${e.toString()}';
      logDebug('Search failed: /profiles', error: e, stackTrace: stackTrace);
    }

    // Last resort: empty
    logDebug(
      'All search endpoints failed, returning empty response',
      error: lastError,
    );
    return const PagedResponse(items: [], page: 1, pageSize: 0, total: 0);
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
    try {
      // RN primary: /engagement/shortlist
      final res = await _dio.get(
        '/engagement/shortlist',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return _parsePaged(res);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final res = await _dio.get(
          '/profiles/shortlist',
          queryParameters: {'page': page, 'pageSize': pageSize},
        );
        return _parsePaged(res);
      }
      rethrow;
    }
  }

  Future<PagedResponse<ShortlistEntry>> getShortlistEntries({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      // Next.js primary: /engagement/shortlist
      final res = await _dio.get(
        '/engagement/shortlist',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return _parseShortlistPaged(res);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final res = await _dio.get(
          '/profiles/shortlist',
          queryParameters: {'page': page, 'pageSize': pageSize},
        );
        return _parseShortlistPaged(res);
      }
      rethrow;
    }
  }

  Future<bool> toggleFavorite(String profileId) async {
    final res = await _dio.post('/profiles/$profileId/favorite');
    return res.statusCode == 200;
  }

  Future<bool> toggleShortlist(String profileId) async {
    try {
      final res = await _dio.post(
        '/engagement/shortlist',
        data: {'toUserId': profileId},
      );
      final status = res.statusCode ?? 200;
      if (status >= 200 && status < 300) return true;
    } catch (_) {}
    final res = await _dio.post('/profiles/$profileId/shortlist');
    final status = res.statusCode ?? 200;
    return status >= 200 && status < 300;
  }

  Future<Map<String, dynamic>> toggleShortlistEntry(String userId) async {
    try {
      final res = await _dio.post(
        '/engagement/shortlist',
        data: {'toUserId': userId},
      );

      final status = res.statusCode ?? 200;
      final data = res.data as Map<String, dynamic>? ?? {};

      if (status >= 200 && status < 300) {
        return {'success': true, 'data': data, 'error': null};
      } else {
        return {
          'success': false,
          'data': data,
          'error': data['message'] ?? 'Failed to toggle shortlist',
        };
      }
    } on DioException catch (e) {
      final errorData = e.response?.data as Map<String, dynamic>? ?? {};
      return {
        'success': false,
        'data': errorData,
        'error': errorData['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      return {'success': false, 'data': null, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> fetchNote(String userId) async {
    try {
      final res = await _dio.get(
        '/engagement/note',
        queryParameters: {'toUserId': userId},
      );

      final status = res.statusCode ?? 200;
      if (status >= 200 && status < 300) {
        final data = res.data as Map<String, dynamic>? ?? {};
        return (data['data'] as Map<String, dynamic>?) ?? data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> setNote(String userId, String note) async {
    try {
      final res = await _dio.post(
        '/engagement/note',
        data: {'toUserId': userId, 'note': note},
      );

      final status = res.statusCode ?? 200;
      final data = res.data as Map<String, dynamic>? ?? {};

      return (status >= 200 && status < 300) &&
          ((data['success'] == true) || (data['data']['success'] == true));
    } catch (_) {
      return false;
    }
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

  // Send/respond to/remove interests using Next.js API
  Future<Map<String, dynamic>> manageInterest({
    required String action, // 'send', 'respond', 'remove'
    String? toUserId,
    String? interestId,
    String? status, // 'accepted', 'rejected' for respond action
  }) async {
    try {
      final data = <String, dynamic>{'action': action};
      if (toUserId != null) data['toUserId'] = toUserId;
      if (interestId != null) data['interestId'] = interestId;
      if (status != null) data['status'] = status;

      final res = await _dio.post('/interests', data: data);
      final responseData = res.data as Map<String, dynamic>? ?? {};

      if (responseData['success'] == true) {
        return {'success': true, 'data': responseData['data'], 'error': null};
      } else {
        return {
          'success': false,
          'data': responseData,
          'error': responseData['error'] ?? 'Failed to manage interest',
        };
      }
    } on DioException catch (e) {
      final errorData = e.response?.data as Map<String, dynamic>? ?? {};
      return {
        'success': false,
        'data': errorData,
        'error':
            errorData['error'] ??
            errorData['message'] ??
            e.message ??
            'Network error',
        'isPlanLimit': _isPlanLimitError(
          errorData['error'] ?? errorData['message'] ?? '',
        ),
      };
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'error': e.toString(),
        'isPlanLimit': false,
      };
    }
  }

  // Get interests with different modes
  Future<PagedResponse<InterestEntry>> getInterests({
    required String mode, // 'sent', 'received', 'mutual'
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final res = await _dio.get(
        '/interests',
        queryParameters: {'mode': mode, 'page': page, 'pageSize': pageSize},
      );
      return _parseInterestsPaged(res);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Fallback to legacy endpoint
        final res = await _dio.get(
          '/profiles/interests',
          queryParameters: {'mode': mode, 'page': page, 'pageSize': pageSize},
        );
        return _parseInterestsPaged(res);
      }
      rethrow;
    }
  }

  // Check interest status between users
  Future<Map<String, dynamic>?> checkInterestStatus({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      final res = await _dio.get(
        '/interests/status',
        queryParameters: {'fromUserId': fromUserId, 'toUserId': toUserId},
      );

      final responseData = res.data as Map<String, dynamic>? ?? {};
      if (responseData['success'] == true) {
        return responseData['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Legacy send interest method for backward compatibility
  Future<bool> sendInterest(String profileId) async {
    final result = await manageInterest(action: 'send', toUserId: profileId);
    return result['success'] == true;
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
    try {
      final res = await _dio.get(
        '/user/profile',
        queryParameters: {'userId': id},
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        if (data['data'] is Map<String, dynamic>) {
          return (data['data'] as Map).cast<String, dynamic>();
        }
        return data;
      }
    } catch (_) {}
    return null;
  }

  PagedResponse<ProfileSummary> _parsePaged(Response res) {
    final meta = <String, dynamic>{};
    final rawItems = _extractProfileList(res.data, meta);

    final items = rawItems
        .whereType<Map>()
        .map((e) => ProfileSummary.fromJson(e.cast<String, dynamic>()))
        .where((p) => p.id.isNotEmpty)
        .toList();

    final query = res.requestOptions.queryParameters;
    final total =
        _asInt(meta['total']) ?? _asInt(res.data?['total']) ?? items.length;
    final requestedPage = _asInt(query['page']);
    final page = _asInt(meta['page']) ?? requestedPage ?? 1;
    final pageSize =
        _asInt(meta['pageSize']) ?? _asInt(query['pageSize']) ?? items.length;
    final nextPage = _asInt(meta['nextPage']);
    final nextCursor = _asString(meta['nextCursor']);
    final hasMoreFlag = _asBool(meta['hasMore']);

    return PagedResponse(
      items: items,
      page: page,
      pageSize: pageSize,
      total: total,
      nextPage: nextPage,
      nextCursor: nextCursor,
      hasMore: hasMoreFlag,
    );
  }

  PagedResponse<MatchEntry> _parseMatchesPaged(Response res) {
    final meta = <String, dynamic>{};
    final rawItems = _extractMatchesList(res.data, meta);

    final items = rawItems
        .whereType<Map>()
        .map((e) => MatchEntry.fromJson(e.cast<String, dynamic>()))
        .where((m) => m.id.isNotEmpty)
        .toList();

    final query = res.requestOptions.queryParameters;
    final total =
        _asInt(meta['total']) ?? _asInt(res.data?['total']) ?? items.length;
    final requestedPage = _asInt(query['page']);
    final page = _asInt(meta['page']) ?? requestedPage ?? 1;
    final pageSize =
        _asInt(meta['pageSize']) ?? _asInt(query['pageSize']) ?? items.length;
    final nextPage = _asInt(meta['nextPage']);
    final nextCursor = _asString(meta['nextCursor']);
    final hasMoreFlag = _asBool(meta['hasMore']);

    return PagedResponse(
      items: items,
      page: page,
      pageSize: pageSize,
      total: total,
      nextPage: nextPage,
      nextCursor: nextCursor,
      hasMore: hasMoreFlag,
    );
  }

  PagedResponse<InterestEntry> _parseInterestsPaged(Response res) {
    final meta = <String, dynamic>{};
    final rawItems = _extractInterestsList(res.data, meta);

    final items = rawItems
        .whereType<Map>()
        .map((e) => InterestEntry.fromJson(e.cast<String, dynamic>()))
        .where((i) => i.id.isNotEmpty)
        .toList();

    final query = res.requestOptions.queryParameters;
    final total =
        _asInt(meta['total']) ?? _asInt(res.data?['total']) ?? items.length;
    final requestedPage = _asInt(query['page']);
    final page = _asInt(meta['page']) ?? requestedPage ?? 1;
    final pageSize =
        _asInt(meta['pageSize']) ?? _asInt(query['pageSize']) ?? items.length;
    final nextPage = _asInt(meta['nextPage']);
    final nextCursor = _asString(meta['nextCursor']);
    final hasMoreFlag = _asBool(meta['hasMore']);

    return PagedResponse(
      items: items,
      page: page,
      pageSize: pageSize,
      total: total,
      nextPage: nextPage,
      nextCursor: nextCursor,
      hasMore: hasMoreFlag,
    );
  }

  PagedResponse<ShortlistEntry> _parseShortlistPaged(Response res) {
    final meta = <String, dynamic>{};
    final rawItems = _extractShortlistList(res.data, meta);

    final items = rawItems
        .whereType<Map>()
        .map((e) => ShortlistEntry.fromJson(e.cast<String, dynamic>()))
        .where((p) => p.userId.isNotEmpty)
        .toList();

    final query = res.requestOptions.queryParameters;
    final total =
        _asInt(meta['total']) ?? _asInt(res.data?['total']) ?? items.length;
    final requestedPage = _asInt(query['page']);
    final page = _asInt(meta['page']) ?? requestedPage ?? 1;
    final pageSize =
        _asInt(meta['pageSize']) ?? _asInt(query['pageSize']) ?? items.length;
    final nextPage = _asInt(meta['nextPage']);
    final nextCursor = _asString(meta['nextCursor']);
    final hasMoreFlag = _asBool(meta['hasMore']);

    return PagedResponse(
      items: items,
      page: page,
      pageSize: pageSize,
      total: total,
      nextPage: nextPage,
      nextCursor: nextCursor,
      hasMore: hasMoreFlag,
    );
  }

  List<dynamic> _extractProfileList(dynamic data, Map<String, dynamic> meta) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      _collectMeta(data, meta);
      for (final key in const [
        'profiles',
        'items',
        'results',
        'data',
        'list',
      ]) {
        if (!data.containsKey(key)) continue;
        final result = _extractProfileList(data[key], meta);
        if (result.isNotEmpty) return result;
      }
    }
    return const [];
  }

  List<dynamic> _extractMatchesList(dynamic data, Map<String, dynamic> meta) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      _collectMeta(data, meta);
      for (final key in const ['matches', 'items', 'results', 'data', 'list']) {
        if (!data.containsKey(key)) continue;
        final result = _extractMatchesList(data[key], meta);
        if (result.isNotEmpty) return result;
      }
    }
    return const [];
  }

  List<dynamic> _extractInterestsList(dynamic data, Map<String, dynamic> meta) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      _collectMeta(data, meta);
      for (final key in const [
        'interests',
        'items',
        'results',
        'data',
        'list',
      ]) {
        if (!data.containsKey(key)) continue;
        final result = _extractInterestsList(data[key], meta);
        if (result.isNotEmpty) return result;
      }
    }
    return const [];
  }

  List<dynamic> _extractShortlistList(dynamic data, Map<String, dynamic> meta) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      _collectMeta(data, meta);
      for (final key in const [
        'entries',
        'items',
        'results',
        'data',
        'list',
        'shortlist',
      ]) {
        if (!data.containsKey(key)) continue;
        final result = _extractShortlistList(data[key], meta);
        if (result.isNotEmpty) return result;
      }
    }
    return const [];
  }

  void _collectMeta(Map<String, dynamic> source, Map<String, dynamic> target) {
    for (final key in const [
      'total',
      'page',
      'pageSize',
      'hasMore',
      'nextPage',
      'nextCursor',
    ]) {
      if (target.containsKey(key)) continue;
      if (source[key] != null) {
        target[key] = source[key];
      }
    }
    if (!target.containsKey('nextCursor')) {
      final cursor = source['cursor'];
      if (cursor != null) {
        target['nextCursor'] = cursor;
      }
    }
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  String? _asString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  bool? _asBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final lower = value.toString().toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
    return null;
  }

  bool _isPlanLimitError(String error) {
    final lower = error.toLowerCase();
    return lower.contains('plan') ||
        lower.contains('limit') ||
        lower.contains('subscription') ||
        lower.contains('upgrade') ||
        lower.contains('premium');
  }

  // endregion

  // region: Unread messages and conversation management

  Future<Map<String, int>> getUnreadMessageCounts() async {
    try {
      final res = await _dio.get('/matches/unread');
      final data = res.data as Map<String, dynamic>? ?? {};

      if (data['success'] == true) {
        final countsData = data['data'] as Map<String, dynamic>? ?? {};
        return countsData.map(
          (key, value) => MapEntry(key, (value as num).toInt()),
        );
      }

      // Fallback: try legacy endpoint
      try {
        final legacyRes = await _dio.get('/conversations/unread');
        final legacyData = legacyRes.data as Map<String, dynamic>? ?? {};
        if (legacyData['success'] == true) {
          final countsData = legacyData['data'] as Map<String, dynamic>? ?? {};
          return countsData.map(
            (key, value) => MapEntry(key, (value as num).toInt()),
          );
        }
      } catch (_) {
        // Ignore fallback error
      }

      return {};
    } catch (_) {
      return {};
    }
  }

  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await _dio.post('/conversations/$conversationId/read');
    } catch (_) {
      // Silently fail
    }
  }

  // endregion

  // region: Block management

  Future<bool> isUserBlocked(String userId) async {
    try {
      final res = await _dio.get('/blocks/check/$userId');
      final data = res.data as Map<String, dynamic>? ?? {};
      return data['blocked'] == true || data['isBlocked'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> blockUser(String userId) async {
    try {
      final res = await _dio.post('/blocks', data: {'userId': userId});
      final responseData = res.data as Map<String, dynamic>? ?? {};

      if (responseData['success'] == true) {
        return {'success': true, 'error': null};
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to block user',
        };
      }
    } on DioException catch (e) {
      final errorData = e.response?.data as Map<String, dynamic>? ?? {};
      return {
        'success': false,
        'error':
            errorData['error'] ??
            errorData['message'] ??
            e.message ??
            'Network error',
        'isPlanLimit': _isPlanLimitError(
          errorData['error'] ?? errorData['message'] ?? '',
        ),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'isPlanLimit': false};
    }
  }

  Future<Map<String, dynamic>> unblockUser(String userId) async {
    try {
      final res = await _dio.delete('/blocks/$userId');
      final responseData = res.data as Map<String, dynamic>? ?? {};

      if (responseData['success'] == true) {
        return {'success': true, 'error': null};
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to unblock user',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'isPlanLimit': false};
    }
  }

  // endregion

  // region: Profile images

  Future<List<ProfileImage>> fetchProfileImages({String? userId}) async {
    final qp = <String, dynamic>{};
    if (userId != null && userId.isNotEmpty) {
      qp['userId'] = userId;
    }
    final res = await _dio.get('/profile-images', queryParameters: qp);
    final data = res.data;
    List<dynamic>? list;
    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic>) {
      final maps = <String>['images', 'data', 'items'];
      for (final key in maps) {
        final value = data[key];
        if (value is List) {
          list = value;
          break;
        }
        if (value is Map && value['images'] is List) {
          list = value['images'] as List;
          break;
        }
      }
    }
    if (list == null) return const <ProfileImage>[];
    return list
        .whereType<Map>()
        .map((e) => ProfileImage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProfileImage> uploadProfileImage({
    required XFile file,
    required String userId,
    void Function(double progress)? onProgress,
  }) async {
    final uploadUrl = await _requestUploadUrl();

    final length = await file.length();
    final contentType =
        file.mimeType ?? _inferContentType(file.path) ?? 'image/jpeg';

    await _uploadToStorage(uploadUrl, file, length, contentType, onProgress);

    final storageId = _extractStorageId(uploadUrl);

    final metadata = await _saveImageMetadata(
      userId: userId,
      storageId: storageId,
      fileName: file.name,
      contentType: contentType,
      fileSize: length,
    );

    return metadata;
  }

  Future<void> deleteProfileImage({
    required String userId,
    required String imageId,
  }) async {
    await _dio.delete(
      '/profile-images',
      data: {'userId': userId, 'imageId': imageId},
    );
  }

  Future<void> reorderProfileImages({
    required String userId,
    required List<String> imageIds,
  }) async {
    await _dio.post(
      '/profile-images/order',
      data: {'profileId': userId, 'imageIds': imageIds},
    );
  }

  /// Creates a profile mirroring aroosi-mobile's `/profile` endpoint.
  Future<void> createProfile(Map<String, dynamic> payload) async {
    await _dio.post('/profile', data: payload);
  }

  /// Update the current user's profile.
  ///
  /// Parity goals with RN implementation:
  /// - Primary endpoint: PUT /user/profile (RN)
  /// - (Optional future) fallback variants if backend differs (e.g. /profiles/me)
  /// - Tolerant: treat 200-204 as success
  /// - Return the updated JSON map (or null on silent failure)
  Future<Map<String, dynamic>?> updateProfile(
    Map<String, dynamic> updates, {
    CancelToken? cancelToken,
  }) async {
    Response res;
    try {
      // RN primary
      res = await _dio.put(
        '/user/profile',
        data: updates,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      // Attempt a fallback endpoint if 404 or method not allowed
      final code = e.response?.statusCode;
      if (code == 404 || code == 405) {
        try {
          // Legacy fallbacks
          try {
            res = await _dio.put(
              '/profile',
              data: updates,
              cancelToken: cancelToken,
            );
          } on DioException {
            res = await _dio.put(
              '/profiles/me',
              data: updates,
              cancelToken: cancelToken,
            );
          }
        } catch (_) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    final status = res.statusCode ?? 200;
    if (status < 200 || status >= 300) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: 'Failed to update profile (HTTP $status)',
      );
    }

    if (res.data is Map<String, dynamic>) {
      final data = res.data as Map<String, dynamic>;
      // Many backends wrap in { data: {...} }
      if (data['data'] is Map<String, dynamic>) {
        return (data['data'] as Map).cast<String, dynamic>();
      }
      return data;
    }
    return null;
  }

  Future<String> _requestUploadUrl() async {
    final res = await _dio.get('/profile-images/upload-url');
    return _readString(res.data, 'uploadUrl') ??
        _readString(res.data, 'data.uploadUrl') ??
        _readString(res.data, 'url') ??
        (throw DioException(
          requestOptions: res.requestOptions,
          error: 'Missing uploadUrl in response',
        ));
  }

  Future<void> _uploadToStorage(
    String uploadUrl,
    XFile file,
    int length,
    String contentType,
    void Function(double progress)? onProgress,
  ) async {
    final dio = Dio(BaseOptions(contentType: contentType));
    final stream = file.openRead();
    try {
      await dio.put<void>(
        uploadUrl,
        data: stream,
        options: Options(
          headers: {'Content-Type': contentType, 'Content-Length': length},
          followRedirects: false,
          validateStatus: (status) => status != null && status < 400,
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            onProgress?.call(sent / total);
          }
        },
      );
    } on DioException catch (error) {
      throw DioException(
        requestOptions: error.requestOptions,
        response: error.response,
        type: error.type,
        error: error.error ?? error.message,
      );
    } catch (error) {
      throw DioException(
        requestOptions: RequestOptions(path: uploadUrl),
        error: error,
      );
    }
  }

  Future<ProfileImage> _saveImageMetadata({
    required String userId,
    required String storageId,
    required String fileName,
    required String contentType,
    required int fileSize,
  }) async {
    final res = await _dio.post(
      '/profile-images',
      data: {
        'userId': userId,
        'storageId': storageId,
        'fileName': fileName,
        'contentType': contentType,
        'fileSize': fileSize,
      },
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return ProfileImage.fromJson(
          (data['data'] as Map).cast<String, dynamic>(),
        );
      }
      if (data['image'] is Map<String, dynamic>) {
        return ProfileImage.fromJson(
          (data['image'] as Map).cast<String, dynamic>(),
        );
      }
      return ProfileImage.fromJson(data);
    }
    throw DioException(
      requestOptions: res.requestOptions,
      error: 'Unexpected metadata response',
    );
  }

  String _extractStorageId(String uploadUrl) {
    final uri = Uri.parse(uploadUrl);
    final segments = uri.pathSegments;
    if (segments.isEmpty) return uploadUrl;
    final last = segments.last;
    final index = last.indexOf('?');
    return index == -1 ? last : last.substring(0, index);
  }

  String? _inferContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return 'image/jpeg';
  }

  String? _readString(dynamic data, String path) {
    if (data == null) return null;
    final parts = path.split('.');
    dynamic current = data;
    for (final part in parts) {
      if (current is Map<String, dynamic>) {
        current = current[part];
      } else if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current?.toString();
  }

  // endregion
}
