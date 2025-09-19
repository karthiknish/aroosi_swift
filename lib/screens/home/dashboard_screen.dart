import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/features/chat/unread_counts_controller.dart';
import 'package:aroosi_flutter/features/engagement/quick_picks_repository.dart';
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
import 'widgets/section_title.dart';
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
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
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
          if (usageAsync.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 3),
            )
          else if (periodStart != null && periodEnd != null)
            UsagePeriodInfo(periodStart: periodStart, periodEnd: periodEnd)
          else if (usageAsync.hasError)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Subscription usage information is unavailable right now.',
                style: TextStyle(fontSize: 12, color: Colors.redAccent),
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
          const SectionTitle('Quick Picks'),
          const SizedBox(height: 8),
          if (quickPicksAsync.hasError)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Unable to load quick picks. Pull to refresh later.',
                style: TextStyle(fontSize: 12, color: Colors.redAccent),
              ),
            ),
          QuickPicksStrip(
            loading: quickPicksLoading,
            items: quickPicks,
            onTapProfile: (id) => _openProfileDetails(context, id),
            onSeeAll: () => _openQuickPicks(context),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Continue exploring'),
          const SizedBox(height: 8),
          ExploreGrid(
            onNavigate: (route) => _handleExploreNavigation(context, route),
          ),
        ],
      ),
    );
  }
}

void _openSubscription(BuildContext context) {
  GoRouter.of(context).pushNamed('mainSubscription');
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
