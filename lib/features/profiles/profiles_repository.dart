import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:aroosi_flutter/core/firebase_service.dart';
import 'package:aroosi_flutter/utils/debug_logger.dart';

import 'models.dart';
import 'profile_image.dart';

final profilesRepositoryProvider = Provider<ProfilesRepository>(
  (ref) => ProfilesRepository(),
);

class ProfilesRepository {
  final FirebaseService _firebase = FirebaseService();

  // region: Profile listing/search

  Future<PagedResponse<MatchEntry>> getMatches({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final matches = await _firebase.getMatches(limit: pageSize);

      final items = matches.map((match) => MatchEntry.fromJson(match)).toList();

      return PagedResponse(
        items: items,
        page: page,
        pageSize: pageSize,
        total: items.length,
      );
    } catch (e) {
      logDebug('Error getting matches', error: e);
      return const PagedResponse(items: [], page: 1, pageSize: 0, total: 0);
    }
  }

  Future<PagedResponse<ProfileSummary>> search({
    required SearchFilters filters,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final profiles = await _firebase.searchProfiles(
        filters: filters.toJson(),
        limit: pageSize,
      );

      final items = profiles
          .map((profile) => ProfileSummary.fromJson(profile))
          .toList();

      return PagedResponse(
        items: items,
        page: page,
        pageSize: pageSize,
        total: items.length,
      );
    } catch (e) {
      logDebug('Error searching profiles', error: e);
      return const PagedResponse(items: [], page: 1, pageSize: 0, total: 0);
    }
  }

  Future<PagedResponse<ProfileSummary>> getFavorites({
    int page = 1,
    int pageSize = 20,
  }) async {
    // This would need to be implemented in FirebaseService
    return const PagedResponse(items: [], page: 1, pageSize: 0, total: 0);
  }

  Future<PagedResponse<ProfileSummary>> getShortlist({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final shortlist = await _firebase.getShortlist(limit: pageSize);

      final items = shortlist
          .map((profile) => ProfileSummary.fromJson(profile))
          .toList();

      return PagedResponse(
        items: items,
        page: page,
        pageSize: pageSize,
        total: items.length,
      );
    } catch (e) {
      logDebug('Error getting shortlist', error: e);
      return const PagedResponse(items: [], page: 1, pageSize: 0, total: 0);
    }
  }

  Future<PagedResponse<ShortlistEntry>> getShortlistEntries({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final shortlist = await _firebase.getShortlist(limit: pageSize);

      final items = shortlist
          .map((profile) => ShortlistEntry.fromJson(profile))
          .toList();

      return PagedResponse(
        items: items,
        page: page,
        pageSize: pageSize,
        total: items.length,
      );
    } catch (e) {
      logDebug('Error getting shortlist entries', error: e);
      return const PagedResponse(items: [], page: 1, pageSize: 0, total: 0);
    }
  }

  Future<bool> toggleFavorite(String profileId) async {
    // This would need to be implemented in FirebaseService
    return false;
  }

  Future<bool> toggleShortlist(String profileId) async {
    try {
      // Check if already in shortlist
      final shortlist = await _firebase.getShortlist();
      final isAlreadyShortlisted = shortlist.any(
        (profile) => profile['userId'] == profileId,
      );

      if (isAlreadyShortlisted) {
        await _firebase.removeFromShortlist(profileId);
      } else {
        await _firebase.addToShortlist(profileId);
      }

      return true;
    } catch (e) {
      logDebug('Error toggling shortlist', error: e);
      return false;
    }
  }

