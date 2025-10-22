import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';

import 'chat_models.dart';
import 'chat_repository.dart';
import 'delivery_receipt_service.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.loading = false,
    this.error,
    this.hasMore = true,
    this.sending = false,
    this.deliveryReceipts = const [],
  });

  final List<ChatMessage> messages;
  final bool loading;
  final String? error;
  final bool hasMore;
  final bool sending;
  final List<DeliveryReceipt> deliveryReceipts;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? loading,
    String? error,
    bool setError = false,
    bool? hasMore,
    bool? sending,
    List<DeliveryReceipt>? deliveryReceipts,
  }) => ChatState(
    messages: messages ?? this.messages,
    loading: loading ?? this.loading,
    error: setError ? error : this.error,
    hasMore: hasMore ?? this.hasMore,
    sending: sending ?? this.sending,
    deliveryReceipts: deliveryReceipts ?? this.deliveryReceipts,
  );
}

class ChatController extends Notifier<ChatState> {
  ChatController() : _repo = ChatRepository();
  final ChatRepository _repo;
  final DeliveryReceiptService _deliveryService = DeliveryReceiptService();

  String? _convId;

  @override
  ChatState build() => const ChatState();

  void setConversation(String conversationId) {
    if (_convId == conversationId) return;
    _convId = conversationId;
    state = const ChatState();
  }

  void setPeerUserId(String? userId) {
    // Currently unused in repository calls, but reserved for future features
    // like prefetching presence or conversation metadata.
  }

  Future<void> loadInitial({String? currentUserId}) async {
    final conv = _convId;
    if (conv == null || state.loading) return;
    state = state.copyWith(loading: true, setError: true, error: null);
    try {
      final msgs = await _repo.getMessages(conversationId: conv, limit: 20);
      state = state.copyWith(
        loading: false,
        messages: msgs,
        hasMore: msgs.length >= 20,
      );
      // best-effort mark as read
      await _repo.markAsRead(conv);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        setError: true,
        error: 'Failed to load messages',
      );
    }
  }

  Future<void> loadMore() async {
    final conv = _convId;
    if (conv == null || state.loading || !state.hasMore) return;
    state = state.copyWith(loading: true);
    try {
      final before = state.messages.isNotEmpty
          ? state.messages.first.createdAt.millisecondsSinceEpoch
          : null;
      final more = await _repo.getMessages(
        conversationId: conv,
        before: before,
        limit: 20,
      );
      state = state.copyWith(
        loading: false,
        messages: [...more, ...state.messages],
        hasMore: more.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> refresh() async {
    final conv = _convId;
    if (conv == null) return;
    try {
      final msgs = await _repo.getMessages(conversationId: conv, limit: 20);
      state = state.copyWith(messages: msgs, hasMore: msgs.length >= 20);
      await _repo.markAsRead(conv);
    } catch (_) {}
  }

  Future<void> send(String text, {String? toUserId}) async {
    final conv = _convId;
    if (conv == null || state.sending || text.trim().isEmpty) return;
    state = state.copyWith(sending: true);
    try {
      final sent = await _repo.sendMessage(
        conversationId: conv,
        text: text.trim(),
        toUserId: toUserId,
      );
      state = state.copyWith(
        messages: [...state.messages, sent],
        sending: false,
      );
    } catch (e) {
      state = state.copyWith(sending: false);
      rethrow;
    }
  }

  Future<void> sendImage(
    List<int> bytes, {
    String filename = 'image.jpg',
    String contentType = 'image/jpeg',
    String? toUserId,
  }) async {
    final conv = _convId;
    if (conv == null || state.sending) return;
    state = state.copyWith(sending: true);
    try {
      final sent = await _repo.uploadImageMessageMultipart(
        conversationId: conv,
        bytes: bytes,
        filename: filename,
        contentType: contentType,
        toUserId: toUserId,
      );
      state = state.copyWith(
        messages: [...state.messages, sent],
        sending: false,
      );
    } catch (_) {
      state = state.copyWith(sending: false);
      rethrow;
    }
  }

  Future<void> reactToMessage({
    required String messageId,
    required String emoji,
  }) async {
    final conv = _convId;
    if (conv == null) return;
    try {
      await _repo.addReaction(
        conversationId: conv,
        messageId: messageId,
        emoji: emoji,
      );
      // Optimistic: update local state
      final updated = state.messages.map((m) {
        if (m.id != messageId) return m;
        final map = Map<String, List<String>>.from(m.reactions);
        final me = ref.read(authControllerProvider).profile?.id ?? 'me';
        final list = List<String>.from(map[emoji] ?? <String>[]);
        if (!list.contains(me)) list.add(me);
        map[emoji] = list;
        return m.copyWith(reactions: map);
      }).toList();
      state = state.copyWith(messages: updated);
    } catch (_) {}
  }

  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    final conv = _convId;
    if (conv == null) return;
    try {
      await _repo.removeReaction(
        conversationId: conv,
        messageId: messageId,
        emoji: emoji,
      );
      final updated = state.messages.map((m) {
        if (m.id != messageId) return m;
        final map = Map<String, List<String>>.from(m.reactions);
        final me = ref.read(authControllerProvider).profile?.id ?? 'me';
        final list = List<String>.from(map[emoji] ?? <String>[]);
        list.remove(me);
        if (list.isEmpty) {
          map.remove(emoji);
        } else {
          map[emoji] = list;
        }
        return m.copyWith(reactions: map);
      }).toList();
      state = state.copyWith(messages: updated);
    } catch (_) {}
  }

  Future<void> deleteMessage(String messageId) async {
    final conv = _convId;
    if (conv == null) return;
    try {
      await _repo.deleteMessage(conversationId: conv, messageId: messageId);
      final updated = state.messages.where((m) => m.id != messageId).toList();
      state = state.copyWith(messages: updated);
    } catch (_) {}
  }

  // Called by realtime layer to append a new message
  void appendIncoming(ChatMessage message) {
    if (_convId == null || message.conversationId != _convId) return;
    state = state.copyWith(messages: [...state.messages, message]);
  }

  Future<void> loadDeliveryReceipts() async {
    final conv = _convId;
    if (conv == null) return;
    try {
      final receipts = await _deliveryService.getDeliveryReceipts(conv);
      state = state.copyWith(deliveryReceipts: receipts);
    } catch (e) {
      // Fail silently for delivery receipts
    }
  }

  Future<void> markMessageRead(String messageId) async {
    try {
      await _deliveryService.recordDeliveryReceipt(messageId, DeliveryStatus.read);
      await loadDeliveryReceipts(); // Refresh receipts
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> markMessageDelivered(String messageId) async {
    try {
      await _deliveryService.recordDeliveryReceipt(messageId, DeliveryStatus.delivered);
      await loadDeliveryReceipts(); // Refresh receipts
    } catch (e) {
      // Fail silently
    }
  }

  DeliveryReceipt? getDeliveryReceiptForMessage(String messageId) {
    try {
      return state.deliveryReceipts.firstWhere(
        (receipt) => receipt.messageId == messageId,
      );
    } catch (e) {
      return null;
    }
  }
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);
