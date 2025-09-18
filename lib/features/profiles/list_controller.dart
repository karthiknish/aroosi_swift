import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'profiles_repository.dart';

class ProfilesListState {
  const ProfilesListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.loading = false,
    this.error,
    this.filters,
  });

  final List<ProfileSummary> items;
  final int page;
  final bool hasMore;
  final bool loading;
  final String? error;
  final SearchFilters? filters;

  ProfilesListState copyWith({
    List<ProfileSummary>? items,
    int? page,
    bool? hasMore,
    bool? loading,
    String? error,
    bool setError = false,
    SearchFilters? filters,
  }) => ProfilesListState(
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loading: loading ?? this.loading,
    error: setError ? error : this.error,
    filters: filters ?? this.filters,
  );
}

class MatchesController extends Notifier<ProfilesListState> {
  MatchesController() : _repo = ProfilesRepository();
  final ProfilesRepository _repo;

  @override
  ProfilesListState build() => const ProfilesListState();

  Future<void> refresh({String? sort}) async {
    state = state.copyWith(loading: true, setError: true, error: null, page: 1);
    try {
      final page = await _repo.getMatches(page: 1, pageSize: 20, sort: sort);
      state = state.copyWith(
        items: page.items,
        page: 1,
        hasMore: page.hasMore,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        setError: true,
        error: 'Failed to load matches',
      );
    }
  }

