import 'dart:io';

enum SubscriptionPlan { free, premium, premiumPlus }

typedef PlatformProductIds = ({String premium, String premiumPlus});

typedef StoreProductPrice = ({
  String amount,
  String currency,
  String localized,
});

class SubscriptionProduct {
  const SubscriptionProduct({
    required this.productId,
    required this.plan,
    required this.title,
    required this.description,
    required this.price,
    required this.raw,
  });

  final String productId;
  final SubscriptionPlan plan;
  final String title;
  final String description;
  final StoreProductPrice price;
  final Object? raw;
}

enum PurchaseErrorType {
  userCancel,
  paymentNotAllowed,
  paymentInvalid,
  productNotAvailable,
  networkError,
  securityError,
  validationFailed,
  alreadyOwned,
  notOwned,
  unknown,
}

class PurchaseError {
  const PurchaseError(this.type, this.message, {this.code, this.debugMessage});

  final PurchaseErrorType type;
  final String message;
  final String? code;
  final String? debugMessage;
}

class PurchaseResult {
  const PurchaseResult.success({
    required this.productId,
    required this.purchaseToken,
    required this.transactionId,
    this.receiptData,
  }) : success = true,
       error = null;

  const PurchaseResult.failure(this.error)
    : success = false,
      productId = null,
      purchaseToken = null,
      transactionId = null,
      receiptData = null;

  final bool success;
  final String? productId;
  final String? purchaseToken;
  final String? transactionId;
  final String? receiptData;
  final PurchaseError? error;
}

class SubscriptionStatus {
  const SubscriptionStatus({
    required this.plan,
    required this.isActive,
    this.expiresAt,
    this.autoRenewing,
    this.isTrialPeriod,
    this.productId,
    // Next.js API aligned fields
    this.daysRemaining,
    this.cancelAtPeriodEnd,
    this.isTrial,
    this.trialEndsAt,
    this.trialDaysRemaining,
    this.boostsRemaining,
    this.hasSpotlightBadge,
    this.spotlightBadgeExpiresAt,
    this.correlationId,
    // Legacy compatibility fields
    this.subscriptionPlan,
    this.subscriptionExpiresAt,
  });

  final SubscriptionPlan plan;
  final bool isActive;
  final DateTime? expiresAt;
  final bool? autoRenewing;
  final bool? isTrialPeriod;
  final String? productId;
  
  // Next.js API aligned fields
  final int? daysRemaining;
  final bool? cancelAtPeriodEnd;
  final bool? isTrial;
  final DateTime? trialEndsAt;
  final int? trialDaysRemaining;
  final int? boostsRemaining;
  final bool? hasSpotlightBadge;
  final DateTime? spotlightBadgeExpiresAt;
  final String? correlationId;
  
  // Legacy compatibility fields
  final String? subscriptionPlan;
  final DateTime? subscriptionExpiresAt;

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      plan:
          SubscriptionPlanX.fromId(json['plan']?.toString()) ??
          SubscriptionPlan.free,
      isActive: json['isActive'] as bool? ?? json['active'] as bool? ?? false,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      autoRenewing: json['autoRenewing'] as bool?,
      isTrialPeriod: json['isTrialPeriod'] as bool?,
      productId: json['productId'] as String?,
      // Next.js API aligned fields
      daysRemaining: json['daysRemaining'] as int?,
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] as bool?,
      isTrial: json['isTrial'] as bool?,
      trialEndsAt: json['trialEndsAt'] != null
          ? DateTime.tryParse(json['trialEndsAt'].toString())
          : null,
      trialDaysRemaining: json['trialDaysRemaining'] as int?,
      boostsRemaining: json['boostsRemaining'] as int?,
      hasSpotlightBadge: json['hasSpotlightBadge'] as bool?,
      spotlightBadgeExpiresAt: json['spotlightBadgeExpiresAt'] != null
          ? DateTime.tryParse(json['spotlightBadgeExpiresAt'].toString())
          : null,
      correlationId: json['correlationId'] as String?,
      // Legacy compatibility fields
      subscriptionPlan: json['subscriptionPlan'] as String?,
      subscriptionExpiresAt: json['subscriptionExpiresAt'] != null
          ? DateTime.tryParse(json['subscriptionExpiresAt'].toString())
          : null,
    );
  }

  SubscriptionStatus copyWith({
    SubscriptionPlan? plan,
    bool? isActive,
    DateTime? expiresAt,
    bool? autoRenewing,
    bool? isTrialPeriod,
    String? productId,
    // Next.js API aligned fields
    int? daysRemaining,
    bool? cancelAtPeriodEnd,
    bool? isTrial,
    DateTime? trialEndsAt,
    int? trialDaysRemaining,
    int? boostsRemaining,
    bool? hasSpotlightBadge,
    DateTime? spotlightBadgeExpiresAt,
    String? correlationId,
    // Legacy compatibility fields
    String? subscriptionPlan,
    DateTime? subscriptionExpiresAt,
  }) {
    return SubscriptionStatus(
      plan: plan ?? this.plan,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      autoRenewing: autoRenewing ?? this.autoRenewing,
      isTrialPeriod: isTrialPeriod ?? this.isTrialPeriod,
      productId: productId ?? this.productId,
      // Next.js API aligned fields
      daysRemaining: daysRemaining ?? this.daysRemaining,
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
      isTrial: isTrial ?? this.isTrial,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      trialDaysRemaining: trialDaysRemaining ?? this.trialDaysRemaining,
      boostsRemaining: boostsRemaining ?? this.boostsRemaining,
      hasSpotlightBadge: hasSpotlightBadge ?? this.hasSpotlightBadge,
      spotlightBadgeExpiresAt: spotlightBadgeExpiresAt ?? this.spotlightBadgeExpiresAt,
      correlationId: correlationId ?? this.correlationId,
      // Legacy compatibility fields
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
    );
  }
}

