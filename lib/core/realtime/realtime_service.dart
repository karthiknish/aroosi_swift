import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:aroosi_flutter/core/env.dart';

/// Realtime service using socket.io compatible transport.
/// Aligns with aroosi-mobile patterns (rooms per conversation, presence, typing).
class RealTimeService {
  RealTimeService._();
  static final RealTimeService instance = RealTimeService._();

  IO.Socket? _socket;
  final _connectedCtrl = StreamController<bool>.broadcast();
  final Map<void Function(String, bool), void Function(dynamic)>
  _typingHandlers = {};
  final Map<void Function(String, bool, int?), void Function(dynamic)>
  _presenceHandlers = {};
  final Map<void Function(String, Map<String, dynamic>), void Function(dynamic)>
  _messageHandlers = {};
  final Map<void Function(Map<String, dynamic>), void Function(dynamic)>
  _unreadHandlers = {};

  // Optional auth headers supplier for socket connection
  Map<String, dynamic> Function()? _authSupplier;

  Stream<bool> get connectedStream => _connectedCtrl.stream;
  bool get isConnected => _socket?.connected == true;

  String get _origin {
    // Strip trailing /api from Env.apiBaseUrl to get socket origin
    final base = Env.apiBaseUrl;
    if (base.endsWith('/api')) return base.substring(0, base.length - 4);
    return base;
  }

  void configureAuth(Map<String, dynamic> Function()? supplier) {
    _authSupplier = supplier;
  }

  void connect({Map<String, dynamic>? auth}) {
    if (_socket != null && _socket!.connected) return;
    final url = '$_origin/';
    final authMap =
        auth ??
        (_authSupplier != null ? _authSupplier!() : <String, dynamic>{});
    final opts = IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableForceNew()
        .enableReconnection()
        .setReconnectionAttempts(20)
        .setReconnectionDelay(1000)
        .setAuth(Map<dynamic, dynamic>.from(authMap))
        .build();
    _socket = IO.io(url, opts);
    _socket!.on('connect', (_) => _connectedCtrl.add(true));
    _socket!.on('disconnect', (_) => _connectedCtrl.add(false));
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _connectedCtrl.add(false);
  }

  // Rooms
  void joinConversation(String conversationId) {
    _socket?.emit('conversation:join', {'conversationId': conversationId});
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('conversation:leave', {'conversationId': conversationId});
  }

  // Typing
  void sendTyping(String conversationId, {required bool isTyping}) {
    _socket?.emit('typing', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  void onTyping(void Function(String conversationId, bool isTyping) handler) {
    final fn = (dynamic data) {
      try {
        final conv = data['conversationId']?.toString() ?? '';
        final v = data['isTyping'] == true;
        if (conv.isNotEmpty) handler(conv, v);
      } catch (_) {}
    };
    _typingHandlers[handler] = fn;
    _socket?.on('typing', fn);
    _socket?.on('user:typing', fn);
  }

  void offTyping(void Function(String conversationId, bool isTyping) handler) {
    final fn = _typingHandlers.remove(handler);
    if (fn != null) {
      _socket?.off('typing', fn);
      _socket?.off('user:typing', fn);
    }
  }

  // Presence
  void onPresence(
    void Function(String userId, bool isOnline, int? lastSeen) handler,
  ) {
    // Support a couple of event names
    void process(dynamic data) {
      try {
        final uid = data['userId']?.toString() ?? data['id']?.toString() ?? '';
        final online = data['isOnline'] == true || data['online'] == true;
        final lastSeen = data['lastSeen'] is int
            ? data['lastSeen'] as int
            : null;
        if (uid.isNotEmpty) handler(uid, online, lastSeen);
      } catch (_) {}
    }

    _presenceHandlers[handler] = process;
    _socket?.on('presence', process);
    _socket?.on('user:presence', process);
  }

  void offPresence(
    void Function(String userId, bool isOnline, int? lastSeen) handler,
  ) {
    final fn = _presenceHandlers.remove(handler);
    if (fn != null) {
      _socket?.off('presence', fn);
      _socket?.off('user:presence', fn);
    }
  }

  // Incoming messages
  void onMessage(
    void Function(String conversationId, Map<String, dynamic> message) handler,
  ) {
    void process(dynamic data) {
      try {
        final map = data is Map
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{};
        final conv =
            map['conversationId']?.toString() ??
            map['convId']?.toString() ??
            '';
        if (conv.isNotEmpty) handler(conv, map);
      } catch (_) {}
    }

    _messageHandlers[handler] = process;
    _socket?.on('message:new', process);
    _socket?.on('message', process);
    _socket?.on('chat:message', process);
    _socket?.on('messages:new', process);
  }

  void offMessage(
    void Function(String conversationId, Map<String, dynamic> message) handler,
  ) {
    final fn = _messageHandlers.remove(handler);
    if (fn != null) {
      _socket?.off('message:new', fn);
      _socket?.off('message', fn);
      _socket?.off('chat:message', fn);
      _socket?.off('messages:new', fn);
    }
  }

  // Unread updates
  void onUnread(void Function(Map<String, dynamic> payload) handler) {
    void process(dynamic data) {
      try {
        final map = data is Map
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{};
        handler(map);
      } catch (_) {}
    }

    _unreadHandlers[handler] = process;
    _socket?.on('unread:update', process);
    _socket?.on('conversations:unread', process);
  }

  void offUnread(void Function(Map<String, dynamic> payload) handler) {
    final fn = _unreadHandlers.remove(handler);
    if (fn != null) {
      _socket?.off('unread:update', fn);
      _socket?.off('conversations:unread', fn);
    }
  }
}