  Future<void> loadMore({String? sort}) async {
    if (!state.hasMore || state.loading) return;
    state = state.copyWith(loading: true);
    try {
      final next = state.page + 1;
      final page = await _repo.getMatches(page: next, pageSize: 20, sort: sort);
      state = state.copyWith(
        items: [...state.items, ...page.items],
        page: next,
        hasMore: page.hasMore,
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> toggleFavorite(String id) async {
    final ok = await _repo.toggleFavorite(id);
    if (ok) {
      final updated = state.items
          .map((e) => e.id == id ? e.copyWith(isFavorite: !e.isFavorite) : e)
          .toList();
      state = state.copyWith(items: updated);
    }
  }

  Future<void> toggleShortlist(String id) async {
    final ok = await _repo.toggleShortlist(id);
    if (ok) {
      final updated = state.items
          .map(
            (e) => e.id == id ? e.copyWith(isShortlisted: !e.isShortlisted) : e,
          )
          .toList();
      state = state.copyWith(items: updated);
    }
  }

  Future<bool> sendInterest(String id) async {
    try {
      final ok = await _repo.sendInterest(id);
      return ok;
    } catch (_) {
      return false;
    }
  }
}

class SearchController extends Notifier<ProfilesListState> {
  SearchController() : _repo = ProfilesRepository();
  final ProfilesRepository _repo;

  @override
  ProfilesListState build() => const ProfilesListState();

  Future<void> search(SearchFilters filters) async {
    state = state.copyWith(
      loading: true,
      setError: true,
      error: null,
      page: 1,
      filters: filters,
    );
    try {
      final page = await _repo.search(filters: filters, page: 1, pageSize: 20);
      state = state.copyWith(
        items: page.items,
        page: 1,
        hasMore: page.hasMore,
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        setError: true,
        error: 'Search failed',
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loading || state.filters == null) return;
    state = state.copyWith(loading: true);
    try {
      final next = state.page + 1;
      final page = await _repo.search(
        filters: state.filters!,
        page: next,
        pageSize: 20,
      );
      state = state.copyWith(
        items: [...state.items, ...page.items],
        page: next,
        hasMore: page.hasMore,
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  void clear() {
    state = const ProfilesListState(
      items: [],
      page: 1,
      hasMore: false,
      loading: false,
      error: null,
      filters: null,
    );
  }
}

class FavoritesController extends Notifier<ProfilesListState> {
  FavoritesController() : _repo = ProfilesRepository();
  final ProfilesRepository _repo;

  @override
  ProfilesListState build() => const ProfilesListState();

  Future<void> refresh() async {
    state = state.copyWith(loading: true, setError: true, error: null, page: 1);
    try {
      final page = await _repo.getFavorites(page: 1, pageSize: 20);
      state = state.copyWith(
        items: page.items,
        page: 1,
        hasMore: page.hasMore,
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        setError: true,
        error: 'Failed to load favorites',
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loading) return;
    state = state.copyWith(loading: true);
    try {
      final next = state.page + 1;
      final page = await _repo.getFavorites(page: next, pageSize: 20);
      state = state.copyWith(
        items: [...state.items, ...page.items],
        page: next,
        hasMore: page.hasMore,
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> toggleFavorite(String id) async {
    final ok = await _repo.toggleFavorite(id);
    if (ok) {
      final updated = state.items
          .map((e) => e.id == id ? e.copyWith(isFavorite: !e.isFavorite) : e)
          .toList();
      state = state.copyWith(items: updated);
    }
  }
}

class ShortlistController extends Notifier<ProfilesListState> {
  ShortlistController() : _repo = ProfilesRepository();
  final ProfilesRepository _repo;

  @override
  ProfilesListState build() => const ProfilesListState();

  Future<void> refresh() async {
    state = state.copyWith(loading: true, setError: true, error: null, page: 1);
    try {
      final page = await _repo.getShortlist(page: 1, pageSize: 20);
      state = state.copyWith(
        items: page.items,
        page: 1,
        hasMore: page.hasMore,
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        setError: true,
        error: 'Failed to load shortlist',
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loading) return;
    state = state.copyWith(loading: true);
    try {
      final next = state.page + 1;
      final page = await _repo.getShortlist(page: next, pageSize: 20);
      state = state.copyWith(
        items: [...state.items, ...page.items],
        page: next,
        hasMore: page.hasMore,
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> toggleShortlist(String id) async {
    final ok = await _repo.toggleShortlist(id);
    if (ok) {
      final updated = state.items
          .map(
            (e) => e.id == id ? e.copyWith(isShortlisted: !e.isShortlisted) : e,
          )
          .toList();
      state = state.copyWith(items: updated);
    }
  }
}

final matchesControllerProvider =
    NotifierProvider<MatchesController, ProfilesListState>(
      MatchesController.new,
    );
final searchControllerProvider =
    NotifierProvider<SearchController, ProfilesListState>(SearchController.new);
final favoritesControllerProvider =
    NotifierProvider<FavoritesController, ProfilesListState>(
      FavoritesController.new,
    );
final shortlistControllerProvider =
    NotifierProvider<ShortlistController, ProfilesListState>(
      ShortlistController.new,
    );

class InterestsState {
  const InterestsState({
    this.options = const <String>[],
    this.selected = const <String>{},
    this.loading = false,
    this.error,
  });

  final List<String> options;
  final Set<String> selected;
  final bool loading;
  final String? error;

  InterestsState copyWith({
    List<String>? options,
    Set<String>? selected,
    bool? loading,
    String? error,
    bool setError = false,
  }) => InterestsState(
    options: options ?? this.options,
    selected: selected ?? this.selected,
    loading: loading ?? this.loading,
    error: setError ? error : this.error,
  );
}

class InterestsController extends Notifier<InterestsState> {
  InterestsController() : _repo = ProfilesRepository();
  final ProfilesRepository _repo;

  @override
  InterestsState build() => const InterestsState();

  Future<void> load() async {
    state = state.copyWith(loading: true, setError: true, error: null);
    try {
      final options = await _repo.getInterestOptions();
      final selected = await _repo.getSelectedInterests();
      state = state.copyWith(
        options: options,
        selected: selected,
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        setError: true,
        error: 'Failed to load interests',
      );
    }
  }

  void toggle(String interest, bool value) {
    final s = Set<String>.from(state.selected);
    if (value) {
      s.add(interest);
    } else {
      s.remove(interest);
    }
    state = state.copyWith(selected: s);
  }

  Future<bool> save() async {
    try {
      final ok = await _repo.saveSelectedInterests(state.selected);
      return ok;
    } catch (_) {
      return false;
    }
  }
}

final interestsControllerProvider =
    NotifierProvider<InterestsController, InterestsState>(
      InterestsController.new,
    );
