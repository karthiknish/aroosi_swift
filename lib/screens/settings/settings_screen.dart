import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/features/subscription/feature_access_provider.dart';
import 'package:aroosi_flutter/features/subscription/feature_usage_controller.dart';
import 'package:aroosi_flutter/features/subscription/subscription_features.dart';
import 'package:aroosi_flutter/features/subscription/subscription_models.dart';
import 'package:aroosi_flutter/widgets/inline_upgrade_banner.dart';
import 'package:aroosi_flutter/platform/adaptive_feedback.dart';
import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/widgets/animations/motion.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(featureAccessProvider);
    final usageController = ref.read(featureUsageControllerProvider.notifier);
    final usageState = ref.watch(featureUsageControllerProvider);

    bool requestUsage(UsageMetric metric) {
      final allowed = usageController.requestUsage(metric);
      if (!allowed) {
        final planLabel = access.requiredPlanLabel(
          _usageFeatureMapping[metric] ??
              SubscriptionFeatureFlag.canBoostProfile,
        );
        final limit = access.usageLimit(metric);
        final used = usageState.count(metric);
        final message = limit > 0
            ? 'You\'ve used $used of $limit available boosts. Upgrade to $planLabel for more.'
            : 'Upgrade to $planLabel to unlock this feature.';
        ToastService.instance.warning(message);
      }
      return allowed;
    }

    void showUpgrade(SubscriptionFeatureFlag feature) {
      final planLabel = access.requiredPlanLabel(feature);
      ToastService.instance.warning(
        'Upgrade to $planLabel to use this feature.',
      );
    }

    final plan = access.plan;
    final bool isFreePlan = plan == SubscriptionPlan.free;
    int tileIndex = 0;
    Widget animatedTile(Widget child) => FadeSlideIn(
      delay: Duration(milliseconds: 60 * tileIndex++),
      beginOffset: const Offset(0, 0.04),
      child: child,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: FadeThrough(
        delay: AppMotionDurations.fast,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (plan != SubscriptionPlan.premiumPlus)
              animatedTile(
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: InlineUpgradeBanner(
                    message: isFreePlan
                        ? 'Upgrade to Premium to unlock unlimited messages, full profiles, and more.'
                        : 'Upgrade to Premium Plus for unlimited boosts, incognito mode, and spotlight badge.',
                    ctaLabel: isFreePlan
                        ? 'Upgrade to Premium'
                        : 'Upgrade to Premium Plus',
                    onPressed: () => context.push('/main/subscription'),
                    icon: Icons.workspace_premium_outlined,
                  ),
                ),
              ),
            animatedTile(
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About Aroosi'),
                onTap: () => context.push('/settings/about'),
              ),
            ),
            animatedTile(
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notification Settings'),
                onTap: () => context.push('/settings/notifications'),
              ),
            ),
            animatedTile(
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Privacy Settings'),
                onTap: () => context.push('/settings/privacy'),
              ),
            ),
            animatedTile(
              ListTile(
                leading: const Icon(Icons.security_outlined),
                title: const Text('Safety Guidelines'),
                onTap: () => context.push('/settings/safety'),
              ),
            ),
            animatedTile(
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Blocked Users'),
                onTap: () => context.push('/settings/blocked-users'),
              ),
            ),
            animatedTile(
              ListTile(
                leading: const Icon(Icons.support_agent),
                title: const Text('Support'),
                onTap: () {
                  if (!access.can(
                    SubscriptionFeatureFlag.canAccessPrioritySupport,
                  )) {
                    showUpgrade(
                      SubscriptionFeatureFlag.canAccessPrioritySupport,
                    );
                    return;
                  }
                  context.push('/support');
                },
              ),
            ),
            const Divider(),
            animatedTile(
              ListTile(
                leading: const Icon(Icons.bolt),
                title: const Text('Boost profile'),
                subtitle: Text(
                  access.can(SubscriptionFeatureFlag.canBoostProfile)
                      ? 'Stand out in search results'
                      : 'Upgrade to ${access.requiredPlanLabel(SubscriptionFeatureFlag.canBoostProfile)}',
                ),
                onTap: () {
                  if (!access.can(SubscriptionFeatureFlag.canBoostProfile)) {
                    showUpgrade(SubscriptionFeatureFlag.canBoostProfile);
                    return;
                  }
                  if (!requestUsage(UsageMetric.profileBoostUsed)) {
                    return;
                  }
                  ToastService.instance.success('Profile boost activated');
                },
              ),
            ),
            animatedTile(
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined),
                title: const Text('Incognito mode'),
                subtitle: Text(
                  access.can(SubscriptionFeatureFlag.canUseIncognitoMode)
                      ? 'Hide your profile from free users'
                      : 'Upgrade to ${access.requiredPlanLabel(SubscriptionFeatureFlag.canUseIncognitoMode)}',
                ),
                onTap: () {
                  if (!access.can(
                    SubscriptionFeatureFlag.canUseIncognitoMode,
                  )) {
                    showUpgrade(SubscriptionFeatureFlag.canUseIncognitoMode);
                    return;
                  }
                  ToastService.instance.info('Incognito mode toggled (demo)');
                },
              ),
            ),
            animatedTile(
              ListTile(
                leading: Icon(
                  Icons.delete_forever,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const Text('Clear cached data'),
                onTap: () async {
                  final ctx = context;
                  // ignore: use_build_context_synchronously
                  final i = await showAdaptiveActionSheet(
                    ctx,
                    title: 'Clear cached data?',
                    actions: const ['Clear now'],
                  );
                  if (i == 0) {
                    // TODO: wire actual cache clear logic
                    ToastService.instance.success('Cache cleared');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const Map<UsageMetric, SubscriptionFeatureFlag> _usageFeatureMapping = {
  UsageMetric.profileBoostUsed: SubscriptionFeatureFlag.canBoostProfile,
  UsageMetric.interestSent: SubscriptionFeatureFlag.canSendUnlimitedLikes,
  UsageMetric.profileView: SubscriptionFeatureFlag.canViewFullProfiles,
  UsageMetric.searchPerformed: SubscriptionFeatureFlag.canUseAdvancedFilters,
  UsageMetric.messageSent: SubscriptionFeatureFlag.canInitiateChat,
  UsageMetric.voiceMessageSent: SubscriptionFeatureFlag.canChatWithMatches,
};
