import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'safety_repository.dart';

class SafetyState {
  const SafetyState({
    this.blockedUsers = const [],
    this.loading = false,
    this.error,
  });

  final List<Map<String, dynamic>> blockedUsers;
  final bool loading;
  final String? error;

  SafetyState copyWith({
    List<Map<String, dynamic>>? blockedUsers,
    bool? loading,
    String? error,
    bool setError = false,
  }) => SafetyState(
    blockedUsers: blockedUsers ?? this.blockedUsers,
    loading: loading ?? this.loading,
    error: setError ? error : this.error,
  );
}

class SafetyController extends Notifier<SafetyState> {
  SafetyController() : _repo = SafetyRepository();
  final SafetyRepository _repo;

  @override
  SafetyState build() => const SafetyState();

  Future<void> refreshBlocked() async {
    state = state.copyWith(loading: true, setError: true, error: null);
    try {
      final users = await _repo.getBlockedUsers();
      state = state.copyWith(blockedUsers: users, loading: false);
    } catch (_) {
      state = state.copyWith(
        loading: false,
        setError: true,
        error: 'Failed to load blocked users',
      );
    }
  }

  Future<bool> isBlocked(String userId) => _repo.isBlocked(userId);

  Future<bool> block(String userId) async {
    final ok = await _repo.blockUser(userId);
    if (ok) await refreshBlocked();
    return ok;
  }

  Future<bool> unblock(String userId) async {
    final ok = await _repo.unblockUser(userId);
    if (ok) await refreshBlocked();
    return ok;
  }

  Future<bool> report(
    String userId, {
    required String reason,
    String? details,
  }) => _repo.reportUser(userId: userId, reason: reason, details: details);
}

final safetyControllerProvider =
    NotifierProvider<SafetyController, SafetyState>(SafetyController.new);
