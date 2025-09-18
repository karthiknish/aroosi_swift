import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/features/subscription/subscription_controller.dart';
import 'package:aroosi_flutter/features/subscription/subscription_features.dart';
import 'package:aroosi_flutter/features/subscription/subscription_models.dart';

class FeatureAccess {
  FeatureAccess({required this.plan});

  final SubscriptionPlan plan;

  SubscriptionFeatures get features => featuresForPlan(plan);

  bool can(SubscriptionFeatureFlag feature) => canAccessFeature(plan, feature);

  int usageLimit(UsageMetric metric) => usageLimitFor(plan, metric);

  bool hasUnlimited(UsageMetric metric) => hasUnlimitedUsage(plan, metric);

  SubscriptionPlan requiredPlan(SubscriptionFeatureFlag feature) => minimumPlanForFeature(feature);

  String requiredPlanLabel(SubscriptionFeatureFlag feature) {
    return planDisplayName(requiredPlan(feature));
  }
}

final featureAccessProvider = Provider<FeatureAccess>((ref) {
  final subscriptionState = ref.watch(subscriptionControllerProvider);
  final authState = ref.watch(authControllerProvider);

  final plan = subscriptionState.status?.plan ??
      SubscriptionPlanX.fromId(authState.profile?.plan) ??
      SubscriptionPlan.free;

  return FeatureAccess(plan: plan);
});
