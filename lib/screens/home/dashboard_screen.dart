import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/features/chat/unread_counts_controller.dart';
import 'package:aroosi_flutter/features/engagement/quick_picks_repository.dart';
import 'package:aroosi_flutter/features/icebreakers/icebreaker_controller.dart';
import 'package:aroosi_flutter/features/profiles/models.dart';
import 'package:aroosi_flutter/features/subscription/feature_access_provider.dart';
import 'package:aroosi_flutter/features/subscription/subscription_controller.dart';

import 'package:aroosi_flutter/features/subscription/subscription_models.dart';
import 'package:aroosi_flutter/features/subscription/subscription_repository.dart';
import 'widgets/actions_row.dart';
import 'widgets/explore_grid.dart';
import 'widgets/header_row.dart';
import 'widgets/premium_features_grid.dart';
import 'widgets/quick_picks_strip.dart';

import 'widgets/subscription_status_header.dart';
import 'widgets/unlock_all_features_cta.dart';
import 'widgets/usage_period_info.dart';

final _quickPicksProvider = FutureProvider<List<ProfileSummary>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isAuthenticated) {
    return const <ProfileSummary>[];
  }
  return QuickPicksRepository().getQuickPicks();
});

final _subscriptionUsageProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isAuthenticated) {
    return null;
  }
  final repository = ref.read(subscriptionRepositoryProvider);
  return repository.fetchUsage();
});

final _icebreakerProgressProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isAuthenticated) {
    return {'total': 0, 'answered': 0};
  }

  try {
    final icebreakerState = ref.watch(icebreakerControllerProvider);
    return {
      'total': icebreakerState.icebreakers.length,
      'answered': icebreakerState.icebreakers.where((q) => q.answered).length,
    };
  } catch (e) {
    return {'total': 0, 'answered': 0};
  }
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final subscriptionState = ref.watch(subscriptionControllerProvider);
    final featureAccess = ref.watch(featureAccessProvider);
    final unreadState = ref.watch(unreadCountsProvider);
    final quickPicksAsync = ref.watch(_quickPicksProvider);
    final usageAsync = ref.watch(_subscriptionUsageProvider);
    final icebreakerProgress = ref.watch(_icebreakerProgressProvider);

    final status = subscriptionState.status;
    final plan =
        status?.plan ??
        SubscriptionPlanX.fromId(auth.profile?.plan) ??
        SubscriptionPlan.free;
    final isActive = status?.isActive ?? auth.profile?.isSubscribed ?? false;
    final expiresAt = status?.expiresAt ?? auth.profile?.subscriptionExpiresAt;
    final daysUntilExpiry = _computeDaysUntil(expiresAt);
    final isApproachingExpiry =
        isActive && daysUntilExpiry != null && daysUntilExpiry <= 5;

    final usagePayload = _normalizeUsagePayload(usageAsync.asData?.value);
    final periodStart = _parseTimestamp(
      usagePayload?['periodStart'] ?? usagePayload?['currentPeriodStart'],
    );
    final periodEnd = _parseTimestamp(
      usagePayload?['periodEnd'] ??
          usagePayload?['currentPeriodEnd'] ??
          usagePayload?['resetDate'],
    );

    final features = featureAccess.features;
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            SubscriptionStatusHeader(
              plan: plan,
              isActive: isActive,
              expiresAt: expiresAt,
              isApproachingExpiry: isApproachingExpiry,
              daysUntilExpiry: daysUntilExpiry,
              onUpgrade: () => _openSubscription(context),
            ),
            if (icebreakerProgress.asData?.value != null)
              _IcebreakerProgressCard(
                progress: icebreakerProgress.asData!.value,
                onTap: () => _openIcebreakers(context),
              ),
            if (usageAsync.isLoading)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Loading subscription information...',
                        style: TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              )
            else if (periodStart != null && periodEnd != null)
              UsagePeriodInfo(periodStart: periodStart, periodEnd: periodEnd)
            else if (usageAsync.hasError)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Subscription usage information is unavailable right now.',
                        style: TextStyle(fontSize: 14, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            PremiumFeaturesGrid(
              features: features,
              onUpgrade: () => _openSubscription(context),
            ),
            if (!isActive)
              UnlockAllFeaturesCTA(onUpgrade: () => _openSubscription(context)),
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
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.2),
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
        ),
      ),
    );
  }
}

void _openSubscription(BuildContext context) {
  GoRouter.of(context).pushNamed('mainSubscription');
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

int? _computeDaysUntil(DateTime? date) {
  if (date == null) return null;
  final now = DateTime.now();
  final diff = date.toLocal().difference(now);
  if (diff.isNegative) return 0;
  final days = diff.inDays;
  return diff.inHours % 24 == 0 ? days : days + 1;
}

DateTime? _parseTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) {
    if (value > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
    }
    if (value > 0) {
      return DateTime.fromMillisecondsSinceEpoch(
        value * 1000,
        isUtc: true,
      ).toLocal();
    }
    return null;
  }
  if (value is double) {
    return _parseTimestamp(value.toInt());
  }
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toLocal();
    final numeric = int.tryParse(value);
    if (numeric != null) return _parseTimestamp(numeric);
  }
  return null;
}

Map<String, dynamic>? _normalizeUsagePayload(Map<String, dynamic>? raw) {
  if (raw == null) return null;
  if (raw['data'] is Map<String, dynamic>) {
    return (raw['data'] as Map).cast<String, dynamic>();
  }
  return raw;
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
            ? Colors.blue.withOpacity(0.05)
            : Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasUnanswered
              ? Colors.blue.withOpacity(0.2)
              : Colors.green.withOpacity(0.2),
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
                          ? Colors.blue.withOpacity(0.8)
                          : Colors.green.withOpacity(0.8),
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
