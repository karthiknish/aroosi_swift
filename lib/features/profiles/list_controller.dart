import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'profiles_repository.dart';
import 'package:aroosi_flutter/utils/debug_logger.dart';

class ShortlistState {
  const ShortlistState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.loading = false,
    this.error,
  });

  final List<ShortlistEntry> items;
  final int page;
  final bool hasMore;
  final bool loading;
  final String? error;

  ShortlistState copyWith({
    List<ShortlistEntry>? items,
    int? page,
    bool? hasMore,
    bool? loading,
    String? error,
    bool setError = false,
  }) => ShortlistState(
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loading: loading ?? this.loading,
    error: setError ? error : this.error,
  );
}

class ProfilesListState {
  const ProfilesListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.loading = false,
    this.error,
    this.filters,
    this.nextPage,
    this.nextCursor,
  });

  final List<ProfileSummary> items;
  final int page;
  final bool hasMore;
  final bool loading;
  final String? error;
  final SearchFilters? filters;
  final int? nextPage;
  final String? nextCursor;

  ProfilesListState copyWith({
    List<ProfileSummary>? items,
    int? page,
    bool? hasMore,
    bool? loading,
    String? error,
    bool setError = false,
    SearchFilters? filters,
    Object? nextPage = _sentinel,
    Object? nextCursor = _sentinel,
  }) => ProfilesListState(
        items: items ?? this.items,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        loading: loading ?? this.loading,
        error: setError ? error : this.error,
        filters: filters ?? this.filters,
        nextPage: nextPage == _sentinel ? this.nextPage : nextPage as int?,
        nextCursor:
            nextCursor == _sentinel ? this.nextCursor : nextCursor as String?,
      );
}

const Object _sentinel = Object();

class MatchesState {
  const MatchesState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.loading = false,
    this.error,
    this.unreadCounts = const {},
  });

  final List<MatchEntry> items;
  final int page;
  final bool hasMore;
  final bool loading;
  final String? error;
  final Map<String, int> unreadCounts; // conversationId -> count

  MatchesState copyWith({
    List<MatchEntry>? items,
    int? page,
    bool? hasMore,
    bool? loading,
    String? error,
    bool setError = false,
    Map<String, int>? unreadCounts,
  }) => MatchesState(
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loading: loading ?? this.loading,
    error: setError ? error : this.error,
    unreadCounts: unreadCounts ?? this.unreadCounts,
  );
}

class MatchesController extends Notifier<MatchesState> {
  MatchesController() : _repo = ProfilesRepository();
  final ProfilesRepository _repo;

  @override
  MatchesState build() => const MatchesState();

