import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/core/responsive.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/features/chat/unread_counts_controller.dart';
import 'package:aroosi_flutter/features/engagement/quick_picks_repository.dart';
import 'package:aroosi_flutter/features/icebreakers/icebreaker_controller.dart';
import 'package:aroosi_flutter/features/profiles/models.dart';
import 'widgets/actions_row.dart';
import 'widgets/explore_grid.dart';
import 'widgets/header_row.dart';
import 'widgets/quick_picks_strip.dart';

final _quickPicksProvider = FutureProvider<List<ProfileSummary>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isAuthenticated) {
    return const <ProfileSummary>[];
  }
  return QuickPicksRepository().getQuickPicks();
});

final _icebreakerProgressProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isAuthenticated) {
    return {'total': 0, 'answered': 0};
  }

  try {
    // Use the icebreaker controller which fetches from available /icebreakers API
    final icebreakerState = ref.watch(icebreakerControllerProvider);
    final total = icebreakerState.icebreakers.length;
    final answered = icebreakerState.icebreakers.where((q) => q.answered).length;
    return {
      'total': total,
      'answered': answered,
    };
  } catch (e) {
    debugPrint('Error loading icebreaker progress: $e');
    return {'total': 0, 'answered': 0};
  }
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final unreadState = ref.watch(unreadCountsProvider);
    final quickPicksAsync = ref.watch(_quickPicksProvider);
    final icebreakerProgress = ref.watch(_icebreakerProgressProvider);

    // Show loading state while initializing
    if (auth.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error state if auth failed
    if (auth.error != null && !auth.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('Authentication Error', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(auth.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(authControllerProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final unreadTotal = (unreadState.counts['total'] as num?)?.toInt() ?? 0;
    final quickPicks =
        quickPicksAsync.asData?.value ?? const <ProfileSummary>[];
    final quickPicksLoading = auth.loading || quickPicksAsync.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (unreadTotal > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // Navigate to notifications
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadTotal > 99 ? '99+' : unreadTotal.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh data
        },
        child: ResponsiveBuilder(
          builder: (context, screenType) {
            return ListView(
              padding: Responsive.screenPadding(context).copyWith(
                top: 12,
                bottom: 24,
              ),
              children: [
            if (icebreakerProgress.asData?.value != null)
              _IcebreakerProgressCard(
                progress: icebreakerProgress.asData!.value,
                onTap: () => _openIcebreakers(context),
              ),
            const SizedBox(height: 24),
            HeaderRow(unreadCount: unreadTotal),
            const SizedBox(height: 16),
            const ActionsRow(),
            const SizedBox(height: 16),
            if (quickPicksAsync.hasError)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Unable to load quick picks. Pull to refresh later.',
                        style: TextStyle(fontSize: 14, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            QuickPicksStrip(
              loading: quickPicksLoading,
              items: quickPicks,
              onTapProfile: (id) => _openProfileDetails(context, id),
              onSeeAll: () => _openQuickPicks(context),
            ),
            ExploreGrid(
              onNavigate: (route) => _handleExploreNavigation(context, route),
            ),
              ],
            );
          },
        ),
      ),
    );
  }
}

void _openIcebreakers(BuildContext context) {
  GoRouter.of(context).pushNamed('mainIcebreakers');
}

void _openQuickPicks(BuildContext context) {
  GoRouter.of(context).pushNamed('mainQuickPicks');
}

void _openProfileDetails(BuildContext context, String id) {
  if (id.isEmpty) return;
  GoRouter.of(context).pushNamed('details', pathParameters: {'id': id});
}

void _handleExploreNavigation(BuildContext context, String routeName) {
  final router = GoRouter.of(context);
  const shellRoutes = {'dashboard', 'search', 'favorites', 'profile'};
  if (shellRoutes.contains(routeName)) {
    router.goNamed(routeName);
  } else {
    router.pushNamed(routeName);
  }
}

class _IcebreakerProgressCard extends StatelessWidget {
  const _IcebreakerProgressCard({required this.progress, required this.onTap});

  final Map<String, int> progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = progress['total'] ?? 0;
    final answered = progress['answered'] ?? 0;
    final hasUnanswered = total > 0 && answered < total;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasUnanswered
            ? Colors.blue.withValues(alpha: 0.05)
            : Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasUnanswered
              ? Colors.blue.withValues(alpha: 0.2)
              : Colors.green.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasUnanswered
                        ? 'Break the ice today!'
                        : 'All icebreakers answered!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: hasUnanswered ? Colors.blue : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$answered / $total answered',
                    style: TextStyle(
                      fontSize: 14,
                      color: hasUnanswered
                          ? Colors.blue.withValues(alpha: 0.8)
                          : Colors.green.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasUnanswered ? Icons.arrow_forward : Icons.check_circle,
              color: hasUnanswered ? Colors.blue : Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}