class SubscriptionState {
  const SubscriptionState({
    this.isInitializing = true,
    this.isAvailable = false,
    this.isLoadingProducts = false,
    this.isProcessingPurchase = false,
    this.products = const [],
    this.status,
    this.error,
  });

  final bool isInitializing;
  final bool isAvailable;
  final bool isLoadingProducts;
  final bool isProcessingPurchase;
  final List<SubscriptionProduct> products;
  final SubscriptionStatus? status;
  final PurchaseError? error;

  SubscriptionState copyWith({
    bool? isInitializing,
    bool? isAvailable,
    bool? isLoadingProducts,
    bool? isProcessingPurchase,
    List<SubscriptionProduct>? products,
    SubscriptionStatus? status,
    PurchaseError? error,
    bool setError = false,
  }) {
    return SubscriptionState(
      isInitializing: isInitializing ?? this.isInitializing,
      isAvailable: isAvailable ?? this.isAvailable,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      isProcessingPurchase: isProcessingPurchase ?? this.isProcessingPurchase,
      products: products ?? this.products,
      status: status ?? this.status,
      error: setError ? error : this.error,
    );
  }
}

extension SubscriptionPlanX on SubscriptionPlan {
  String get id {
    switch (this) {
      case SubscriptionPlan.free:
        return 'free';
      case SubscriptionPlan.premium:
        return 'premium';
      case SubscriptionPlan.premiumPlus:
        return 'premiumPlus';
    }
  }

  static SubscriptionPlan? fromId(String? value) {
    switch (value) {
      case 'free':
        return SubscriptionPlan.free;
      case 'premium':
        return SubscriptionPlan.premium;
      case 'premiumPlus':
      case 'premium_plus':
        return SubscriptionPlan.premiumPlus;
      default:
        return null;
    }
  }
}

class SubscriptionPlanInfo {
  const SubscriptionPlanInfo({
    required this.plan,
    required this.name,
    required this.priceLabel,
    required this.features,
    this.popular = false,
  });

  final SubscriptionPlan plan;
  final String name;
  final String priceLabel;
  final List<String> features;
  final bool popular;
}

const Map<SubscriptionPlan, SubscriptionPlanInfo> kDefaultPlanCatalog = {
  SubscriptionPlan.free: SubscriptionPlanInfo(
    plan: SubscriptionPlan.free,
    name: 'Free',
    priceLabel: 'PKR 0',
    features: ['Browse profiles', 'Basic search filters', 'Chat with matches'],
  ),
  SubscriptionPlan.premium: SubscriptionPlanInfo(
    plan: SubscriptionPlan.premium,
    name: 'Premium',
    priceLabel: 'PKR 1,499 / month',
    features: [
      'Unlimited interests',
      'Advanced search filters',
      'See who liked your profile',
      'Priority support',
    ],
    popular: true,
  ),
  SubscriptionPlan.premiumPlus: SubscriptionPlanInfo(
    plan: SubscriptionPlan.premiumPlus,
    name: 'Premium Plus',
    priceLabel: 'PKR 2,999 / month',
    features: [
      'All Premium features',
      'Boosted profile visibility',
      'Concierge matchmaking support',
    ],
  ),
};

class SubscriptionConfig {
  const SubscriptionConfig._();

