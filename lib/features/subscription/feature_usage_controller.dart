import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/features/subscription/feature_access_provider.dart';
import 'package:aroosi_flutter/features/subscription/subscription_features.dart';

class FeatureUsageState {
  const FeatureUsageState({this.usages = const {}});

  final Map<UsageMetric, int> usages;

  int count(UsageMetric metric) => usages[metric] ?? 0;

  FeatureUsageState copyWithIncremented(UsageMetric metric) {
    final next = Map<UsageMetric, int>.from(usages);
    next[metric] = (next[metric] ?? 0) + 1;
    return FeatureUsageState(usages: next);
  }

  FeatureUsageState reset() => const FeatureUsageState();
}

class FeatureUsageController extends Notifier<FeatureUsageState> {
  @override
  FeatureUsageState build() {
    // Reset usage counters whenever feature access (plan) changes
    ref.listen<FeatureAccess>(featureAccessProvider, (_, __) {
      state = const FeatureUsageState();
    });
    return const FeatureUsageState();
  }

  bool requestUsage(UsageMetric metric) {
  final access = ref.read(featureAccessProvider);
    final limit = access.usageLimit(metric);

    if (limit == 0) {
      return false;
    }

    if (limit > 0 && state.count(metric) >= limit) {
      return false;
    }

    state = state.copyWithIncremented(metric);
    return true;
  }

  void reset() {
    state = state.reset();
  }
}

final featureUsageControllerProvider =
    NotifierProvider<FeatureUsageController, FeatureUsageState>(FeatureUsageController.new);
