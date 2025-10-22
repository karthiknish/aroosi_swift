import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:aroosi_flutter/core/env.dart';

/// Realtime service using raw WebSocket to match aroosi (Next.js) implementation.
/// Aligns with Next.js WebSocket message types: join_conversation, message, typing, delivery_receipt, read_receipt.
class RealTimeService {
  RealTimeService._();
  static final RealTimeService instance = RealTimeService._();

  WebSocketChannel? _channel;
  final _connectedCtrl = StreamController<bool>.broadcast();
  final Map<void Function(String, bool), void Function(String)>
  _typingHandlers = {};
  final Map<void Function(String, Map<String, dynamic>), void Function(String)>
  _messageHandlers = {};
  final Map<void Function(String, String, String), void Function(String)>
  _deliveryReceiptHandlers = {};
  final Map<void Function(String, String, String), void Function(String)>
  _readReceiptHandlers = {};
  final Map<void Function(Map<String, dynamic>), void Function(String)>
  _unreadHandlers = {};
  final Map<void Function(String, bool, int?), void Function(String)>
  _presenceHandlers = {};

  Stream<bool> get connectedStream => _connectedCtrl.stream;
  bool get isConnected => _channel != null;

  String get _wsUrl {
    // Convert API base URL to WebSocket URL
    final base = Env.apiBaseUrl;
    if (base.startsWith('https://')) {
      return base
          .replaceFirst('https://', 'wss://')
          .replaceFirst('/api', '/api/websocket');
    } else if (base.startsWith('http://')) {
      return base
          .replaceFirst('http://', 'ws://')
          .replaceFirst('/api', '/api/websocket');
    }
    return base;
  }