  Future<void> refresh() async {
    state = state.copyWith(loading: true, setError: true, error: null, page: 1);
    try {
      final page = await _repo.getMatches(page: 1, pageSize: 20);
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

  Future<void> loadMore() async {
    if (!state.hasMore || state.loading) return;
    state = state.copyWith(loading: true);
    try {
      final next = state.page + 1;
      final page = await _repo.getMatches(page: next, pageSize: 20);
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

  Future<Map<String, dynamic>> sendInterest(String userId) async {
    try {
      final result = await _repo.manageInterest(action: 'send', toUserId: userId);
      
      if (result['success'] == true) {
        return {
          'success': true,
          'error': null,
          'isPlanLimit': false,
        };
      } else {
        final error = result['error'] as String? ?? 'Failed to send interest';
        final isPlanLimit = result['isPlanLimit'] == true;
        
        return {
          'success': false,
          'error': error,
          'isPlanLimit': isPlanLimit,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'isPlanLimit': false,
      };
    }
  }

  Future<void> loadUnreadCounts() async {
    try {
      final counts = await _repo.getUnreadMessageCounts();
      // Update the state with new unread counts
      final updatedItems = state.items.map((match) {
        final unreadCount = counts[match.conversationId] ?? 0;
        return match.copyWith(unreadCount: unreadCount);
      }).toList();
      
      state = state.copyWith(items: updatedItems);
    } catch (_) {
      // Silently fail for unread counts
    }
  }

  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await _repo.markConversationAsRead(conversationId);
      // Update the local state
      final updatedItems = state.items.map((match) {
        if (match.conversationId == conversationId) {
          return match.copyWith(unreadCount: 0);
        }
        return match;
      }).toList();
      
      state = state.copyWith(items: updatedItems);
    } catch (_) {
      // Silently fail for marking as read
    }
  }

  Future<bool> isUserBlocked(String userId) async {
    return await _repo.isUserBlocked(userId);
  }

  Future<Map<String, dynamic>> blockUser(String userId) async {
    return await _repo.blockUser(userId);
  }

  Future<Map<String, dynamic>> unblockUser(String userId) async {
    return await _repo.unblockUser(userId);
  }
}

class SearchController extends Notifier<ProfilesListState> {
  SearchController() : _repo = ProfilesRepository();
  final ProfilesRepository _repo;

  @override
  ProfilesListState build() => const ProfilesListState();

  Future<void> search(SearchFilters filters) async {
    logDebug('SearchController: Starting search', data: {
      'filters': filters.toQuery(),
      'currentState': {
        'itemsCount': state.items.length,
        'loading': state.loading,
        'hasMore': state.hasMore,
        'error': state.error,
      }
    });
    
    state = state.copyWith(
      loading: true,
      setError: true,
      error: null,
      page: 1,
      filters: filters,
      nextPage: null,
      nextCursor: null,
    );
    
    try {
      final page = await _repo.search(
        filters: filters,
        page: 1,
        pageSize: filters.pageSize ?? 20,
      );
      
      logDebug('SearchController: Search completed successfully', data: {
        'returnedItems': page.items.length,
        'page': page.page,
        'hasMore': page.hasMore,
        'nextPage': page.nextPage,
        'nextCursor': page.nextCursor,
        'total': page.total,
      });
      
      state = state.copyWith(
        items: page.items,
        page: page.page,
        hasMore: page.hasMore,
        loading: false,
        nextPage: page.nextPage,
        nextCursor: page.nextCursor,
      );
    } catch (e, stackTrace) {
      logDebug('SearchController: Search failed', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        loading: false,
        setError: true,
        error: 'Search failed',
        nextPage: null,
        nextCursor: null,
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loading || state.filters == null) {
      logDebug('SearchController: Load more skipped', data: {
        'hasMore': state.hasMore,
        'loading': state.loading,
        'hasFilters': state.filters != null,
      });
      return;
    }
    
    logDebug('SearchController: Starting load more', data: {
      'currentPage': state.page,
      'currentItems': state.items.length,
      'nextCursor': state.nextCursor,
      'nextPage': state.nextPage,
    });
    
    state = state.copyWith(loading: true);
    try {
      final filters = state.filters!;
      final nextCursor = state.nextCursor;
      final nextPage = state.nextPage ?? (state.page + 1);
      final page = await _repo.search(
        filters: filters.copyWith(cursor: nextCursor),
        page: nextPage,
        pageSize: filters.pageSize ?? 20,
      );
      
      logDebug('SearchController: Load more completed', data: {
        'newItems': page.items.length,
        'totalItems': state.items.length + page.items.length,
        'page': page.page,
        'hasMore': page.hasMore,
        'nextPage': page.nextPage,
        'nextCursor': page.nextCursor,
      });
      
      state = state.copyWith(
        items: [...state.items, ...page.items],
        page: page.page,
        hasMore: page.hasMore,
        loading: false,
        nextPage: page.nextPage,
        nextCursor: page.nextCursor,
        filters: filters.copyWith(cursor: page.nextCursor),
      );
    } catch (e, stackTrace) {
      logDebug('SearchController: Load more failed', error: e, stackTrace: stackTrace);
      state = state.copyWith(loading: false);
    }
  }

  void clear() {
    logDebug('SearchController: Clearing search state', data: {
      'previousItems': state.items.length,
      'previousPage': state.page,
      'hadFilters': state.filters != null,
    });
    
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

class ShortlistController extends Notifier<ShortlistState> {
  ShortlistController() : _repo = ProfilesRepository();
  final ProfilesRepository _repo;

  @override
  ShortlistState build() => const ShortlistState();

  Future<void> refresh() async {
    state = state.copyWith(loading: true, setError: true, error: null, page: 1);
    try {
      final page = await _repo.getShortlistEntries(page: 1, pageSize: 20);
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
      final page = await _repo.getShortlistEntries(page: next, pageSize: 20);
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

  Future<Map<String, dynamic>> toggleShortlist(String userId) async {
    try {
      final result = await _repo.toggleShortlistEntry(userId);
      
      if (result['success'] == true) {
        // Check if the entry was removed (based on API response)
        final data = result['data'] as Map<String, dynamic>? ?? {};
        final action = data['action'] as String? ?? 'added';
        
        if (action == 'removed' || data['removed'] == true) {
          // Remove from local state
          final updated = state.items.where((e) => e.userId != userId).toList();
          state = state.copyWith(items: updated);
        }
        // If added, the item will appear on next refresh
        
        return {
          'success': true,
          'action': action,
          'error': null,
        };
      } else {
        // Check for plan limit error
        final error = result['error'] as String? ?? 'Failed to toggle shortlist';
        final isPlanLimit = error.toLowerCase().contains('plan') || 
                           error.toLowerCase().contains('limit') ||
                           error.toLowerCase().contains('subscription') ||
                           error.toLowerCase().contains('upgrade');
        
        return {
          'success': false,
          'action': 'error',
          'error': error,
          'isPlanLimit': isPlanLimit,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'action': 'error',
        'error': e.toString(),
        'isPlanLimit': false,
      };
    }
  }

  Future<String?> fetchNote(String userId) async {
    try {
      final noteData = await _repo.fetchNote(userId);
      return noteData?['note'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> setNote(String userId, String note) async {
    try {
      final success = await _repo.setNote(userId, note);
      if (success) {
        // Update the note in local state
        final updated = state.items.map((e) {
          if (e.userId == userId) {
            return e.copyWith(note: note.isEmpty ? null : note);
          }
          return e;
        }).toList();
        state = state.copyWith(items: updated);
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadNotesForEntries(List<String> userIds) async {
    for (final userId in userIds) {
      final note = await fetchNote(userId);
      if (note != null) {
        final updated = state.items.map((e) {
          if (e.userId == userId) {
            return e.copyWith(note: note);
          }
          return e;
        }).toList();
        state = state.copyWith(items: updated);
      }
    }
  }
}


final searchControllerProvider =
    NotifierProvider<SearchController, ProfilesListState>(SearchController.new);
final favoritesControllerProvider =
    NotifierProvider<FavoritesController, ProfilesListState>(
      FavoritesController.new,
    );
final shortlistControllerProvider =
    NotifierProvider<ShortlistController, ShortlistState>(
      ShortlistController.new,
    );

class UserInterestsState {
  const UserInterestsState({
    this.options = const <String>[],
    this.selected = const <String>{},
    this.loading = false,
    this.error,
  });

  final List<String> options;
  final Set<String> selected;
  final bool loading;
  final String? error;

  UserInterestsState copyWith({
    List<String>? options,
    Set<String>? selected,
    bool? loading,
    String? error,
    bool setError = false,
  }) => UserInterestsState(
    options: options ?? this.options,
    selected: selected ?? this.selected,
    loading: loading ?? this.loading,
    error: setError ? error : this.error,
  );
}

class InterestsState {
  const InterestsState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.loading = false,
    this.error,
    this.currentMode = 'sent',
  });

  final List<InterestEntry> items;
  final int page;
  final bool hasMore;
  final bool loading;
  final String? error;
  final String currentMode; // 'sent', 'received', 'mutual'

  InterestsState copyWith({
    List<InterestEntry>? items,
    int? page,
    bool? hasMore,
    bool? loading,
    String? error,
    bool setError = false,
    String? currentMode,
  }) => InterestsState(
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loading: loading ?? this.loading,
    error: setError ? error : this.error,
    currentMode: currentMode ?? this.currentMode,
  );
}

class UserInterestsController extends Notifier<UserInterestsState> {
  UserInterestsController() : _repo = ProfilesRepository();
  final ProfilesRepository _repo;

  @override
  UserInterestsState build() => const UserInterestsState();

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

class InterestsController extends Notifier<InterestsState> {
  InterestsController() : _repo = ProfilesRepository();
  final ProfilesRepository _repo;

  @override
  InterestsState build() => const InterestsState();

  Future<void> load({String mode = 'sent'}) async {
    state = state.copyWith(
      loading: true, 
      setError: true, 
      error: null, 
      page: 1,
      currentMode: mode,
    );
    try {
      final page = await _repo.getInterests(mode: mode, page: 1, pageSize: 20);
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
        error: 'Failed to load interests',
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loading) return;
    state = state.copyWith(loading: true);
    try {
      final next = state.page + 1;
      final page = await _repo.getInterests(
        mode: state.currentMode, 
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

  Future<Map<String, dynamic>> respondToInterest({
    required String interestId,
    required String status, // 'accepted', 'rejected'
  }) async {
    try {
      final result = await _repo.manageInterest(
        action: 'respond',
        interestId: interestId,
        status: status,
      );
      
      if (result['success'] == true) {
        // Update the interest status in local state
        final updated = state.items.map((e) {
          if (e.id == interestId) {
            return e.copyWith(status: status);
          }
          return e;
        }).toList();
        
        state = state.copyWith(items: updated);
        
        return {
          'success': true,
          'error': null,
          'isPlanLimit': false,
        };
      } else {
        final error = result['error'] as String? ?? 'Failed to respond to interest';
        final isPlanLimit = result['isPlanLimit'] == true;
        
        return {
          'success': false,
          'error': error,
          'isPlanLimit': isPlanLimit,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'isPlanLimit': false,
      };
    }
  }

  Future<Map<String, dynamic>?> checkInterestStatus({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      return await _repo.checkInterestStatus(
        fromUserId: fromUserId,
        toUserId: toUserId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshInterestStatus(String interestId) async {
    try {
      // This would call a real-time endpoint or WebSocket to get the latest status
      // For now, we'll reload the current mode to get updated data
      await load(mode: state.currentMode);
    } catch (_) {
      // Silently fail for refresh
    }
  }

  Future<void> onInterestStatusChanged({
    required String interestId,
    required String newStatus,
  }) async {
    // Update the local state immediately for real-time feel
    final updated = state.items.map((e) {
      if (e.id == interestId) {
        return e.copyWith(status: newStatus);
      }
      return e;
    }).toList();
    
    state = state.copyWith(items: updated);
    
    // Optionally sync with server
    try {
      await refreshInterestStatus(interestId);
    } catch (_) {
      // If sync fails, we still have the local update
    }
  }
}



final matchesControllerProvider =
    NotifierProvider<MatchesController, MatchesState>(
      MatchesController.new,
    );
final userInterestsControllerProvider =
    NotifierProvider<UserInterestsController, UserInterestsState>(
      UserInterestsController.new,
    );
final interestsControllerProvider =
    NotifierProvider<InterestsController, InterestsState>(
      InterestsController.new,
    );
