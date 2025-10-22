import 'package:aroosi_flutter/core/firebase_service.dart';
import 'chat_models.dart';

class ChatRepository {
  final FirebaseService _firebase = FirebaseService();

  Future<List<ChatMessage>> getMessages({
    required String conversationId,
    int? before, // epoch millis for pagination
    int? limit,
  }) async {
    try {
      final messages = await _firebase.getMessages(
        conversationId: conversationId,
        limit: limit,
      );
      
      return messages
          .map((message) => ChatMessage.fromJson(message))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String text,
    String? toUserId,
  }) async {
    // Get current user ID for fromUserId field
    final currentUser = _firebase.currentUser?.uid;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    await _firebase.sendMessage(
      conversationId: conversationId,
      text: text,
      fromUserId: currentUser,
      toUserId: toUserId,
    );

    // Return a mock message object
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      fromUserId: currentUser,
      toUserId: toUserId,
      text: text,
      type: 'text',
      createdAt: DateTime.now(),
    );
  }

  // Delete a message
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    // Implementation would go here
  }

  Future<void> markAsRead(String conversationId) async {
    // Implementation would go here
  }

  Future<List<ConversationSummary>> getConversations() async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, return empty list
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<String> createConversation({
    required List<String> participantIds,
  }) async {
    try {
      return await _firebase.createConversation(participantIds);
    } catch (e) {
      throw Exception('Failed to create conversation: ${e.toString()}');
    }
  }

  // Typing indicator (no-op over HTTP; typically handled via realtime)
  Future<void> sendTypingIndicator({
    required String conversationId,
    required bool isTyping,
  }) async {
    // Intentionally a no-op. Hook up to realtime service when available.
    return;
  }

  // Delivery receipts (no-op placeholder)
  Future<void> sendDeliveryReceipt({
    required String messageId,
    required String status, // e.g., 'delivered' | 'read'
  }) async {
    // No REST endpoint; server infers from read events. Keep for parity.
    return;
  }

  // Image message upload
  Future<ChatMessage> uploadImageMessage({
    required String conversationId,
    required List<int> bytes,
    String filename = 'image.jpg',
    String contentType = 'image/jpeg',
    String? toUserId,
  }) async {
    try {
      final currentUser = _firebase.currentUser?.uid;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // For now, return a mock image message
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: conversationId,
        fromUserId: currentUser,
        toUserId: toUserId,
        text: 'Image message',
        type: 'image',
        imageUrl: 'https://placeholder.com/image.jpg', // Would be actual upload URL
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  Future<String> getVoiceMessageUrl(String messageId) async {
    try {
      // This would need to be implemented in FirebaseService
      return 'https://placeholder.com/voice.m4a';
    } catch (_) {
      return 'https://placeholder.com/voice.m4a';
    }
  }

  Future<ChatMessage> sendVoiceMessage({
    required String conversationId,
    required List<int> bytes,
    required int durationSeconds,
    String filename = 'voice-message.m4a',
    String contentType = 'audio/m4a',
    String? toUserId,
  }) async {
    try {
      final currentUser = _firebase.currentUser?.uid;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // For now, return a mock voice message
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: conversationId,
        fromUserId: currentUser,
        toUserId: toUserId,
        text: 'Voice message (${_formatDuration(durationSeconds)})',
        type: 'voice',
        audioUrl: 'https://placeholder.com/voice.m4a',
        duration: durationSeconds,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to send voice message: ${e.toString()}');
    }
  }

  // Alias for uploadImageMessage for compatibility
  Future<ChatMessage> uploadImageMessageMultipart({
    required String conversationId,
    required List<int> bytes,
    String filename = 'image.jpg',
    String contentType = 'image/jpeg',
    String? toUserId,
  }) async {
    return uploadImageMessage(
      conversationId: conversationId,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      toUserId: toUserId,
    );
  }

  Future<Map<String, String>> getBatchProfileImages(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};
    
    // For now, return empty mapping
    return <String, String>{};
  }

  // Unread counts across matches/conversations
  Future<Map<String, dynamic>> getUnreadCounts() async {
    return {};
  }

  // Mark specific messages as read
  Future<void> markMessagesAsRead(List<String> messageIds) async {
    if (messageIds.isEmpty) return;
  }

  // Conversation events (optional parity)
  Future<List<dynamic>> getConversationEvents(String conversationId) async {
    return <dynamic>[];
  }

  // Presence API
  Future<Map<String, dynamic>> getPresence(String userId) async {
    return {'isOnline': false};
  }

  // Reaction methods
  Future<void> addReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    // Implementation would go here
  }

  Future<void> removeReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    // Implementation would go here
  }

  // Helper methods
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '${remainingSeconds}s';
  }
}
