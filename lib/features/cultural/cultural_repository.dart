import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/core/api_client.dart';
import 'package:aroosi_flutter/features/profiles/models.dart';

final culturalRepositoryProvider = Provider<CulturalRepository>(
  (ref) => CulturalRepository(),
);

class CulturalRepository {
  CulturalRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;
  final Dio _dio;

  // region: Cultural Profile Management

  /// Update user's cultural profile information
  Future<Map<String, dynamic>> updateCulturalProfile(
    String userId,
    CulturalProfile culturalProfile,
  ) async {
    try {
      final response = await _dio.put(
        '/cultural/profile/$userId',
        data: culturalProfile.toJson(),
      );

      final responseData = response.data as Map<String, dynamic>? ?? {};
      if (responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Cultural profile updated successfully',
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to update cultural profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get user's cultural profile information
  Future<CulturalProfile?> getCulturalProfile([String? userId]) async {
    try {
      final path = userId != null ? '/cultural/profile/$userId' : '/cultural/profile/me';
      final response = await _dio.get(path);
      final responseData = response.data as Map<String, dynamic>? ?? {};

      if (responseData['success'] == true && responseData['culturalProfile'] != null) {
        return CulturalProfile.fromJson(responseData['culturalProfile'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // region: Family Approval Workflow

  /// Request family approval for a potential match
  Future<Map<String, dynamic>> requestFamilyApproval({
    required String targetUserId,
    required String message,
    String? familyMemberId,
    String? familyMemberName,
    String? familyMemberRelation,
  }) async {
    try {
      final response = await _dio.post(
        '/cultural/family-approval/request',
        data: {
          'targetUserId': targetUserId,
          'message': message,
          if (familyMemberId != null) 'familyMemberId': familyMemberId,
          if (familyMemberName != null) 'familyMemberName': familyMemberName,
          if (familyMemberRelation != null) 'familyMemberRelation': familyMemberRelation,
        },
      );

      final responseData = response.data as Map<String, dynamic>? ?? {};
      if (responseData['success'] == true) {
        return {
          'success': true,
          'requestId': responseData['requestId']?.toString(),
          'message': responseData['message'] ?? 'Family approval request sent successfully',
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to send family approval request',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Respond to a family approval request (approve/reject)
  Future<Map<String, dynamic>> respondToFamilyApproval({
    required String requestId,
    required bool approved,
    String? response,
  }) async {
    try {
      final responseData = await _dio.post(
        '/cultural/family-approval/respond',
        data: {
          'requestId': requestId,
          'approved': approved,
          if (response != null && response.isNotEmpty) 'response': response,
        },
      );

      final data = responseData.data as Map<String, dynamic>? ?? {};
      if (data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Response submitted successfully',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to submit response',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get family approval requests for current user
  Future<List<FamilyApprovalRequest>> getFamilyApprovalRequests({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/cultural/family-approval/requests',
        queryParameters: queryParams,
      );

      final responseData = response.data as Map<String, dynamic>? ?? {};
      if (responseData['success'] == true) {
        final requests = responseData['requests'] as List<dynamic>? ?? [];
        return requests
            .map((e) => FamilyApprovalRequest.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Get family approval requests sent to current user
  Future<List<FamilyApprovalRequest>> getReceivedFamilyApprovalRequests({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/cultural/family-approval/received',
        queryParameters: queryParams,
      );

      final responseData = response.data as Map<String, dynamic>? ?? {};
      if (responseData['success'] == true) {
        final requests = responseData['requests'] as List<dynamic>? ?? [];
        return requests
            .map((e) => FamilyApprovalRequest.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // region: Supervised Communication

  /// Initiate supervised communication for traditional courtship
  Future<Map<String, dynamic>> initiateSupervisedConversation({
    required String participant2Id,
    required String supervisorId,
    List<String>? rules,
    int? timeLimit,
    List<String>? topicRestrictions,
  }) async {
    try {
      final response = await _dio.post(
        '/cultural/supervised-conversation/initiate',
        data: {
          'participant2Id': participant2Id,
          'supervisorId': supervisorId,
          if (rules != null) 'rules': rules,
          if (timeLimit != null) 'timeLimit': timeLimit,
          if (topicRestrictions != null) 'topicRestrictions': topicRestrictions,
        },
      );

      final responseData = response.data as Map<String, dynamic>? ?? {};
      if (responseData['success'] == true) {
        return {
          'success': true,
          'conversationId': responseData['conversationId']?.toString(),
          'message': responseData['message'] ?? 'Supervised conversation initiated successfully',
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to initiate supervised conversation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get supervised conversations for current user
  Future<List<SupervisedConversation>> getSupervisedConversations({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/cultural/supervised-conversation/list',
        queryParameters: queryParams,
      );

      final responseData = response.data as Map<String, dynamic>? ?? {};
      if (responseData['success'] == true) {
        final conversations = responseData['conversations'] as List<dynamic>? ?? [];
        return conversations
            .map((e) => SupervisedConversation.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Update supervised conversation settings (supervisor only)
  Future<Map<String, dynamic>> updateSupervisedConversation({
    required String conversationId,
    String? status,
    List<String>? rules,
    int? timeLimit,
    List<String>? topicRestrictions,
  }) async {
    try {
      final response = await _dio.put(
        '/cultural/supervised-conversation/$conversationId',
        data: {
          if (status != null) 'status': status,
          if (rules != null) 'rules': rules,
          if (timeLimit != null) 'timeLimit': timeLimit,
          if (topicRestrictions != null) 'topicRestrictions': topicRestrictions,
        },
      );

      final responseData = response.data as Map<String, dynamic>? ?? {};
      if (responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Conversation updated successfully',
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to update conversation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // region: Cultural Compatibility Matching

  /// Get cultural compatibility score between two users
  Future<Map<String, dynamic>> getCulturalCompatibility(String userId1, String userId2) async {
    try {
      final response = await _dio.get(
        '/cultural/compatibility/$userId1/$userId2',
      );

      final responseData = response.data as Map<String, dynamic>? ?? {};
      if (responseData['success'] == true) {
        return {
          'success': true,
          'compatibility': responseData['compatibility'] as Map<String, dynamic>? ?? {},
          'score': responseData['score'] as num? ?? 0,
          'insights': responseData['insights'] as List<dynamic>? ?? [],
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to calculate compatibility',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get cultural compatibility recommendations
  Future<List<Map<String, dynamic>>> getCulturalRecommendations({
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/cultural/recommendations',
        queryParameters: {'limit': limit},
      );

      final responseData = response.data as Map<String, dynamic>? ?? {};
      if (responseData['success'] == true) {
        final recommendations = responseData['recommendations'] as List<dynamic>? ?? [];
        return recommendations.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
