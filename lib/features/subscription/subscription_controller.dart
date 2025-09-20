import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import 'subscription_models.dart';
import 'subscription_repository.dart';

final subscriptionControllerProvider =
    NotifierProvider<SubscriptionController, SubscriptionState>(
      SubscriptionController.new,
    );

class SubscriptionController extends Notifier<SubscriptionState> {
  SubscriptionController() : _iap = InAppPurchase.instance;

  final InAppPurchase _iap;
  final SubscriptionRepository _repository = SubscriptionRepository();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Completer<PurchaseResult>? _activePurchase;
  Completer<bool>? _restoreCompleter;
  Timer? _statusRefreshTimer;

  @override
  SubscriptionState build() {
    _init();
    // Ensure resources are cleaned up when the provider is disposed
    ref.onDispose(() {
      _purchaseSub?.cancel();
      _statusRefreshTimer?.cancel();
      if (_activePurchase != null && !(_activePurchase?.isCompleted ?? true)) {
        _activePurchase?.complete(
          const PurchaseResult.failure(
            PurchaseError(PurchaseErrorType.unknown, 'Controller disposed'),
          ),
        );
      }
      _activePurchase = null;
      _restoreCompleter?.complete(false);
      _restoreCompleter = null;
    });
    return const SubscriptionState();
  }

