import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/features/profiles/models.dart';
import 'cultural_repository.dart';

/// State for cultural features
class CulturalState {
  const CulturalState({
    this.culturalProfile,
    this.familyApprovalRequests = const [],
    this.receivedFamilyApprovalRequests = const [],
    this.supervisedConversations = const [],
    this.compatibility,
    this.loading = false,
    this.error,
  });

  final CulturalProfile? culturalProfile;
  final List<FamilyApprovalRequest> familyApprovalRequests;
  final List<FamilyApprovalRequest> receivedFamilyApprovalRequests;
  final List<SupervisedConversation> supervisedConversations;
  final Map<String, dynamic>? compatibility;
  final bool loading;
  final String? error;

  CulturalState copyWith({
    CulturalProfile? culturalProfile,
    List<FamilyApprovalRequest>? familyApprovalRequests,
    List<FamilyApprovalRequest>? receivedFamilyApprovalRequests,
    List<SupervisedConversation>? supervisedConversations,
    Map<String, dynamic>? compatibility,
    bool? loading,
    String? error,
  }) => CulturalState(
    culturalProfile: culturalProfile ?? this.culturalProfile,
    familyApprovalRequests: familyApprovalRequests ?? this.familyApprovalRequests,
    receivedFamilyApprovalRequests: receivedFamilyApprovalRequests ?? this.receivedFamilyApprovalRequests,
    supervisedConversations: supervisedConversations ?? this.supervisedConversations,
    compatibility: compatibility ?? this.compatibility,
    loading: loading ?? this.loading,
    error: error ?? this.error,
  );
}

final culturalControllerProvider = NotifierProvider<CulturalController, CulturalState>(
  CulturalController.new,
);

class CulturalController extends Notifier<CulturalState> {
  late final CulturalRepository _repo;

  @override
  CulturalState build() {
    _repo = ref.read(culturalRepositoryProvider);
    return const CulturalState();
  }

  
  // region: Cultural Profile Management

  Future<void> loadCulturalProfile(String userId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final profile = await _repo.getCulturalProfile(userId);
      state = state.copyWith(
        culturalProfile: profile,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Failed to load cultural profile: ${e.toString()}',
      );
    }
  }

  Future<bool> updateCulturalProfile(String userId, CulturalProfile profile) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _repo.updateCulturalProfile(userId, profile);
      if (result['success'] == true) {
        state = state.copyWith(
          culturalProfile: profile,
          loading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          loading: false,
          error: result['error'] ?? 'Failed to update profile',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Failed to update cultural profile: ${e.toString()}',
      );
      return false;
    }
  }

  // region: Family Approval Workflow

  Future<void> loadFamilyApprovalRequests() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final requests = await _repo.getFamilyApprovalRequests();
      final receivedRequests = await _repo.getReceivedFamilyApprovalRequests();
      state = state.copyWith(
        familyApprovalRequests: requests,
        receivedFamilyApprovalRequests: receivedRequests,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Failed to load family approval requests: ${e.toString()}',
      );
    }
  }

  Future<bool> requestFamilyApproval({
    required String targetUserId,
    required String message,
    String? familyMemberId,
    String? familyMemberName,
    String? familyMemberRelation,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _repo.requestFamilyApproval(
        targetUserId: targetUserId,
        message: message,
        familyMemberId: familyMemberId,
        familyMemberName: familyMemberName,
        familyMemberRelation: familyMemberRelation,
      );

      if (result['success'] == true) {
        // Refresh the requests list
        await loadFamilyApprovalRequests();
        return true;
      } else {
        state = state.copyWith(
          loading: false,
          error: result['error'] ?? 'Failed to send request',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Failed to send family approval request: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> respondToFamilyApproval({
    required String requestId,
    required bool approved,
    String? response,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _repo.respondToFamilyApproval(
        requestId: requestId,
        approved: approved,
        response: response,
      );

      if (result['success'] == true) {
        // Refresh the requests list
        await loadFamilyApprovalRequests();
        return true;
      } else {
        state = state.copyWith(
          loading: false,
          error: result['error'] ?? 'Failed to submit response',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Failed to respond to family approval request: ${e.toString()}',
      );
      return false;
    }
  }

  // region: Supervised Communication

  Future<void> loadSupervisedConversations() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final conversations = await _repo.getSupervisedConversations();
      state = state.copyWith(
        supervisedConversations: conversations,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Failed to load supervised conversations: ${e.toString()}',
      );
    }
  }

  Future<bool> initiateSupervisedConversation({
    required String participant2Id,
    required String supervisorId,
    List<String>? rules,
    int? timeLimit,
    List<String>? topicRestrictions,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _repo.initiateSupervisedConversation(
        participant2Id: participant2Id,
        supervisorId: supervisorId,
        rules: rules,
        timeLimit: timeLimit,
        topicRestrictions: topicRestrictions,
      );

      if (result['success'] == true) {
        // Refresh the conversations list
        await loadSupervisedConversations();
        return true;
      } else {
        state = state.copyWith(
          loading: false,
          error: result['error'] ?? 'Failed to initiate conversation',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Failed to initiate supervised conversation: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> updateSupervisedConversation({
    required String conversationId,
    String? status,
    List<String>? rules,
    int? timeLimit,
    List<String>? topicRestrictions,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _repo.updateSupervisedConversation(
        conversationId: conversationId,
        status: status,
        rules: rules,
        timeLimit: timeLimit,
        topicRestrictions: topicRestrictions,
      );

      if (result['success'] == true) {
        // Refresh the conversations list
        await loadSupervisedConversations();
        return true;
      } else {
        state = state.copyWith(
          loading: false,
          error: result['error'] ?? 'Failed to update conversation',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Failed to update supervised conversation: ${e.toString()}',
      );
      return false;
    }
  }

  // region: Cultural Compatibility

  Future<void> loadCompatibility(String userId1, String userId2) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final compatibility = await _repo.getCulturalCompatibility(userId1, userId2);
      state = state.copyWith(
        compatibility: compatibility,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Failed to load compatibility data: ${e.toString()}',
      );
    }
  }

  Future<Map<String, dynamic>> getCulturalCompatibility(String userId1, String userId2) async {
    try {
      return await _repo.getCulturalCompatibility(userId1, userId2);
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to get compatibility: ${e.toString()}',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getCulturalRecommendations({int limit = 10}) async {
    try {
      return await _repo.getCulturalRecommendations(limit: limit);
    } catch (e) {
      return [];
    }
  }

  // Utility methods
  void clearError() {
    state = state.copyWith(error: null);
  }
}
