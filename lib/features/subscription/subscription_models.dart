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
  });

  final SubscriptionPlan plan;
  final bool isActive;
  final DateTime? expiresAt;
  final bool? autoRenewing;
  final bool? isTrialPeriod;
  final String? productId;

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
    );
  }

  SubscriptionStatus copyWith({
    SubscriptionPlan? plan,
    bool? isActive,
    DateTime? expiresAt,
    bool? autoRenewing,
    bool? isTrialPeriod,
    String? productId,
  }) {
    return SubscriptionStatus(
      plan: plan ?? this.plan,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      autoRenewing: autoRenewing ?? this.autoRenewing,
      isTrialPeriod: isTrialPeriod ?? this.isTrialPeriod,
      productId: productId ?? this.productId,
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

class FeatureAvailabilityResult {
  const FeatureAvailabilityResult({
    required this.canUse,
    this.reason,
    this.requiredPlan,
  });

  final bool canUse;
  final String? reason;
  final SubscriptionPlan? requiredPlan;

  factory FeatureAvailabilityResult.fromJson(Map<String, dynamic> json) {
    final requiredPlanId = json['requiredPlan'] ?? json['requiredTier'];
    return FeatureAvailabilityResult(
      canUse: json['canUse'] == true,
      reason: json['reason']?.toString(),
      requiredPlan: SubscriptionPlanX.fromId(requiredPlanId?.toString()),
    );
  }
}
