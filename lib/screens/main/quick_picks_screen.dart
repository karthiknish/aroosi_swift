import 'package:flutter/material.dart';

import 'package:aroosi_flutter/platform/adaptive_pickers.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/features/engagement/icebreaker_service.dart';
import 'package:aroosi_flutter/features/engagement/quick_picks_provider.dart';
import 'package:aroosi_flutter/widgets/swipeable_card.dart';
import 'package:aroosi_flutter/features/icebreakers/icebreaker_repository.dart';

class QuickPicksScreen extends ConsumerStatefulWidget {
  const QuickPicksScreen({super.key});

  @override
  ConsumerState<QuickPicksScreen> createState() => _QuickPicksScreenState();
}

class _QuickPicksScreenState extends ConsumerState<QuickPicksScreen> {
  final icebreakerRepository = IcebreakerRepository();
  List<String> _icebreakers = [];

  @override
  void initState() {
    super.initState();
    _loadIcebreakers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quickPicksProvider.notifier).loadQuickPicks();
    });
  }

  Future<void> _loadIcebreakers() async {
    try {
      final icebreakers = await IcebreakerService().getDailyIcebreakers();
      if (mounted) {
        setState(() {
          _icebreakers = icebreakers.map((q) => q.text).toList();
        });
      }
    } catch (_) {
      // Ignore errors for icebreakers
    }
  }

  @override
  Widget build(BuildContext context) {
    final quickPicksState = ref.watch(quickPicksProvider);
    final quickPicksNotifier = ref.read(quickPicksProvider.notifier);

    return AppScaffold(
      title: 'Match Concierge',
      actions: [
        IconButton(
          onPressed: () async {
            final ctx = context;
            // ignore: use_build_context_synchronously
            final date = await showAdaptiveDatePicker(ctx);
            if (date != null) {
              final dayKey =
                  '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
              quickPicksNotifier.loadQuickPicks(dayKey: dayKey);
              final dateStr = date.toLocal().toString().split(' ').first;
              ToastService.instance.success('Filter date: $dateStr');
            }
          },
          icon: const Icon(Icons.filter_list),
        ),
        IconButton(
          onPressed: () => quickPicksNotifier.loadQuickPicks(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: _buildContent(quickPicksState, quickPicksNotifier),
    );
  }

  Widget _buildContent(QuickPicksState state, QuickPicksNotifier notifier) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading quick picks',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                notifier.clearError();
                notifier.loadQuickPicks();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'All caught up!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back tomorrow for more matches',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header with progress and limits
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Quick Picks',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: state.canLike
                          ? Colors.green.shade50
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: state.canLike
                            ? Colors.green.shade300
                            : Colors.grey.shade400,
                      ),
                    ),
                    child: Text(
                      '${state.totalLikesToday}/${state.dailyLimit} likes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: state.canLike
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (state.currentIndex + 1) / state.profiles.length,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${state.currentIndex + 1}/${state.profiles.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Cards stack
        Expanded(
          child: Stack(
            children: [
              // Background cards (show next 2 cards)
              ...state.nextProfiles.asMap().entries.map((entry) {
                final index = entry.key;
                final profile = entry.value;
                return Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 16.0 * (index + 1),
                      bottom: 16.0 * (index + 1),
                      left: 24.0 * (index + 1),
                      right: 24.0 * (index + 1),
                    ),
                    child: SwipeableCard(
                      profile: profile,
                      onSwipeComplete: (_) {}, // Disabled for background cards
                      compatibilityScore:
                          state.compatibilityScores[profile.id] ?? 0,
                      isTopCard: false,
                      icebreakers: _icebreakers,
                    ),
                  ),
                );
              }),

              // Top card (interactive)
              if (state.currentProfile != null)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SwipeableCard(
                      profile: state.currentProfile!,
                      onSwipeComplete: (direction) {
                        if (direction == SwipeDirection.right &&
                            state.canLike) {
                          notifier.likeProfile();
                        } else if (direction == SwipeDirection.right &&
                            !state.canLike) {
                          ToastService.instance.warning(
                            'Daily limit reached. Try again tomorrow.',
                          );
                        } else if (direction == SwipeDirection.left) {
                          notifier.skipProfile();
                        }
                      },
                      compatibilityScore:
                          state.compatibilityScores[state.currentProfile!.id] ??
                          0,
                      isTopCard: true,
                      icebreakers: _icebreakers,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
