import 'package:aroosi_flutter/features/subscription/subscription_models.dart';

enum SubscriptionFeatureFlag {
  canViewMatches,
  canChatWithMatches,
  canInitiateChat,
  canSendUnlimitedLikes,
  canViewFullProfiles,
  canHideFromFreeUsers,
  canBoostProfile,
  canViewProfileViewers,
  canUseAdvancedFilters,
  hasSpotlightBadge,
  canUseIncognitoMode,
  canAccessPrioritySupport,
  canSeeReadReceipts,
}

enum UsageMetric {
  messageSent,
  profileView,
  searchPerformed,
  interestSent,
  profileBoostUsed,
  voiceMessageSent,
}

class SubscriptionFeatures {
  const SubscriptionFeatures({
    required this.canViewMatches,
    required this.canChatWithMatches,
    required this.canInitiateChat,
    required this.canSendUnlimitedLikes,
    required this.canViewFullProfiles,
    required this.canHideFromFreeUsers,
    required this.canBoostProfile,
    required this.canViewProfileViewers,
    required this.canUseAdvancedFilters,
    required this.hasSpotlightBadge,
    required this.canUseIncognitoMode,
    required this.canAccessPrioritySupport,
    required this.canSeeReadReceipts,
    required this.maxLikesPerDay,
    required this.boostsPerMonth,
  });

  final bool canViewMatches;
  final bool canChatWithMatches;
  final bool canInitiateChat;
  final bool canSendUnlimitedLikes;
  final bool canViewFullProfiles;
  final bool canHideFromFreeUsers;
  final bool canBoostProfile;
  final bool canViewProfileViewers;
  final bool canUseAdvancedFilters;
  final bool hasSpotlightBadge;
  final bool canUseIncognitoMode;
  final bool canAccessPrioritySupport;
  final bool canSeeReadReceipts;
  final int maxLikesPerDay;
  final int boostsPerMonth;
}

const Map<SubscriptionPlan, SubscriptionFeatures> kFeatureAccessRules = {
  SubscriptionPlan.free: SubscriptionFeatures(
    canViewMatches: true,
    canChatWithMatches: true,
    canInitiateChat: false,
    canSendUnlimitedLikes: false,
    canViewFullProfiles: false,
    canHideFromFreeUsers: false,
    canBoostProfile: false,
    canViewProfileViewers: false,
    canUseAdvancedFilters: false,
    hasSpotlightBadge: false,
    canUseIncognitoMode: false,
    canAccessPrioritySupport: false,
    canSeeReadReceipts: false,
    maxLikesPerDay: 5,
    boostsPerMonth: 0,
  ),
  SubscriptionPlan.premium: SubscriptionFeatures(
    canViewMatches: true,
    canChatWithMatches: true,
    canInitiateChat: true,
    canSendUnlimitedLikes: true,
    canViewFullProfiles: true,
    canHideFromFreeUsers: true,
    canBoostProfile: true,
    canViewProfileViewers: true,
    canUseAdvancedFilters: true,
    hasSpotlightBadge: false,
    canUseIncognitoMode: false,
    canAccessPrioritySupport: true,
    canSeeReadReceipts: true,
    maxLikesPerDay: -1,
    boostsPerMonth: 1,
  ),
  SubscriptionPlan.premiumPlus: SubscriptionFeatures(
    canViewMatches: true,
    canChatWithMatches: true,
    canInitiateChat: true,
    canSendUnlimitedLikes: true,
    canViewFullProfiles: true,
    canHideFromFreeUsers: true,
    canBoostProfile: true,
    canViewProfileViewers: true,
    canUseAdvancedFilters: true,
    hasSpotlightBadge: true,
    canUseIncognitoMode: true,
    canAccessPrioritySupport: true,
    canSeeReadReceipts: true,
    maxLikesPerDay: -1,
    boostsPerMonth: -1,
  ),
};

const Map<SubscriptionPlan, Map<UsageMetric, int>> kUsageLimits = {
  SubscriptionPlan.free: {
    UsageMetric.messageSent: 20,
    UsageMetric.profileView: 50,
    UsageMetric.searchPerformed: 100,
    UsageMetric.interestSent: 3,
    UsageMetric.profileBoostUsed: 0,
    UsageMetric.voiceMessageSent: 0,
  },
  SubscriptionPlan.premium: {
    UsageMetric.messageSent: -1,
    UsageMetric.profileView: 50,
    UsageMetric.searchPerformed: 500,
    UsageMetric.interestSent: -1,
    UsageMetric.profileBoostUsed: 1,
    UsageMetric.voiceMessageSent: 10,
  },
  SubscriptionPlan.premiumPlus: {
    UsageMetric.messageSent: -1,
    UsageMetric.profileView: -1,
    UsageMetric.searchPerformed: 2000,
    UsageMetric.interestSent: -1,
    UsageMetric.profileBoostUsed: -1,
    UsageMetric.voiceMessageSent: -1,
  },
};

SubscriptionFeatures featuresForPlan(SubscriptionPlan plan) {
  return kFeatureAccessRules[plan] ??
      kFeatureAccessRules[SubscriptionPlan.free]!;
}

