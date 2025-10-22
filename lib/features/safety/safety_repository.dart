import 'package:aroosi_flutter/core/firebase_service.dart';

class SafetyRepository {
  final FirebaseService _firebase = FirebaseService();

  Future<Map<String, dynamic>> reportUser({
    required String userId,
    required String reason,
    String? details,
  }) async {
    try {
      await _firebase.reportUser(
        reportedUserId: userId,
        reason: reason,
        description: details,
      );
      return {
        'success': true,
        'message': 'Report submitted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to submit report: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> blockUser(String userId) async {
    try {
      await _firebase.blockUser(userId);
      return {
        'success': true,
        'message': 'User blocked successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to block user: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> unblockUser(String userId) async {
    try {
      await _firebase.unblockUser(userId);
      return {
        'success': true,
        'message': 'User unblocked successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to unblock user: ${e.toString()}',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    try {
      return await _firebase.getBlockedUsers();
    } catch (e) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<Map<String, dynamic>> isBlocked(String userId) async {
    try {
      final blockedUsers = await _firebase.getBlockedUsers();
      final isBlocked = blockedUsers.any((block) => block['blockedUserId'] == userId);
      
      return {
        'isBlocked': isBlocked,
        'isBlockedBy': false,
        'canInteract': !isBlocked,
      };
    } catch (_) {
      return {
        'isBlocked': false,
        'isBlockedBy': false,
        'canInteract': true,
      };
    }
  }
}
