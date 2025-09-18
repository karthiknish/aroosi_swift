import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/core/realtime/realtime_service.dart';
import 'package:aroosi_flutter/features/chat/chat_repository.dart';

class UnreadCountsState {
  const UnreadCountsState({this.counts = const {}});
  final Map<String, dynamic>
  counts; // e.g., { total: 3, conversations: { id: n } }

  UnreadCountsState copyWith({Map<String, dynamic>? counts}) =>
      UnreadCountsState(counts: counts ?? this.counts);
}

class UnreadCountsController extends Notifier<UnreadCountsState> {
  final _repo = ChatRepository();
  void Function(Map<String, dynamic>)? _handler;

  @override
  UnreadCountsState build() {
    // Subscribe to realtime updates
    final rt = RealTimeService.instance;
    _handler = (payload) {
      state = state.copyWith(counts: payload);
    };
    rt.onUnread(_handler!);
    ref.onDispose(() {
      if (_handler != null) rt.offUnread(_handler!);
    });
    // Initial fetch fallback
    refresh();
    return const UnreadCountsState();
  }

  Future<void> refresh() async {
    try {
      final map = await _repo.getUnreadCounts();
      state = state.copyWith(counts: map);
    } catch (_) {}
  }
}

final unreadCountsProvider =
    NotifierProvider<UnreadCountsController, UnreadCountsState>(
      UnreadCountsController.new,
    );
