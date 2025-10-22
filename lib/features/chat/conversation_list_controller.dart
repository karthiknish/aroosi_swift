import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_models.dart';
import 'chat_repository.dart';

class ConversationListState {
  const ConversationListState({
    this.items = const [],
    this.loading = false,
    this.error,
  });

  final List<ConversationSummary> items;
  final bool loading;
  final String? error;

  ConversationListState copyWith({
    List<ConversationSummary>? items,
    bool? loading,
    String? error,
    bool setError = false,
  }) => ConversationListState(
    items: items ?? this.items,
    loading: loading ?? this.loading,
    error: setError ? error : this.error,
  );
}

class ConversationListController extends Notifier<ConversationListState> {
  ConversationListController() : _repo = ChatRepository();
  final ChatRepository _repo;

  @override
  ConversationListState build() => const ConversationListState();

  Future<void> load() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, setError: true, error: null);
    try {
      var items = await _repo.getConversations();
      items = await _enrichAvatars(items);
      state = state.copyWith(loading: false, items: items);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        setError: true,
        error: 'Failed to load conversations',
      );
    }
  }

  Future<void> refresh() async {
    try {
      var items = await _repo.getConversations();
      items = await _enrichAvatars(items);
      state = state.copyWith(items: items);
    } catch (_) {}
  }

  Future<List<ConversationSummary>> _enrichAvatars(
    List<ConversationSummary> items,
  ) async {
    final missing = items
        .where(
          (c) =>
              (c.partnerAvatarUrl == null || c.partnerAvatarUrl!.isEmpty) &&
              (c.partnerId.isNotEmpty),
        )
        .toList();
    if (missing.isEmpty) return Future.value(items);
    final ids = missing.map((e) => e.partnerId).toSet().toList();
    try {
      final mapping = await _repo.getBatchProfileImages(ids);
      return items.map((c) {
        final url =
            (c.partnerAvatarUrl != null && c.partnerAvatarUrl!.isNotEmpty)
            ? c.partnerAvatarUrl
            : (mapping[c.partnerId]);
        if (url == null || url.isEmpty) return c;
        return ConversationSummary(
          id: c.id,
          partnerId: c.partnerId,
          partnerName: c.partnerName,
          partnerAvatarUrl: url,
          unreadCount: c.unreadCount,
          lastMessageText: c.lastMessageText,
          lastMessageAt: c.lastMessageAt,
        );
      }).toList();
    } catch (_) {
      return items;
    }
  }

  Future<String> createConversationWith(String userId) async {
    final id = await _repo.createConversation(participantIds: [userId]);
    await refresh();
    return id;
  }
}

final conversationListControllerProvider =
    NotifierProvider<ConversationListController, ConversationListState>(
      ConversationListController.new,
    );
