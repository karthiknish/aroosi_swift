import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/features/profiles/profiles_repository.dart';

class ProfileDetailState {
  const ProfileDetailState({this.data, this.loading = false, this.error});

  final Map<String, dynamic>? data;
  final bool loading;
  final String? error;

  ProfileDetailState copyWith({
    Map<String, dynamic>? data,
    bool? loading,
    String? error,
    bool setError = false,
  }) => ProfileDetailState(
        data: data ?? this.data,
        loading: loading ?? this.loading,
        error: setError ? error : this.error,
      );
}

class ProfileDetailController extends Notifier<ProfileDetailState> {
  ProfileDetailController() : _repo = ProfilesRepository();
  final ProfilesRepository _repo;

  @override
  ProfileDetailState build() => const ProfileDetailState();

  Future<void> load(String id) async {
    state = state.copyWith(loading: true, setError: true, error: null);
    try {
      final data = await _repo.getProfileById(id);
      if (data == null) {
        state = state.copyWith(loading: false, setError: true, error: 'Profile not found');
        return;
      }
      state = state.copyWith(data: data, loading: false);
    } catch (_) {
      state = state.copyWith(loading: false, setError: true, error: 'Failed to load profile');
    }
  }

  Future<void> toggleFavorite(String id) async {
    final ok = await _repo.toggleFavorite(id);
    if (!ok) return;
    final m = Map<String, dynamic>.from(state.data ?? {});
    final curr = (m['isFavorite'] == true) || (m['favorite'] == true);
    m['isFavorite'] = !curr;
    state = state.copyWith(data: m);
  }

  Future<void> toggleShortlist(String id) async {
    final ok = await _repo.toggleShortlist(id);
    if (!ok) return;
    final m = Map<String, dynamic>.from(state.data ?? {});
    final curr = (m['isShortlisted'] == true) || (m['shortlisted'] == true);
    m['isShortlisted'] = !curr;
    state = state.copyWith(data: m);
  }
}

final profileDetailControllerProvider =
    NotifierProvider<ProfileDetailController, ProfileDetailState>(ProfileDetailController.new);
