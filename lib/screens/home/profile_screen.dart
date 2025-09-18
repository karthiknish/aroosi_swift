import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/features/subscription/feature_access_provider.dart';
import 'package:aroosi_flutter/features/subscription/feature_usage_controller.dart';
import 'package:aroosi_flutter/features/subscription/subscription_features.dart';
import 'package:aroosi_flutter/features/subscription/subscription_models.dart';
import 'package:aroosi_flutter/widgets/inline_upgrade_banner.dart';
import 'package:aroosi_flutter/features/subscription/subscription_repository.dart';
import 'package:aroosi_flutter/features/profiles/profiles_repository.dart';
import 'package:aroosi_flutter/platform/adaptive_dialogs.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/widgets/primary_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final authCtrl = ref.read(authControllerProvider.notifier);
    final access = ref.watch(featureAccessProvider);
    final usage = ref.watch(featureUsageControllerProvider);
    final usageController = ref.read(featureUsageControllerProvider.notifier);

    final name = auth.profile?.fullName ?? 'Guest';
    final email = auth.profile?.email ?? '';
    final avatar = auth.profile?.avatarUrl;
    final plan = auth.profile?.plan ?? 'free';
    final expires = auth.profile?.subscriptionExpiresAt;
    return AppScaffold(
      title: 'Profile',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (auth.loading) const CircularProgressIndicator(),
            if (!auth.loading) ...[
              if (avatar != null && avatar.isNotEmpty) ...[
                CircleAvatar(radius: 36, backgroundImage: NetworkImage(avatar)),
                const SizedBox(height: 12),
              ],
              Text(auth.isAuthenticated ? name : 'Logged out'),
              if (email.isNotEmpty) ...[const SizedBox(height: 8), Text(email)],
              const SizedBox(height: 8),
              Text('Plan: ${plan.toUpperCase()}'),
              if (expires != null) Text('Expires: ${expires.toLocal()}'),
              const SizedBox(height: 16),
              _FeatureHighlights(access: access),
              if (access.plan == SubscriptionPlan.free) ...[
                const SizedBox(height: 12),
                InlineUpgradeBanner(
                  message:
                      'Upgrade to Premium to unlock unlimited likes, full profile details, and more.',
                  ctaLabel: 'Upgrade to Premium',
                  onPressed: () => context.push('/main/subscription'),
                ),
              ] else if (access.plan == SubscriptionPlan.premium) ...[
                const SizedBox(height: 12),
                InlineUpgradeBanner(
                  message:
                      'Go Premium Plus for unlimited boosts, incognito mode, and spotlight badge.',
                  ctaLabel: 'Upgrade to Premium Plus',
                  onPressed: () => context.push('/main/subscription'),
                ),
              ],
              const SizedBox(height: 16),
              _BoostControls(
                access: access,
                usage: usage,
                usageNotifier: usageController,
              ),
            ],
            PrimaryButton(
              label: 'Logout',
              onPressed: auth.isAuthenticated
                  ? () async {
                      final confirm = await showAdaptiveConfirm(
                        context,
                        title: 'Logout',
                        message: 'Are you sure you want to log out?',
                        confirmText: 'Logout',
                        cancelText: 'Cancel',
                      );
                      if (!context.mounted) return;
                      if (confirm) {
                        await authCtrl.logout();
                      }
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureHighlights extends StatelessWidget {
  const _FeatureHighlights({required this.access});

  final FeatureAccess access;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan benefits',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _FeatureRow(
              icon: Icons.tune,
              title: 'Advanced filters',
              enabled: access.can(
                SubscriptionFeatureFlag.canUseAdvancedFilters,
              ),
            ),
            _FeatureRow(
              icon: Icons.remove_red_eye,
              title: 'See who viewed you',
              enabled: access.can(
                SubscriptionFeatureFlag.canViewProfileViewers,
              ),
            ),
            _FeatureRow(
              icon: Icons.bolt,
              title: 'Profile boosts',
              enabled: access.can(SubscriptionFeatureFlag.canBoostProfile),
              detail: access.hasUnlimited(UsageMetric.profileBoostUsed)
                  ? 'Unlimited'
                  : '${access.usageLimit(UsageMetric.profileBoostUsed)} / month',
            ),
            _FeatureRow(
              icon: Icons.local_fire_department_outlined,
              title: 'Incognito mode',
              enabled: access.can(SubscriptionFeatureFlag.canUseIncognitoMode),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.enabled,
    this.detail,
  });

  final IconData icon;
  final String title;
  final bool enabled;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = enabled
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyMedium),
                if (detail != null)
                  Text(detail!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Icon(
            enabled ? Icons.check_circle : Icons.lock,
            color: color,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _BoostControls extends ConsumerStatefulWidget {
  const _BoostControls({
    required this.access,
    required this.usage,
    required this.usageNotifier,
  });

  final FeatureAccess access;
  final FeatureUsageState usage;
  final FeatureUsageController usageNotifier;

  @override
  ConsumerState<_BoostControls> createState() => _BoostControlsState();
}

class _BoostControlsState extends ConsumerState<_BoostControls> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final access = widget.access;
    final usage = widget.usage;

    final canBoost = access.can(SubscriptionFeatureFlag.canBoostProfile);
    final limit = access.usageLimit(UsageMetric.profileBoostUsed);
    final used = usage.count(UsageMetric.profileBoostUsed);
    final unlimited = access.hasUnlimited(UsageMetric.profileBoostUsed);
    final remaining = !unlimited && limit > 0
        ? (limit - used).clamp(0, limit)
        : null;
    final limitReached = !unlimited && limit > 0 && remaining == 0;

    final availabilityLabel = unlimited
        ? 'Unlimited boosts included'
        : limit <= 0
        ? 'No boosts available on your plan'
        : '$remaining of $limit boosts remaining this month';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile boost', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Move to the top of discovery and get more attention for a short time.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(availabilityLabel, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting
                  ? null
                  : () => _handleBoost(context, canBoost, limitReached),
              child: _submitting
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Boosting...'),
                      ],
                    )
                  : Text(
                      !canBoost
                          ? 'Upgrade to boost'
                          : limitReached
                          ? 'Boost limit reached'
                          : 'Boost now',
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBoost(
    BuildContext context,
    bool canBoost,
    bool limitReached,
  ) async {
    final access = widget.access;
    final subscriptionRepository = ref.read(subscriptionRepositoryProvider);
    final profilesRepository = ref.read(profilesRepositoryProvider);
    final usageNotifier = widget.usageNotifier;

    if (!canBoost) {
      final planLabel = access.requiredPlanLabel(
        SubscriptionFeatureFlag.canBoostProfile,
      );
      ToastService.instance.warning(
        'Upgrade to $planLabel to unlock profile boosts.',
      );
      context.push('/main/subscription');
      return;
    }

    if (limitReached) {
      final planLabel = access.requiredPlanLabel(
        SubscriptionFeatureFlag.canBoostProfile,
      );
      ToastService.instance.warning(
        "You've used all available boosts this month. Upgrade to $planLabel for more.",
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final availability = await subscriptionRepository.canUseFeature(
        'profileBoosts',
      );
      if (availability != null && !availability.canUse) {
        final planLabel = availability.requiredPlan != null
            ? planDisplayName(availability.requiredPlan!)
            : access.requiredPlanLabel(SubscriptionFeatureFlag.canBoostProfile);
        final reason =
            availability.reason ??
            'Profile boost is not available on your current plan.';
        ToastService.instance.warning(reason);
        if (availability.requiredPlan != null) {
          ToastService.instance.info('Upgrade to $planLabel for more boosts.');
        }
        return;
      }

      final success = await profilesRepository.boostProfile();
      if (!success) {
        ToastService.instance.error(
          'Failed to boost profile. Please try again.',
        );
        return;
      }

      usageNotifier.requestUsage(UsageMetric.profileBoostUsed);
      await subscriptionRepository.trackFeatureUsage('profileBoosts');
      ToastService.instance.success(
        'Profile boost activated! Your profile is being highlighted to more members.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }
}