  Future<Map<String, dynamic>> toggleShortlistEntry(String userId) async {
    try {
      final success = await toggleShortlist(userId);
      return {
        'success': success,
        'data': {'userId': userId},
        'error': success ? null : 'Failed to toggle shortlist',
      };
    } catch (e) {
      return {'success': false, 'data': null, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> fetchNote(String userId) async {
    // This would need to be implemented in FirebaseService
    return null;
  }

  Future<bool> setNote(String userId, String note) async {
    // This would need to be implemented in FirebaseService
    return false;
  }

  Future<bool> boostProfile() async {
    // This would need to be implemented in FirebaseService
    return false;
  }

  // Interests management
  Future<Map<String, dynamic>> manageInterest({
    required String action,
    String? toUserId,
    String? interestId,
    String? status,
  }) async {
    try {
      switch (action) {
        case 'send':
          await _firebase.sendInterest(toUserId!);
          break;
        case 'respond':
          if (interestId != null && status != null) {
            await _firebase.respondToInterest(interestId, status);
          }
          break;
        case 'remove':
          // This would need to be implemented
          break;
      }

      return {'success': true, 'data': {}, 'error': null};
    } catch (e) {
      return {'success': false, 'data': null, 'error': e.toString()};
    }
  }

  Future<PagedResponse<InterestEntry>> getInterests({
    required String mode,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final interests = await _firebase.getInterests(
        mode: mode,
        limit: pageSize,
      );

      final items = interests
          .map((interest) => InterestEntry.fromJson(interest))
          .toList();

      return PagedResponse(
        items: items,
        page: page,
        pageSize: pageSize,
        total: items.length,
      );
    } catch (e) {
      logDebug('Error getting interests', error: e);
      return const PagedResponse(items: [], page: 1, pageSize: 0, total: 0);
    }
  }

  Future<Map<String, dynamic>?> checkInterestStatus({
    required String fromUserId,
    required String toUserId,
  }) async {
    // This would need to be implemented in FirebaseService
    return null;
  }

  Future<bool> sendInterest(String profileId) async {
    try {
      await _firebase.sendInterest(profileId);
      return true;
    } catch (e) {
      logDebug('Error sending interest', error: e);
      return false;
    }
  }

  Future<List<String>> getInterestOptions() async {
    return [
      'Arts & Culture',
      'Travel',
      'Fitness',
      'Music',
      'Foodie',
      'Tech',
      'Outdoors',
    ];
  }

  Future<Set<String>> getSelectedInterests() async {
    // This would need to be implemented in FirebaseService
    return <String>{};
  }

  Future<bool> saveSelectedInterests(Set<String> interests) async {
    // This would need to be implemented in FirebaseService
    return false;
  }

  /// Get profile details by user ID
  Future<Map<String, dynamic>?> getProfileById(String id) async {
    try {
      return await _firebase.getProfileById(id);
    } catch (e) {
      logDebug('Error getting profile by ID', error: e);
      return null;
    }
  }

  // region: Unread messages and conversation management

  Future<Map<String, int>> getUnreadMessageCounts() async {
    return {};
  }

  Future<void> markConversationAsRead(String conversationId) async {
    // Implementation would go here
  }

  // region: Block management

  Future<bool> isUserBlocked(String userId) async {
    try {
      final blockedUsers = await _firebase.getBlockedUsers();
      return blockedUsers.any((block) => block['blockedUserId'] == userId);
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> blockUser(String userId) async {
    try {
      await _firebase.blockUser(userId);
      return {'success': true, 'error': null};
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
      return {'success': true, 'error': null};
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to unblock user: ${e.toString()}',
      };
    }
  }

  // region: Profile images

  Future<List<ProfileImage>> fetchProfileImages({String? userId}) async {
    try {
      // This would need to be implemented in FirebaseService
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<ProfileImage> uploadProfileImage({
    required XFile file,
    required String userId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final imageUrl = await _firebase.uploadProfileImage(file, userId);

      final imageId = DateTime.now().millisecondsSinceEpoch.toString();
      final storageId = imageId; // Use same ID for simplicity

      return ProfileImage(id: imageId, storageId: storageId, url: imageUrl);
    } catch (e) {
      logDebug('Error uploading profile image', error: e);
      rethrow;
    }
  }

  Future<void> deleteProfileImage({
    required String userId,
    required String imageId,
  }) async {
    // Implementation would go here
  }

  Future<void> reorderProfileImages({
    required String userId,
    required List<String> imageIds,
  }) async {
    // Implementation would go here
  }

  /// Get the current authenticated user's profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      return await _firebase.getCurrentUserProfile();
    } catch (e) {
      logDebug('Error getting current user profile', error: e);
      return null;
    }
  }

  /// Creates a profile
  Future<Map<String, dynamic>?> createProfile(
    Map<String, dynamic> payload,
  ) async {
    try {
      return await _firebase.createProfile(payload);
    } catch (e) {
      logDebug('Error creating profile', error: e);
      rethrow;
    }
  }

  /// Update the current user's profile
  Future<Map<String, dynamic>?> updateProfile(
    Map<String, dynamic> updates,
  ) async {
    try {
      return await _firebase.updateProfile(updates);
    } catch (e) {
      logDebug('Error updating profile', error: e);
      rethrow;
    }
  }

  /// Get dashboard statistics (admin only)
  Future<Map<String, dynamic>?> getDashboardStats() async {
    // This would need to be implemented in FirebaseService
    return null;
  }
}
