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

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {

  @override
  void initState() {
    super.initState();
    // Always fetch latest profile on mount
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authControllerProvider.notifier).refreshProfileOnly();
    });
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh profile when widget is updated (e.g., after returning from edit profile)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authControllerProvider.notifier).refreshProfileOnly();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch latest profile when screen regains focus (like RN useFocusEffect)
    // Note: addScopedWillPopCallback is deprecated, but keeping functionality for now
    final route = ModalRoute.of(context);
    if (route != null) {
      // Using addScopedWillPopCallback for backward compatibility
      // ignore: deprecated_member_use
      route.addScopedWillPopCallback(_onFocus);
    }
  }

  Future<bool> _onFocus() async {
    await ref.read(authControllerProvider.notifier).refreshProfileOnly();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final authCtrl = ref.read(authControllerProvider.notifier);
    final access = ref.watch(featureAccessProvider);
    final usage = ref.watch(featureUsageControllerProvider);
    final usageController = ref.read(featureUsageControllerProvider.notifier);

    if (auth.loading || auth.profile == null) {
      return const AppScaffold(
        title: 'Profile',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final name = (auth.profile?.fullName?.trim().isNotEmpty ?? false)
        ? auth.profile!.fullName!.trim()
        : 'Your Name';
    final email = auth.profile?.email ?? '';
    final avatar = auth.profile?.profileImageUrls?.isNotEmpty ?? false
        ? auth.profile!.profileImageUrls!.first
        : null;
    final plan = auth.profile?.plan ?? 'free';
    final expires = auth.profile?.subscriptionExpiresAt;
    final formattedPlan = _formatPlan(plan);
    final formattedExpiry = expires != null
        ? _formatDate(expires.toLocal())
        : null;

    return AppScaffold(
      title: 'Profile',
      child: RefreshIndicator(
        key: UniqueKey(),
        onRefresh: () async {
          await authCtrl.refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            MediaQuery.of(context).padding.bottom + 80,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileHeader(
                name: name,
                email: email,
                avatarUrl: avatar,
                planLabel: formattedPlan,
                planExpires: formattedExpiry,
              ),
              const SizedBox(height: 24),
              _ProfileQuickActions(
                onEditProfile: () => context.push('/main/edit-profile'),
                onManageSubscription: () => context.push('/main/subscription'),
                onPrivacySettings: () => context.push('/settings/privacy'),
                onSupport: () => context.push('/support'),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 24),
                _AccountDetailsCard(email: email, plan: formattedPlan),
              ],
              const SizedBox(height: 24),
              _FeatureHighlights(access: access),
              if (access.plan == SubscriptionPlan.free) ...[
                const SizedBox(height: 16),
                InlineUpgradeBanner(
                  message:
                      'Upgrade to Premium to unlock unlimited likes, full profile details, and more.',
                  ctaLabel: 'Upgrade to Premium',
                  onPressed: () => context.push('/main/subscription'),
                ),
              ] else if (access.plan == SubscriptionPlan.premium) ...[
                const SizedBox(height: 16),
                InlineUpgradeBanner(
                  message:
                      'Go Premium Plus for unlimited boosts, incognito mode, and a spotlight badge.',
                  ctaLabel: 'Upgrade to Premium Plus',
                  onPressed: () => context.push('/main/subscription'),
                ),
              ],
              const SizedBox(height: 24),
              _BoostControls(
                access: access,
                usage: usage,
                usageNotifier: usageController,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Log out',
                onPressed: auth.isAuthenticated
                    ? () async {
                        final confirm = await showAdaptiveConfirm(
                          context,
                          title: 'Log out',
                          message: 'Are you sure you want to log out?',
                          confirmText: 'Log out',
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
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.planLabel,
    this.planExpires,
  });

  final String name;
  final String email;
  final String? avatarUrl;
  final String planLabel;
  final String? planExpires;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (avatarUrl != null && avatarUrl!.isNotEmpty)
            CircleAvatar(
              radius: 42,
              backgroundImage: NetworkImage(avatarUrl!),
              onBackgroundImageError: (_, __) {
                // Handle image loading error gracefully - fallback to initials
                return;
              },
            )
          else
            CircleAvatar(
              radius: 42,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                name.trim().isNotEmpty
                    ? name.trim().substring(0, 1).toUpperCase()
                    : 'A',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.workspace_premium, size: 18),
                label: Text(planLabel),
              ),
              if (planExpires != null)
                Chip(
                  avatar: const Icon(Icons.schedule, size: 18),
                  label: Text('Renews $planExpires'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileQuickActions extends StatelessWidget {
  const _ProfileQuickActions({
    required this.onEditProfile,
    required this.onManageSubscription,
    required this.onPrivacySettings,
    required this.onSupport,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onManageSubscription;
  final VoidCallback onPrivacySettings;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _ActionButton(
          icon: Icons.edit,
          label: 'Edit profile',
          onTap: onEditProfile,
        ),
        _ActionButton(
          icon: Icons.workspace_premium,
          label: 'Manage subscription',
          onTap: onManageSubscription,
        ),
        _ActionButton(
          icon: Icons.privacy_tip,
          label: 'Privacy settings',
          onTap: onPrivacySettings,
        ),
        _ActionButton(
          icon: Icons.support_agent,
          label: 'Support',
          onTap: onSupport,
        ),
      ],
    );
  }
}

class _AccountDetailsCard extends StatelessWidget {
  const _AccountDetailsCard({required this.email, required this.plan});

  final String email;
  final String plan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(email),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Current plan'),
            subtitle: Text(plan),
            trailing: TextButton(
              onPressed: () => context.push('/main/subscription'),
              child: const Text('View options'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

String _formatPlan(String plan) {
  if (plan.isEmpty || plan.toLowerCase() == 'free') return 'Free';
  final normalized = plan
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
      .trim();
  if (normalized.isEmpty) return 'Free';
  return normalized
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      })
      .join(' ');
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[(date.month - 1).clamp(0, months.length - 1)];
  final day = date.day.toString().padLeft(2, '0');
  return '$month $day, ${date.year}';
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