  Future<void> _init() async {
    if (Platform.isIOS) {
      InAppPurchaseStoreKitPlatform.registerPlatform();
    }
    final available = await _iap.isAvailable();
    state = state.copyWith(
      isInitializing: false,
      isAvailable: available,
      error: available
          ? null
          : const PurchaseError(
              PurchaseErrorType.productNotAvailable,
              'In-app purchases unavailable',
            ),
      setError: true,
    );

    if (!available) {
      return;
    }

    await Future.wait([loadProducts(), refreshStatus()]);

    _purchaseSub ??= _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        final mapped = _mapError(error);
        _completeActive(PurchaseResult.failure(mapped));
      },
    );

    // Start periodic status refresh for real-time updates
    _startPeriodicStatusRefresh();
  }

  Future<void> refreshStatus() async {
    final status = await _repository.fetchStatus();
    if (status != null) {
      state = state.copyWith(status: status);
    }
  }

  void _startPeriodicStatusRefresh() {
    // Refresh status every 5 minutes for real-time updates
    _statusRefreshTimer?.cancel();
    _statusRefreshTimer = Timer.periodic(const Duration(minutes: 5), (
      timer,
    ) async {
      if (!state.isProcessingPurchase) {
        await refreshStatus();
      }
    });
  }

  Future<void> forceStatusRefresh() async {
    await refreshStatus();
    // Restart the periodic timer
    _startPeriodicStatusRefresh();
  }

  Future<void> loadProducts() async {
    final ids = <String>{};
    final premium = SubscriptionConfig.productIdForPlan(
      SubscriptionPlan.premium,
    );
    final premiumPlus = SubscriptionConfig.productIdForPlan(
      SubscriptionPlan.premiumPlus,
    );
    if (premium != null) ids.add(premium);
    if (premiumPlus != null) ids.add(premiumPlus);
    if (ids.isEmpty) return;

    state = state.copyWith(
      isLoadingProducts: true,
      error: null,
      setError: true,
    );
    final response = await _iap.queryProductDetails(ids);
    if (response.error != null) {
      state = state.copyWith(
        isLoadingProducts: false,
        error: _mapIapError(response.error!),
        setError: true,
      );
      return;
    }

    final products = response.productDetails.map((detail) {
      final plan =
          SubscriptionPlanX.fromId(_planFromProductId(detail.id)) ??
          SubscriptionPlan.premium;
      return SubscriptionProduct(
        productId: detail.id,
        plan: plan,
        title: detail.title,
        description: detail.description,
        price: (
          amount: detail.price,
          currency: detail.currencyCode,
          localized: detail.price,
        ),
        raw: detail,
      );
    }).toList();

    state = state.copyWith(isLoadingProducts: false, products: products);
  }

  Future<PurchaseResult> purchasePlan(SubscriptionPlan plan) async {
    final productId = SubscriptionConfig.productIdForPlan(plan);
    if (productId == null) {
      return const PurchaseResult.failure(
        PurchaseError(
          PurchaseErrorType.productNotAvailable,
          'No product configured for this plan',
        ),
      );
    }

    SubscriptionProduct? product;
    for (final p in state.products) {
      if (p.productId == productId) {
        product = p;
        break;
      }
    }
    if (product == null || product.raw is! ProductDetails) {
      return const PurchaseResult.failure(
        PurchaseError(
          PurchaseErrorType.productNotAvailable,
          'Product information not loaded',
        ),
      );
    }

    if (_activePurchase != null && !(_activePurchase?.isCompleted ?? true)) {
      return const PurchaseResult.failure(
        PurchaseError(
          PurchaseErrorType.unknown,
          'Another purchase is in progress',
        ),
      );
    }

    _activePurchase = Completer<PurchaseResult>();
    state = state.copyWith(
      isProcessingPurchase: true,
      error: null,
      setError: true,
    );

    final success = await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: product.raw as ProductDetails,
      ),
    );

    if (!success) {
      final error = const PurchaseError(
        PurchaseErrorType.unknown,
        'Unable to start purchase flow',
      );
      state = state.copyWith(
        isProcessingPurchase: false,
        error: error,
        setError: true,
      );
      final result = PurchaseResult.failure(error);
      _activePurchase?.complete(result);
      _activePurchase = null;
      return result;
    }

    return _activePurchase!.future;
  }

  Future<bool> restorePurchases() async {
    if (state.isProcessingPurchase) {
      return false;
    }

    state = state.copyWith(
      isProcessingPurchase: true,
      error: null,
      setError: true,
    );
    _restoreCompleter = Completer<bool>();

    try {
      // IAP 3.x restorePurchases returns Future<void>. Await and then rely on
      // purchaseStream callbacks to complete the restore flow.
      await _iap.restorePurchases();

      // Set a timeout for the restore operation
      Timer(const Duration(seconds: 10), () {
        if (_restoreCompleter != null && !(_restoreCompleter!.isCompleted)) {
          logApi('⚠️ Restore purchases timed out after 10 seconds');
          state = state.copyWith(
            isProcessingPurchase: false,
            error: const PurchaseError(
              PurchaseErrorType.unknown,
              'Restore operation timed out',
            ),
            setError: true,
          );
          _restoreCompleter?.complete(false);
          _restoreCompleter = null;
        }
      });
    } catch (e) {
      state = state.copyWith(
        isProcessingPurchase: false,
        error: _mapError(e),
        setError: true,
      );
      _restoreCompleter?.complete(false);
      _restoreCompleter = null;
    }

    return _restoreCompleter!.future;
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        continue;
      }
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _validateAndFinish(purchase);
        continue;
      }
      // Treat anything else as an error/cancel flow.
      final err = purchase.error != null
          ? _mapIapError(purchase.error!)
          : const PurchaseError(
              PurchaseErrorType.unknown,
              'Purchase cancelled',
            );
      _finish(purchase, success: false, error: err);
    }
  }

  Future<void> _validateAndFinish(PurchaseDetails purchase) async {
    final productId = purchase.productID;
    final platform = Platform.isIOS ? 'ios' : 'android';
    final receipt = purchase.verificationData.serverVerificationData;
    final purchaseToken = Platform.isIOS
        ? receipt
        : purchase.verificationData.serverVerificationData;

    // Use robust validation with retry mechanism
    final ok = await _repository.validatePurchaseWithRetry(
      platform: platform,
      productId: productId,
      purchaseToken: purchaseToken,
      receiptData: Platform.isIOS ? receipt : null,
      maxRetries: 3,
      retryDelay: const Duration(seconds: 2),
    );

    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }

    if (ok) {
      await refreshStatus();
      state = state.copyWith(
        isProcessingPurchase: false,
        error: null,
        setError: true,
      );
      final result = PurchaseResult.success(
        productId: productId,
        purchaseToken: purchaseToken,
        transactionId:
            purchase.purchaseID ?? purchase.transactionDate?.toString() ?? '',
        receiptData: Platform.isIOS ? receipt : null,
      );
      _completeActive(result);
      _restoreCompleter?.complete(true);
      _restoreCompleter = null;
    } else {
      const error = PurchaseError(
        PurchaseErrorType.validationFailed,
        'Purchase validation failed after retries',
      );
      state = state.copyWith(
        isProcessingPurchase: false,
        error: error,
        setError: true,
      );
      _completeActive(const PurchaseResult.failure(error));
      _restoreCompleter?.complete(false);
      _restoreCompleter = null;
    }
  }

  void _finish(
    PurchaseDetails purchase, {
    required bool success,
    PurchaseError? error,
  }) {
    if (purchase.pendingCompletePurchase) {
      _iap.completePurchase(purchase);
    }
    state = state.copyWith(
      isProcessingPurchase: false,
      error: error,
      setError: true,
    );
    if (success) {
      final result = PurchaseResult.success(
        productId: purchase.productID,
        purchaseToken: purchase.verificationData.serverVerificationData,
        transactionId:
            purchase.purchaseID ?? purchase.transactionDate?.toString() ?? '',
        receiptData: Platform.isIOS
            ? purchase.verificationData.serverVerificationData
            : null,
      );
      _completeActive(result);
    } else {
      _completeActive(
        PurchaseResult.failure(
          error ??
              const PurchaseError(PurchaseErrorType.unknown, 'Purchase failed'),
        ),
      );
      _restoreCompleter?.complete(false);
      _restoreCompleter = null;
    }
  }

  void _completeActive(PurchaseResult result) {
    if (_activePurchase != null && !(_activePurchase?.isCompleted ?? true)) {
      _activePurchase?.complete(result);
    }
    _activePurchase = null;
  }

  PurchaseError _mapError(Object error) {
    if (error is IAPError) {
      return _mapIapError(error);
    }
    return const PurchaseError(
      PurchaseErrorType.unknown,
      'Unexpected purchase error',
    );
  }

  PurchaseError _mapIapError(IAPError error) {
    final code = error.code.toLowerCase();
    if (code.contains('canceled') || code.contains('cancelled')) {
      return PurchaseError(
        PurchaseErrorType.userCancel,
        error.message,
        code: error.code,
      );
    }
    if (code.contains('item_unavailable')) {
      return PurchaseError(
        PurchaseErrorType.productNotAvailable,
        error.message,
        code: error.code,
      );
    }
    if (code.contains('network')) {
      return PurchaseError(
        PurchaseErrorType.networkError,
        error.message,
        code: error.code,
      );
    }
    if (code.contains('billing_unavailable')) {
      return PurchaseError(
        PurchaseErrorType.paymentNotAllowed,
        error.message,
        code: error.code,
      );
    }
    return PurchaseError(
      PurchaseErrorType.unknown,
      error.message,
      code: error.code,
    );
  }

  String _planFromProductId(String productId) {
    final ids = SubscriptionConfig.currentPlatformIds;
    if (productId == ids.premiumPlus) return 'premiumPlus';
    if (productId == ids.premium) return 'premium';
    return productId;
  }

  Future<bool> refreshSubscription() async {
    try {
      final success = await _repository.refreshSubscription();
      if (success) {
        await refreshStatus();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        error: PurchaseError(
          PurchaseErrorType.networkError,
          'Failed to refresh subscription',
        ),
        setError: true,
      );
      return false;
    }
  }

  Future<bool> cancelSubscription() async {
    try {
      final success = await _repository.cancelSubscription();
      if (success) {
        await refreshStatus();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        error: PurchaseError(
          PurchaseErrorType.networkError,
          'Failed to cancel subscription',
        ),
        setError: true,
      );
      return false;
    }
  }

  Future<Map<String, dynamic>?> getFeatures() async {
    try {
      return await _repository.getFeatures();
    } catch (e) {
      state = state.copyWith(
        error: PurchaseError(
          PurchaseErrorType.networkError,
          'Failed to fetch features',
        ),
        setError: true,
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUsageHistory() async {
    try {
      return await _repository.getUsageHistory();
    } catch (e) {
      state = state.copyWith(
        error: PurchaseError(
          PurchaseErrorType.networkError,
          'Failed to fetch usage history',
        ),
        setError: true,
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> getBoostQuota() async {
    try {
      return await _repository.getBoostQuota();
    } catch (e) {
      state = state.copyWith(
        error: PurchaseError(
          PurchaseErrorType.networkError,
          'Failed to fetch boost quota',
        ),
        setError: true,
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> getVoiceQuota() async {
    try {
      return await _repository.getVoiceQuota();
    } catch (e) {
      state = state.copyWith(
        error: PurchaseError(
          PurchaseErrorType.networkError,
          'Failed to fetch voice quota',
        ),
        setError: true,
      );
      return null;
    }
  }

  Future<bool> updateSubscriptionStatus(Map<String, dynamic> statusData) async {
    try {
      final success = await _repository.updateSubscriptionStatus(statusData);
      if (success) {
        await refreshStatus();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        error: PurchaseError(
          PurchaseErrorType.networkError,
          'Failed to update subscription status',
        ),
        setError: true,
      );
      return false;
    }
  }

  Future<bool> manageSubscription() async {
    try {
      // For iOS, we can open the subscription management URL
      if (Platform.isIOS) {
        // This would typically open the App Store subscription management
        // For now, we'll just refresh the status
        await refreshStatus();
        return true;
      }

      // For Android, we would open Google Play subscription management
      // For now, we'll just refresh the status
      await refreshStatus();
      return true;
    } catch (e) {
      state = state.copyWith(
        error: PurchaseError(
          PurchaseErrorType.unknown,
          'Failed to open subscription management',
        ),
        setError: true,
      );
      return false;
    }
  }

  Future<bool> checkPurchaseHistory() async {
    try {
      // This would typically check the purchase history from the store
      // For now, we'll just trigger a restore
      return await restorePurchases();
    } catch (e) {
      state = state.copyWith(
        error: PurchaseError(
          PurchaseErrorType.unknown,
          'Failed to check purchase history',
        ),
        setError: true,
      );
      return false;
    }
  }

  Future<bool> validateCurrentSubscription() async {
    try {
      final currentStatus = state.status;
      if (currentStatus == null || !currentStatus.isActive) {
        return false;
      }

      // If we have a product ID, try to validate the current subscription
      if (currentStatus.productId != null) {
        final platform = Platform.isIOS ? 'ios' : 'android';
        final success = await _repository.validatePurchaseWithRetry(
          platform: platform,
          productId: currentStatus.productId!,
          purchaseToken: 'current', // This would be the actual purchase token
          maxRetries: 2,
        );

        if (!success) {
          // If validation fails, refresh status to get updated information
          await refreshStatus();
          return false;
        }
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        error: PurchaseError(
          PurchaseErrorType.validationFailed,
          'Failed to validate current subscription',
        ),
        setError: true,
      );
      return false;
    }
  }

  void logApi(String message) {
    // Simple logging method for API operations
    debugPrint('[SubscriptionController] $message');
  }

  // Cleanup handled via ref.onDispose in build()
}
