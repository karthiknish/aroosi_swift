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

  Future<bool> isBlocked(String userId) async {
    final result = await _repo.isBlocked(userId);
    return result['isBlocked'] == true;
  }

  Future<bool> block(String userId) async {
    final result = await _repo.blockUser(userId);
    final success = result['success'] == true;
    if (success) await refreshBlocked();
    return success;
  }

  Future<bool> unblock(String userId) async {
    final result = await _repo.unblockUser(userId);
    final success = result['success'] == true;
    if (success) await refreshBlocked();
    return success;
  }

  Future<bool> report(
    String userId, {
    required String reason,
    String? details,
  }) async {
    final result = await _repo.reportUser(userId: userId, reason: reason, details: details);
    return result['success'] == true;
  }
}

final safetyControllerProvider =
    NotifierProvider<SafetyController, SafetyState>(SafetyController.new);
