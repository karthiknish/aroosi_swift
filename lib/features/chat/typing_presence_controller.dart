import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/core/realtime/realtime_service.dart';
import 'package:aroosi_flutter/features/chat/chat_repository.dart';

class TypingPresenceState {
  const TypingPresenceState({
    this.conversationId,
    this.peerUserId,
    this.isTyping = false,
    this.isOnline = false,
    this.lastSeen,
  });
  final String? conversationId;
  final String? peerUserId;
  final bool isTyping;
  final bool isOnline;
  final int? lastSeen; // epoch millis

  TypingPresenceState copyWith({
    String? conversationId,
    String? peerUserId,
    bool? isTyping,
    bool? isOnline,
    int? lastSeen,
    bool clearLastSeen = false,
  }) => TypingPresenceState(
    conversationId: conversationId ?? this.conversationId,
    peerUserId: peerUserId ?? this.peerUserId,
    isTyping: isTyping ?? this.isTyping,
    isOnline: isOnline ?? this.isOnline,
    lastSeen: clearLastSeen ? null : (lastSeen ?? this.lastSeen),
  );
}

class TypingPresenceController extends Notifier<TypingPresenceState> {
  final _rt = RealTimeService.instance;
  final _repo = ChatRepository();
  Timer? _typingDebounce;
  void Function(String, bool)? _typingHandlerRef;
  void Function(String, bool, int?)? _presenceHandlerRef;

  @override
  TypingPresenceState build() {
    ref.onDispose(() {
      final convId = state.conversationId;
      if (convId != null) {
        _rt.leaveConversation(convId);
      }
      if (_typingHandlerRef != null) _rt.offTyping(_typingHandlerRef!);
      if (_presenceHandlerRef != null) _rt.offPresence(_presenceHandlerRef!);
      _typingDebounce?.cancel();
    });
    return const TypingPresenceState();
  }

  void setConversation(String conversationId, {String? peerUserId}) {
    // If same conv, skip rewire
    if (state.conversationId == conversationId) return;
    // Cleanup previous
    final prev = state.conversationId;
    if (prev != null) {
      _rt.leaveConversation(prev);
      if (_typingHandlerRef != null) _rt.offTyping(_typingHandlerRef!);
      if (_presenceHandlerRef != null) _rt.offPresence(_presenceHandlerRef!);
    }
    // Connect and join
    if (!_rt.isConnected) _rt.connect();
    _rt.joinConversation(conversationId);
    state = state.copyWith(
      conversationId: conversationId,
      peerUserId: peerUserId ?? state.peerUserId,
    );
    // Register listeners
    _typingHandlerRef = (convId, isTyping) {
      if (convId == conversationId) {
        state = state.copyWith(isTyping: isTyping);
      }
    };
    _presenceHandlerRef = (_, isOnline, lastSeen) {
      state = state.copyWith(isOnline: isOnline, lastSeen: lastSeen);
    };
    _rt.onTyping(_typingHandlerRef!);
    _rt.onPresence(_presenceHandlerRef!);
    // Initial presence
    refreshPresence();
  }

  Future<void> refreshPresence() async {
    final userId = state.peerUserId;
    if (userId == null || userId.isEmpty) return;
    try {
      final p = await _repo.getPresence(userId);
      state = state.copyWith(
        isOnline: p['isOnline'] == true,
        lastSeen: p['lastSeen'] is int ? p['lastSeen'] as int : null,
      );
    } catch (_) {}
  }

  void setMyTyping(bool typing) {
    final convId = state.conversationId;
    if (convId == null) return;
    _typingDebounce?.cancel();
    if (typing) {
      _rt.sendTyping(convId, isTyping: true);
      _typingDebounce = Timer(const Duration(seconds: 2), () {
        _rt.sendTyping(convId, isTyping: false);
      });
    } else {
      _rt.sendTyping(convId, isTyping: false);
    }
  }
}

final typingPresenceControllerProvider =
    NotifierProvider<TypingPresenceController, TypingPresenceState>(
      TypingPresenceController.new,
    );