  void connect() {
    if (_channel != null) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _connectedCtrl.add(true);

      _channel?.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
            _connectedCtrl.add(false);
        },
        onDone: () {
              _connectedCtrl.add(false);
        },
      );
    } catch (e) {
        _connectedCtrl.add(false);
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _connectedCtrl.add(false);
  }

  void _handleMessage(String message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'joined':
          // Handle successful join response
          break;

        case 'message':
          final conversationId = data['conversationId'] as String?;
          if (conversationId != null) {
            _notifyMessageHandlers(conversationId, data);
          }
          break;

        case 'typing':
          final conversationId = data['conversationId'] as String?;
          final isTyping = data['isTyping'] as bool?;
          if (conversationId != null && isTyping != null) {
            _notifyTypingHandlers(conversationId, isTyping);
          }
          break;

        case 'delivery_receipt':
          final messageId = data['messageId'] as String?;
          final conversationId = data['conversationId'] as String?;
          final userId = data['userId'] as String?;
          if (messageId != null && conversationId != null && userId != null) {
            _notifyDeliveryReceiptHandlers(conversationId, messageId, userId);
          }
          break;

        case 'read_receipt':
          final messageId = data['messageId'] as String?;
          final conversationId = data['conversationId'] as String?;
          final userId = data['userId'] as String?;
          if (messageId != null && conversationId != null && userId != null) {
            _notifyReadReceiptHandlers(conversationId, messageId, userId);
          }
          break;

        case 'pong':
          // Handle ping/pong for connection health
          break;

        case 'error':
            break;
      }
    } catch (e) {
      // Error handling WebSocket message
    }
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_channel == null) return;

    try {
      final jsonMessage = jsonEncode(message);
      _channel?.sink.add(jsonMessage);
    } catch (e) {
      // Error sending WebSocket message
    }
  }

  // Rooms
  void joinConversation(String conversationId) {
    _sendMessage({
      'type': 'join_conversation',
      'conversationId': conversationId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void leaveConversation(String conversationId) {
    _sendMessage({
      'type': 'leave_conversation',
      'conversationId': conversationId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Messages
  void sendMessage({
    required String conversationId,
    required String fromUserId,
    required String toUserId,
    required String content,
    String messageType = 'text',
  }) {
    _sendMessage({
      'type': 'message',
      'conversationId': conversationId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'message': content,
      'messageType': messageType,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Typing
  void sendTyping(String conversationId, {required bool isTyping}) {
    _sendMessage({
      'type': 'typing',
      'conversationId': conversationId,
      'isTyping': isTyping,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Delivery receipts
  void sendDeliveryReceipt({
    required String messageId,
    required String conversationId,
    required String userId,
    String status = 'delivered',
  }) {
    _sendMessage({
      'type': 'delivery_receipt',
      'messageId': messageId,
      'conversationId': conversationId,
      'userId': userId,
      'status': status,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Read receipts
  void sendReadReceipt({
    required String messageId,
    required String conversationId,
    required String userId,
  }) {
    _sendMessage({
      'type': 'read_receipt',
      'messageId': messageId,
      'conversationId': conversationId,
      'userId': userId,
      'status': 'read',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Ping for connection health
  void sendPing() {
    _sendMessage({'type': 'ping'});
  }

  // Handler notifications
  void _notifyTypingHandlers(String conversationId, bool isTyping) {
    for (final handler in _typingHandlers.keys) {
      try {
        handler(conversationId, isTyping);
      } catch (e) {
        debugPrint('Error in typing handler: $e');
      }
    }
  }

  void _notifyMessageHandlers(
    String conversationId,
    Map<String, dynamic> message,
  ) {
    for (final handler in _messageHandlers.keys) {
      try {
        handler(conversationId, message);
      } catch (e) {
        debugPrint('Error in message handler: $e');
      }
    }
  }

  void _notifyDeliveryReceiptHandlers(
    String conversationId,
    String messageId,
    String userId,
  ) {
    for (final handler in _deliveryReceiptHandlers.keys) {
      try {
        handler(conversationId, messageId, userId);
      } catch (e) {
        debugPrint('Error in delivery receipt handler: $e');
      }
    }
  }

  void _notifyReadReceiptHandlers(
    String conversationId,
    String messageId,
    String userId,
  ) {
    for (final handler in _readReceiptHandlers.keys) {
      try {
        handler(conversationId, messageId, userId);
      } catch (e) {
        debugPrint('Error in read receipt handler: $e');
      }
    }
  }



  // Event handlers
  void onTyping(void Function(String conversationId, bool isTyping) handler) {
    _typingHandlers[handler] = (String conversationId) => conversationId;
  }

  void offTyping(void Function(String conversationId, bool isTyping) handler) {
    _typingHandlers.remove(handler);
  }

  void onMessage(
    void Function(String conversationId, Map<String, dynamic> message) handler,
  ) {
    _messageHandlers[handler] = (String conversationId) => conversationId;
  }

  void offMessage(
    void Function(String conversationId, Map<String, dynamic> message) handler,
  ) {
    _messageHandlers.remove(handler);
  }

  void onDeliveryReceipt(
    void Function(String conversationId, String messageId, String userId)
    handler,
  ) {
    _deliveryReceiptHandlers[handler] = (String conversationId) =>
        conversationId;
  }

  void offDeliveryReceipt(
    void Function(String conversationId, String messageId, String userId)
    handler,
  ) {
    _deliveryReceiptHandlers.remove(handler);
  }

  void onReadReceipt(
    void Function(String conversationId, String messageId, String userId)
    handler,
  ) {
    _readReceiptHandlers[handler] = (String conversationId) => conversationId;
  }

  void offReadReceipt(
    void Function(String conversationId, String messageId, String userId)
    handler,
  ) {
    _readReceiptHandlers.remove(handler);
  }

  // Presence methods for typing indicators
  void onPresence(
    void Function(String conversationId, bool isPresent, int? lastSeen) handler,
  ) {
    _presenceHandlers[handler] = (String conversationId) => conversationId;
  }

  void offPresence(
    void Function(String conversationId, bool isPresent, int? lastSeen) handler,
  ) {
    _presenceHandlers.remove(handler);
  }

  // Unread message methods
  void onUnread(void Function(Map<String, dynamic> payload) handler) {
    _unreadHandlers[handler] = (String conversationId) => conversationId;
  }

  void offUnread(void Function(Map<String, dynamic> payload) handler) {
    _unreadHandlers.remove(handler);
  }
}
