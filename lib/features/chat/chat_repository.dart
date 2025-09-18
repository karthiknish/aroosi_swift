import 'package:dio/dio.dart';

import 'package:aroosi_flutter/core/api_client.dart';
import 'chat_models.dart';

class ChatRepository {
  ChatRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<List<ChatMessage>> getMessages({
    required String conversationId,
    int? before, // epoch millis for pagination
    int? limit,
  }) async {
    final qp = <String, dynamic>{};
    if (before != null) qp['before'] = before;
    if (limit != null) qp['limit'] = limit;
    Response res;
    // Try web-first unified endpoint: /messages/messages?conversationId=...
    try {
      final params = {'conversationId': conversationId, ...qp};
      res = await _dio.get('/messages/messages', queryParameters: params);
    } on DioException catch (e1) {
      // Fallback 1: legacy mobile unified endpoint
      if (e1.response?.statusCode == 404) {
        try {
          final params = {'conversationId': conversationId, ...qp};
          res = await _dio.get('/match-messages', queryParameters: params);
        } on DioException catch (e2) {
          // Fallback 2: conversation-scoped endpoint
          if (e2.response?.statusCode == 404) {
            try {
              res = await _dio.get(
                '/conversations/$conversationId/messages',
                queryParameters: qp,
              );
            } on DioException {
              rethrow;
            }
          } else {
            rethrow;
          }
        }
      } else {
        rethrow;
      }
    }
    final data = res.data;
    final list = data is List
        ? data
        : (data is Map && data['messages'] is List)
        ? data['messages'] as List
        : <dynamic>[];
    return list
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String text,
    String? toUserId,
    String? replyToMessageId,
  }) async {
    Response res;
    final body = {
      'conversationId': conversationId,
      if (toUserId != null) 'toUserId': toUserId,
      'text': text,
      'type': 'text',
      if (replyToMessageId != null) 'replyTo': replyToMessageId,
    };
    // Try unified web endpoint first
    try {
      res = await _dio.post('/messages/send', data: body);
    } on DioException catch (e1) {
      if (e1.response?.statusCode == 404) {
        // Fallback 1: legacy posting endpoint
        try {
          res = await _dio.post('/messages', data: body);
        } on DioException catch (e2) {
          if (e2.response?.statusCode == 404) {
            // Fallback 2: legacy mobile endpoint name
            try {
              res = await _dio.post('/match-messages', data: body);
            } on DioException catch (e3) {
              if (e3.response?.statusCode == 404) {
                // Fallback 3: conversation-scoped create
                res = await _dio.post(
                  '/conversations/$conversationId/messages',
                  data: body,
                );
              } else {
                rethrow;
              }
            }
          } else {
            rethrow;
          }
        }
      } else {
        rethrow;
      }
    }
    final data = res.data is Map
        ? Map<String, dynamic>.from(res.data as Map)
        : <String, dynamic>{};
    final payload = data['message'] is Map<String, dynamic>
        ? data['message'] as Map<String, dynamic>
        : data;
    return ChatMessage.fromJson(payload);
  }

  // React to a message with an emoji
  Future<void> addReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    // Prefer unified reactions endpoint
    try {
      await _dio.post(
        '/reactions',
        data: {
          'conversationId': conversationId,
          'messageId': messageId,
          'emoji': emoji,
        },
      );
      return;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Fallback: message-scoped path
        await _dio.post(
          '/messages/$messageId/reactions',
          data: {'emoji': emoji},
        );
        return;
      }
      rethrow;
    }
  }

  Future<void> removeReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      await _dio.delete(
        '/reactions',
        data: {
          'conversationId': conversationId,
          'messageId': messageId,
          'emoji': emoji,
        },
      );
      return;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        await _dio.delete(
          '/messages/$messageId/reactions',
          data: {'emoji': emoji},
        );
        return;
      }
      rethrow;
    }
  }

  // Delete a message
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      await _dio.delete(
        '/messages/$messageId',
        data: {'conversationId': conversationId},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        await _dio.post(
          '/messages/delete',
          data: {'conversationId': conversationId, 'messageId': messageId},
        );
        return;
      }
      rethrow;
    }
  }

  Future<void> markAsRead(String conversationId) async {
    // Try unified web endpoint first
    try {
      await _dio.post(
        '/messages/mark-read',
        data: {'conversationId': conversationId},
      );
      return;
    } on DioException catch (e1) {
      if (e1.response?.statusCode == 404) {
        // Fallback: legacy read endpoint
        try {
          await _dio.post(
            '/messages/read',
            data: {'conversationId': conversationId},
          );
          return;
        } on DioException catch (e2) {
          if (e2.response?.statusCode == 404) {
            // Final fallback: conversation-scoped read
            await _dio.post('/conversations/$conversationId/read');
          } else {
            rethrow;
          }
        }
      } else {
        rethrow;
      }
    }
  }

  Future<List<ConversationSummary>> getConversations() async {
    Response res;
    res = await _dio.get('/conversations');
    final data = res.data;
    final list = data is List
        ? data
        : (data is Map && data['conversations'] is List)
        ? data['conversations'] as List
        : <dynamic>[];
    return list
        .map(
          (e) =>
              ConversationSummary.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<Map<String, String>> getBatchProfileImages(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};
    Response res;
    res = await _dio.get(
      '/profile-images/batch',
      queryParameters: {'userIds': userIds.join(',')},
    );
    final data = res.data;
    // Expect shapes: { data: { <userId>: [urls...] } } or { <userId>: [urls...] }
    final mapObj = data is Map && data['data'] is Map
        ? data['data'] as Map
        : (data is Map ? data : <String, dynamic>{});
    final mapping = <String, String>{};
    mapObj.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        mapping[key.toString()] = value.first.toString();
      }
    });
    return mapping;
  }

  Future<String> createConversation({
    required List<String> participantIds,
  }) async {
    Response res;
    res = await _dio.post(
      '/conversations',
      data: {'participantIds': participantIds},
    );
    final data = res.data is Map
        ? Map<String, dynamic>.from(res.data as Map)
        : <String, dynamic>{};
    final id =
        data['id']?.toString() ??
        data['_id']?.toString() ??
        data['conversationId']?.toString();
    if (id == null || id.isEmpty) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'Failed to create conversation',
      );
    }
    return id;
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

  // Voice message helpers (parity with RN; optional use)
  Future<Map<String, String>> generateVoiceUploadUrl() async {
    // Simulate unified endpoint that returns { uploadUrl, storageId }
    // If backend provides another path, replace here.
    final storageId = 'voice_${DateTime.now().millisecondsSinceEpoch}';
    final base = ApiClient.dio.options.baseUrl;
    return {'uploadUrl': '$base/voice-messages/upload', 'storageId': storageId};
  }

  Future<void> uploadVoiceMessage({
    required String uploadUrl,
    required List<int> bytes,
    String contentType = 'audio/m4a',
  }) async {
    // Best-effort upload using Dio to the provided URL
    await Dio().put(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(headers: {'Content-Type': contentType}),
    );
  }

  Future<String> getVoiceMessageUrl(String storageId) async {
    // If server provides signed URL endpoint, call it; else construct path
    try {
      final res = await _dio.get('/voice-messages/$storageId/url');
      final data = res.data;
      if (data is Map && data['url'] is String) return data['url'] as String;
    } catch (_) {
      // ignore
    }
    final base = ApiClient.dio.options.baseUrl;
    return '$base/voice-messages/$storageId';
  }

  // Image message upload (web-first multipart, fallback to two-step)
  Future<ChatMessage> uploadImageMessageMultipart({
    required String conversationId,
    required List<int> bytes,
    String filename = 'image.jpg',
    String contentType = 'image/jpeg',
    String? toUserId,
    String? caption,
  }) async {
    final form = FormData.fromMap({
      'conversationId': conversationId,
      if (toUserId != null) 'toUserId': toUserId,
      if (caption != null) 'caption': caption,
      // Dio v5 MultipartFile uses MediaType via http_parser in some setups; to avoid extra deps, omit contentType here and set header on request if needed.
      'image': MultipartFile.fromBytes(bytes, filename: filename),
    });
    Response res;
    try {
      res = await _dio.post('/messages/upload-image', data: form);
    } on DioException catch (_) {
      // Fallback to two-step
      return uploadImageMessageTwoStep(
        conversationId: conversationId,
        bytes: bytes,
        filename: filename,
        contentType: contentType,
        toUserId: toUserId,
        caption: caption,
      );
    }
    final data = res.data is Map
        ? Map<String, dynamic>.from(res.data as Map)
        : <String, dynamic>{};
    final payload = data['message'] is Map<String, dynamic>
        ? data['message'] as Map<String, dynamic>
        : data;
    return ChatMessage.fromJson(payload);
  }

  Future<ChatMessage> uploadImageMessageTwoStep({
    required String conversationId,
    required List<int> bytes,
    String filename = 'image.jpg',
    String contentType = 'image/jpeg',
    String? toUserId,
    String? caption,
  }) async {
    // Step 1: get upload URL
    final urlRes = await _dio.post('/messages/upload-image-url');
    final uploadUrl = (urlRes.data is Map)
        ? (urlRes.data['uploadUrl']?.toString())
        : null;
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw DioException(
        requestOptions: urlRes.requestOptions,
        message: 'No uploadUrl',
      );
    }
    // Step 2: PUT file to uploadUrl
    await Dio().put(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(headers: {'Content-Type': contentType}),
    );
    // Extract storageId if present in URL (best-effort)
    final storageIdMatch = RegExp(
      r'messages/images/([\w-]+)',
    ).firstMatch(uploadUrl);
    final storageId = storageIdMatch != null ? storageIdMatch.group(1) : null;
    // Step 3: POST metadata to create message
    final meta = {
      'conversationId': conversationId,
      if (toUserId != null) 'toUserId': toUserId,
      if (caption != null) 'caption': caption,
      if (storageId != null) 'storageId': storageId,
      'filename': filename,
      'contentType': contentType,
    };
    final saveRes = await _dio.post('/messages/image', data: meta);
    final data = saveRes.data is Map
        ? Map<String, dynamic>.from(saveRes.data as Map)
        : <String, dynamic>{};
    final payload = data['message'] is Map<String, dynamic>
        ? data['message'] as Map<String, dynamic>
        : data;
    return ChatMessage.fromJson(payload);
  }

  // Unread counts across matches/conversations
  Future<Map<String, dynamic>> getUnreadCounts() async {
    final res = await _dio.get('/matches/unread');
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  // Mark specific messages as read
  Future<void> markMessagesAsRead(List<String> messageIds) async {
    if (messageIds.isEmpty) return;
    await _dio.post('/messages/mark-read', data: {'messageIds': messageIds});
  }

  // Conversation events (optional parity)
  Future<List<dynamic>> getConversationEvents(String conversationId) async {
    final res = await _dio.get('/conversations/$conversationId/events');
    final data = res.data;
    if (data is List) return data;
    if (data is Map && data['events'] is List) return List.from(data['events']);
    return <dynamic>[];
  }

  // Presence API
  Future<Map<String, dynamic>> getPresence(String userId) async {
    final res = await _dio.get(
      '/presence',
      queryParameters: {'userId': userId},
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'isOnline': false};
  }
}