bool canAccessFeature(SubscriptionPlan plan, SubscriptionFeatureFlag feature) {
  final features = featuresForPlan(plan);
  switch (feature) {
    case SubscriptionFeatureFlag.canViewMatches:
      return features.canViewMatches;
    case SubscriptionFeatureFlag.canChatWithMatches:
      return features.canChatWithMatches;
    case SubscriptionFeatureFlag.canInitiateChat:
      return features.canInitiateChat;
    case SubscriptionFeatureFlag.canSendUnlimitedLikes:
      return features.canSendUnlimitedLikes;
    case SubscriptionFeatureFlag.canViewFullProfiles:
      return features.canViewFullProfiles;
    case SubscriptionFeatureFlag.canHideFromFreeUsers:
      return features.canHideFromFreeUsers;
    case SubscriptionFeatureFlag.canBoostProfile:
      return features.canBoostProfile;
    case SubscriptionFeatureFlag.canViewProfileViewers:
      return features.canViewProfileViewers;
    case SubscriptionFeatureFlag.canUseAdvancedFilters:
      return features.canUseAdvancedFilters;
    case SubscriptionFeatureFlag.hasSpotlightBadge:
      return features.hasSpotlightBadge;
    case SubscriptionFeatureFlag.canUseIncognitoMode:
      return features.canUseIncognitoMode;
    case SubscriptionFeatureFlag.canAccessPrioritySupport:
      return features.canAccessPrioritySupport;
    case SubscriptionFeatureFlag.canSeeReadReceipts:
      return features.canSeeReadReceipts;
  }
}

int usageLimitFor(SubscriptionPlan plan, UsageMetric metric) {
  final limits = kUsageLimits[plan];
  if (limits == null) return 0;
  return limits[metric] ?? 0;
}

bool hasUnlimitedUsage(SubscriptionPlan plan, UsageMetric metric) {
  final limit = usageLimitFor(plan, metric);
  return limit < 0;
}

SubscriptionPlan minimumPlanForFeature(SubscriptionFeatureFlag feature) {
  switch (feature) {
    case SubscriptionFeatureFlag.canViewMatches:
    case SubscriptionFeatureFlag.canChatWithMatches:
      return SubscriptionPlan.free;
    case SubscriptionFeatureFlag.canInitiateChat:
    case SubscriptionFeatureFlag.canSendUnlimitedLikes:
    case SubscriptionFeatureFlag.canViewFullProfiles:
    case SubscriptionFeatureFlag.canHideFromFreeUsers:
    case SubscriptionFeatureFlag.canBoostProfile:
    case SubscriptionFeatureFlag.canViewProfileViewers:
    case SubscriptionFeatureFlag.canUseAdvancedFilters:
    case SubscriptionFeatureFlag.canAccessPrioritySupport:
    case SubscriptionFeatureFlag.canSeeReadReceipts:
      return SubscriptionPlan.premium;
    case SubscriptionFeatureFlag.hasSpotlightBadge:
    case SubscriptionFeatureFlag.canUseIncognitoMode:
      return SubscriptionPlan.premiumPlus;
  }
}

typedef FeatureComparisonRow = ({
  String feature,
  Object free,
  Object premium,
  Object premiumPlus,
});

final List<FeatureComparisonRow> kFeatureComparison = [
  (
    feature: 'Send Messages',
    free: '20 / month',
    premium: 'Unlimited',
    premiumPlus: 'Unlimited',
  ),
  (
    feature: 'View full profiles',
    free: false,
    premium: true,
    premiumPlus: true,
  ),
  (
    feature: 'Send Interests',
    free: '3 / month',
    premium: 'Unlimited',
    premiumPlus: 'Unlimited',
  ),
  (
    feature: 'Advanced Search Filters',
    free: false,
    premium: true,
    premiumPlus: true,
  ),
  (
    feature: 'See Who Viewed You',
    free: false,
    premium: true,
    premiumPlus: true,
  ),
  (
    feature: 'Profile Boost',
    free: false,
    premium: '1 / month',
    premiumPlus: 'Unlimited',
  ),
  (feature: 'Read Receipts', free: false, premium: true, premiumPlus: true),
  (
    feature: 'See Who Liked You',
    free: false,
    premium: false,
    premiumPlus: true,
  ),
  (feature: 'Incognito Mode', free: false, premium: false, premiumPlus: true),
  (feature: 'Priority Support', free: false, premium: true, premiumPlus: true),
  (
    feature: 'Voice Messages',
    free: false,
    premium: '10 / month',
    premiumPlus: 'Unlimited',
  ),
  (feature: 'Spotlight Badge', free: false, premium: false, premiumPlus: true),
];

String planDisplayName(SubscriptionPlan plan) {
  switch (plan) {
    case SubscriptionPlan.free:
      return 'Free';
    case SubscriptionPlan.premium:
      return 'Premium';
    case SubscriptionPlan.premiumPlus:
      return 'Premium Plus';
  }
}
