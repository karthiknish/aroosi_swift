import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/features/engagement/quick_picks_repository.dart';
import 'package:aroosi_flutter/features/profiles/models.dart';
import 'package:aroosi_flutter/core/api_client.dart';

// Provider for quick picks repository
final quickPicksRepositoryProvider = Provider<QuickPicksRepository>((ref) {
  return QuickPicksRepository();
});

// State class for quick picks
class QuickPicksState {
  const QuickPicksState({
    this.profiles = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.error,
    this.compatibilityScores = const {},
    this.hasLikedToday = false,
    this.totalLikesToday = 0,
    this.dailyLimit = 10, // Default limit without subscription
  });

  final List<ProfileSummary> profiles;
  final int currentIndex;
  final bool isLoading;
  final String? error;
  final Map<String, int> compatibilityScores; // userId -> score
  final bool hasLikedToday;
  final int totalLikesToday;
  final int dailyLimit;

  QuickPicksState copyWith({
    List<ProfileSummary>? profiles,
    int? currentIndex,
    bool? isLoading,
    String? error,
    Map<String, int>? compatibilityScores,
    bool? hasLikedToday,
    int? totalLikesToday,
    int? dailyLimit,
  }) {
    return QuickPicksState(
      profiles: profiles ?? this.profiles,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      compatibilityScores: compatibilityScores ?? this.compatibilityScores,
      hasLikedToday: hasLikedToday ?? this.hasLikedToday,
      totalLikesToday: totalLikesToday ?? this.totalLikesToday,
      dailyLimit: dailyLimit ?? this.dailyLimit,
    );
  }

  ProfileSummary? get currentProfile {
    if (currentIndex < profiles.length) {
      return profiles[currentIndex];
    }
    return null;
  }

  List<ProfileSummary> get nextProfiles {
    return profiles.skip(currentIndex + 1).take(3).toList();
  }

  bool get hasMoreProfiles => currentIndex < profiles.length;
  bool get canLike => totalLikesToday < dailyLimit;
}

// Notifier for managing quick picks
class QuickPicksNotifier extends Notifier<QuickPicksState> {
  QuickPicksRepository get _repository => ref.read(quickPicksRepositoryProvider);

  @override
  QuickPicksState build() => const QuickPicksState();

  Future<void> loadQuickPicks({String? dayKey}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final profiles = await _repository.getQuickPicks(dayKey: dayKey);
      
      // Load compatibility scores for each profile
      final scores = <String, int>{};
      for (final profile in profiles) {
        try {
          final score = await _getCompatibilityScore(profile.id);
          scores[profile.id] = score;
        } catch (_) {
          scores[profile.id] = 0; // Default score if API fails
        }
      }
      
      state = state.copyWith(
        profiles: profiles,
        compatibilityScores: scores,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<int> _getCompatibilityScore(String userId) async {
    try {
      final response = await ApiClient.dio.get('/compatibility/$userId');
      if (response.data['success'] == true) {
        return response.data['data']['score'] as int? ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  Future<void> likeProfile() async {
    if (!state.canLike || state.currentProfile == null) return;

    final currentProfile = state.currentProfile!;
    
    try {
      await _repository.actOnQuickPick(currentProfile.id, 'like');
      
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        hasLikedToday: true,
        totalLikesToday: state.totalLikesToday + 1,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> skipProfile() async {
    if (state.currentProfile == null) return;

    final currentProfile = state.currentProfile!;
    
    try {
      await _repository.actOnQuickPick(currentProfile.id, 'skip');
      
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const QuickPicksState();
  }
}

// Provider for the quick picks notifier
final quickPicksProvider = NotifierProvider<QuickPicksNotifier, QuickPicksState>(QuickPicksNotifier.new);