  static const PlatformProductIds ios = (
    premium: 'com.aroosi.premium.monthly',
    premiumPlus: 'com.aroosi.premiumplus.monthly',
  );

  static const PlatformProductIds android = (
    premium: 'premium',
    premiumPlus: 'premiumplus',
  );

  static PlatformProductIds get currentPlatformIds {
    if (Platform.isIOS) return ios;
    return android;
  }

  static String? productIdForPlan(SubscriptionPlan plan) {
    final ids = currentPlatformIds;
    switch (plan) {
      case SubscriptionPlan.premium:
        return ids.premium;
      case SubscriptionPlan.premiumPlus:
        return ids.premiumPlus;
      case SubscriptionPlan.free:
        return null;
    }
  }
}

class FeatureUsageItem {
  const FeatureUsageItem({
    required this.name,
    required this.used,
    required this.limit,
    required this.unlimited,
    required this.remaining,
    required this.percentageUsed,
  });

  final String name;
  final int used;
  final int limit;
  final bool unlimited;
  final int remaining;
  final double percentageUsed;

  factory FeatureUsageItem.fromJson(Map<String, dynamic> json) {
    return FeatureUsageItem(
      name: json['name'] as String,
      used: json['used'] as int,
      limit: json['limit'] as int,
      unlimited: json['unlimited'] as bool,
      remaining: json['remaining'] as int,
      percentageUsed: (json['percentageUsed'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class FeatureLimits {
  const FeatureLimits({
    required this.messagesSent,
    required this.interestsSent,
    required this.searchesPerformed,
    required this.profileBoosts,
    required this.profileViews,
    required this.dailyLikes,
    // Legacy names for backward compatibility
    required this.maxMessages,
    required this.maxInterests,
    required this.maxProfileViews,
    required this.maxSearches,
    required this.maxProfileBoosts,
    // Feature access limits
    this.canBoostProfile,
    this.canUseAdvancedFilters,
    this.canSeeWhoViewedProfile,
    this.canSeeReadReceipts,
    this.canViewWhoLikedMe,
    this.canUseIncognitoMode,
    this.canAccessPrioritySupport,
  });

  final int messagesSent;
  final int interestsSent;
  final int searchesPerformed;
  final int profileBoosts;
  final int profileViews;
  final int dailyLikes;
  // Legacy names for backward compatibility
  final int maxMessages;
  final int maxInterests;
  final int maxProfileViews;
  final int maxSearches;
  final int maxProfileBoosts;
  // Feature access limits
  final int? canBoostProfile;
  final int? canUseAdvancedFilters;
  final int? canSeeWhoViewedProfile;
  final int? canSeeReadReceipts;
  final int? canViewWhoLikedMe;
  final int? canUseIncognitoMode;
  final int? canAccessPrioritySupport;

  factory FeatureLimits.fromJson(Map<String, dynamic> json) {
    return FeatureLimits(
      messagesSent: json['messagesSent'] as int? ?? json['maxMessages'] as int? ?? 0,
      interestsSent: json['interestsSent'] as int? ?? json['maxInterests'] as int? ?? 0,
      searchesPerformed: json['searchesPerformed'] as int? ?? json['maxSearches'] as int? ?? 0,
      profileBoosts: json['profileBoosts'] as int? ?? json['maxProfileBoosts'] as int? ?? 0,
      profileViews: json['profileViews'] as int? ?? json['maxProfileViews'] as int? ?? 0,
      dailyLikes: json['dailyLikes'] as int? ?? 0,
      // Legacy names for backward compatibility
      maxMessages: json['maxMessages'] as int? ?? 0,
      maxInterests: json['maxInterests'] as int? ?? 0,
      maxProfileViews: json['maxProfileViews'] as int? ?? 0,
      maxSearches: json['maxSearches'] as int? ?? 0,
      maxProfileBoosts: json['maxProfileBoosts'] as int? ?? 0,
      // Feature access limits
      canBoostProfile: json['canBoostProfile'] as int?,
      canUseAdvancedFilters: json['canUseAdvancedFilters'] as int?,
      canSeeWhoViewedProfile: json['canSeeWhoViewedProfile'] as int?,
      canSeeReadReceipts: json['canSeeReadReceipts'] as int?,
      canViewWhoLikedMe: json['canViewWhoLikedMe'] as int?,
      canUseIncognitoMode: json['canUseIncognitoMode'] as int?,
      canAccessPrioritySupport: json['canAccessPrioritySupport'] as int?,
    );
  }
}

class FeatureUsage {
  const FeatureUsage({
    required this.plan,
    required this.currentMonth,
    required this.resetDate,
    required this.features,
    required this.periodStart,
    required this.periodEnd,
    required this.messagesSent,
    required this.interestsSent,
    required this.searchesPerformed,
    required this.profileBoosts,
    required this.limits,
    // Legacy format for backward compatibility
    required this.messaging,
    required this.profileViews,
    required this.searches,
    required this.boosts,
  });

  final SubscriptionPlan plan;
  final String currentMonth;
  final DateTime resetDate;
  final List<FeatureUsageItem> features;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int messagesSent;
  final int interestsSent;
  final int searchesPerformed;
  final int profileBoosts;
  final FeatureLimits limits;
  // Legacy format for backward compatibility
  final MessagingUsage messaging;
  final ProfileViewsUsage profileViews;
  final SearchesUsage searches;
  final BoostsUsage boosts;

  factory FeatureUsage.fromJson(Map<String, dynamic> json) {
    return FeatureUsage(
      plan: SubscriptionPlanX.fromId(json['plan']?.toString()) ?? SubscriptionPlan.free,
      currentMonth: json['currentMonth'] as String,
      resetDate: json['resetDate'] != null ? DateTime.fromMillisecondsSinceEpoch(json['resetDate'] as int) : DateTime.now(),
      features: (json['features'] as List?)?.map((e) => FeatureUsageItem.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      periodStart: json['periodStart'] != null ? DateTime.fromMillisecondsSinceEpoch(json['periodStart'] as int) : DateTime.now(),
      periodEnd: json['periodEnd'] != null ? DateTime.fromMillisecondsSinceEpoch(json['periodEnd'] as int) : DateTime.now(),
      messagesSent: json['messagesSent'] as int? ?? 0,
      interestsSent: json['interestsSent'] as int? ?? 0,
      searchesPerformed: json['searchesPerformed'] as int? ?? 0,
      profileBoosts: json['profileBoosts'] as int? ?? 0,
      limits: FeatureLimits.fromJson(json['limits'] as Map<String, dynamic>),
      // Legacy format for backward compatibility
      messaging: MessagingUsage.fromJson(json['messaging'] as Map<String, dynamic>? ?? {}),
      profileViews: ProfileViewsUsage.fromJson(json['profileViews'] as Map<String, dynamic>? ?? {}),
      searches: SearchesUsage.fromJson(json['searches'] as Map<String, dynamic>? ?? {}),
      boosts: BoostsUsage.fromJson(json['boosts'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class MessagingUsage {
  const MessagingUsage({
    required this.sent,
    required this.limit,
  });

  final int sent;
  final int limit;

  factory MessagingUsage.fromJson(Map<String, dynamic> json) {
    return MessagingUsage(
      sent: json['sent'] as int? ?? 0,
      limit: json['limit'] as int? ?? 0,
    );
  }
}

class ProfileViewsUsage {
  const ProfileViewsUsage({
    required this.count,
    required this.limit,
  });

  final int count;
  final int limit;

  factory ProfileViewsUsage.fromJson(Map<String, dynamic> json) {
    return ProfileViewsUsage(
      count: json['count'] as int? ?? 0,
      limit: json['limit'] as int? ?? 0,
    );
  }
}

class SearchesUsage {
  const SearchesUsage({
    required this.count,
    required this.limit,
  });

  final int count;
  final int limit;

  factory SearchesUsage.fromJson(Map<String, dynamic> json) {
    return SearchesUsage(
      count: json['count'] as int? ?? 0,
      limit: json['limit'] as int? ?? 0,
    );
  }
}

class BoostsUsage {
  const BoostsUsage({
    required this.used,
    required this.monthlyLimit,
  });

  final int used;
  final int monthlyLimit;

  factory BoostsUsage.fromJson(Map<String, dynamic> json) {
    return BoostsUsage(
      used: json['used'] as int? ?? 0,
      monthlyLimit: json['monthlyLimit'] as int? ?? 0,
    );
  }
}

class FeatureAvailabilityResult {
  const FeatureAvailabilityResult({
    required this.canUse,
    this.reason,
    this.requiredPlan,
    this.message,
  });

  final bool canUse;
  final String? reason;
  final SubscriptionPlan? requiredPlan;
  final String? message;

  factory FeatureAvailabilityResult.fromJson(Map<String, dynamic> json) {
    final requiredPlanId = json['requiredPlan'] ?? json['requiredTier'];
    return FeatureAvailabilityResult(
      canUse: json['canUse'] == true,
      reason: json['reason']?.toString(),
      requiredPlan: SubscriptionPlanX.fromId(requiredPlanId?.toString()),
      message: json['message']?.toString(),
    );
  }
}
