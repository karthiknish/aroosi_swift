import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/features/subscription/subscription_controller.dart';
import 'package:aroosi_flutter/features/subscription/subscription_features.dart';
import 'package:aroosi_flutter/features/subscription/subscription_models.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  SubscriptionPlan? _pendingPlan;

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(subscriptionControllerProvider);
    ref.listen(subscriptionControllerProvider, (previous, next) {
      if (previous?.error != next.error && next.error != null) {
        _showSnack(next.error!.message, type: ToastType.error);
      }
      if (previous?.isProcessingPurchase == true && !next.isProcessingPurchase) {
        if (next.error == null && _pendingPlan != null) {
          _showSnack('Subscription updated successfully.', type: ToastType.success);
        }
        _pendingPlan = null;
      }
    });

    final authState = ref.watch(authControllerProvider);
    final currentPlan = subscriptionState.status?.plan ??
        SubscriptionPlanX.fromId(authState.profile?.plan);
    final isBusy = subscriptionState.isInitializing || subscriptionState.isProcessingPurchase;

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: subscriptionState.isInitializing
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(subscriptionControllerProvider.notifier).loadProducts();
                await ref.read(subscriptionControllerProvider.notifier).refreshStatus();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _CurrentStatusCard(status: subscriptionState.status, fallbackPlan: currentPlan),
                  const SizedBox(height: 16),
                  ..._buildPlanCards(context, subscriptionState, currentPlan, isBusy),
                  const SizedBox(height: 24),
                  _buildManagementSection(subscriptionState, isBusy),
                  const SizedBox(height: 24),
                  _FeatureComparisonCard(plan: currentPlan ?? SubscriptionPlan.free),
                  const SizedBox(height: 24),
                  _buildTerms(),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildPlanCards(
    BuildContext context,
    SubscriptionState subscriptionState,
    SubscriptionPlan? currentPlan,
    bool isBusy,
  ) {
    final controller = ref.read(subscriptionControllerProvider.notifier);
    final List<Widget> cards = [];
    for (final entry in kDefaultPlanCatalog.entries) {
      final info = entry.value;
      final product = subscriptionState.products.firstWhere(
        (p) => p.plan == info.plan,
        orElse: () => SubscriptionProduct(
          productId: '',
          plan: info.plan,
          title: info.name,
          description: info.name,
          price: (amount: info.priceLabel, currency: '', localized: info.priceLabel),
          raw: null,
        ),
      );
      final isCurrent = currentPlan == info.plan && subscriptionState.status?.isActive == true;
      final isProductLoaded = product.raw != null;
      final isSelectable = info.plan != SubscriptionPlan.free && !isCurrent && !isBusy && isProductLoaded;
      final priceLabel = product.price.localized.isNotEmpty ? product.price.localized : info.priceLabel;
      cards.add(
        Card(
          color: isCurrent ? Theme.of(context).colorScheme.primaryContainer : null,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(info.name, style: Theme.of(context).textTheme.titleLarge),
                    if (info.popular) ...[
                      const SizedBox(width: 12),
                      Chip(
                        label: const Text('Popular'),
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      ),
                    ],
                    if (isCurrent) ...[
                      const SizedBox(width: 12),
                      Chip(
                        label: const Text('Current plan'),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(priceLabel, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 12),
                ...info.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 18, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(feature)),
                        ],
                      ),
                    )),
                if (!isProductLoaded && info.plan != SubscriptionPlan.free) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Product unavailable. Pull to refresh to retry.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ] else if (isSelectable) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      setState(() {
                        _pendingPlan = info.plan;
                      });
                      final result = await controller.purchasePlan(info.plan);
                      if (!mounted) return;
                      if (!result.success) {
                        if (result.error != null && result.error!.type != PurchaseErrorType.userCancel) {
                          _showSnack(result.error!.message, type: ToastType.error);
                        }
                      }
                    },
                    child: _pendingPlan == info.plan && subscriptionState.isProcessingPurchase
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('Processing...'),
                            ],
                          )
                        : Text('Choose ${info.name}'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Auto-renews monthly. Cancel anytime from your store account.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return cards;
  }

  Widget _buildManagementSection(SubscriptionState state, bool isBusy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: isBusy
              ? null
              : () async {
                  final restored = await ref.read(subscriptionControllerProvider.notifier).restorePurchases();
                  if (!mounted) return;
                  if (restored) {
                    _showSnack('Purchases restored.', type: ToastType.success);
                  } else {
                    _showSnack('No purchases to restore.');
                  }
                },
          child: Text(state.isProcessingPurchase ? 'Restoring…' : 'Restore Purchases'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => _openStoreSubscriptions(),
          child: const Text('Manage / Cancel Subscription'),
        ),
      ],
    );
  }

  Widget _buildTerms() {
    return Text(
      'Subscriptions renew automatically each month. Your App Store or Google Play account will be charged unless you cancel at least 24 hours before the renewal date.',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  void _showSnack(String message, {ToastType type = ToastType.info}) {
    switch (type) {
      case ToastType.success:
        ToastService.instance.success(message);
        return;
      case ToastType.warning:
        ToastService.instance.warning(message);
        return;
      case ToastType.error:
        ToastService.instance.error(message);
        return;
      case ToastType.info:
        ToastService.instance.info(message);
        return;
    }
  }

  Future<void> _openStoreSubscriptions() async {
    final uri = Platform.isIOS
        ? Uri.parse('itms-apps://apps.apple.com/account/subscriptions')
        : Uri.parse('https://play.google.com/store/account/subscriptions');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showSnack('Unable to open store subscriptions.', type: ToastType.error);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Unable to open store subscriptions.', type: ToastType.error);
    }
  }
}

class _CurrentStatusCard extends StatelessWidget {
  const _CurrentStatusCard({required this.status, this.fallbackPlan});

  final SubscriptionStatus? status;
  final SubscriptionPlan? fallbackPlan;

  @override
  Widget build(BuildContext context) {
    final plan = status?.plan ?? fallbackPlan ?? SubscriptionPlan.free;
    final info = kDefaultPlanCatalog[plan]!;
    final isActive = status?.isActive ?? false;
    final expiresLabel = status?.expiresAt != null ? _formatDate(status!.expiresAt!) : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Plan', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              info.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (isActive && expiresLabel != null) ...[
              const SizedBox(height: 8),
              Text('Renews on $expiresLabel'),
            ] else if (!isActive) ...[
              const SizedBox(height: 8),
              const Text('Upgrade to unlock more features.'),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _FeatureComparisonCard extends StatelessWidget {
  const _FeatureComparisonCard({required this.plan});

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan comparison', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Feature', style: theme.textTheme.labelLarge)),
                Expanded(
                  child: Text('Free',
                      style: _headerStyle(theme, plan == SubscriptionPlan.free),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text('Premium',
                      style: _headerStyle(theme, plan == SubscriptionPlan.premium),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text('Premium Plus',
                      style: _headerStyle(theme, plan == SubscriptionPlan.premiumPlus),
                      textAlign: TextAlign.center),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...kFeatureComparison.map((row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(row.feature)),
                      Expanded(child: _ComparisonValue(value: row.free, highlight: plan == SubscriptionPlan.free)),
                      Expanded(child: _ComparisonValue(value: row.premium, highlight: plan == SubscriptionPlan.premium)),
                      Expanded(child: _ComparisonValue(value: row.premiumPlus, highlight: plan == SubscriptionPlan.premiumPlus)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

TextStyle? _headerStyle(ThemeData theme, bool highlight) {
  final base = theme.textTheme.labelLarge;
  return highlight ? base?.copyWith(fontWeight: FontWeight.w700) : base;
}

class _ComparisonValue extends StatelessWidget {
  const _ComparisonValue({required this.value, this.highlight = false});

  final Object value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (value is bool) {
      final bool boolValue = value as bool;
      return Icon(
        boolValue ? Icons.check_circle : Icons.cancel,
    color: boolValue
      ? (highlight ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0.8))
            : theme.colorScheme.outline,
        size: 18,
      );
    }
    return Text(
      value.toString(),
      textAlign: TextAlign.center,
      style: (highlight
              ? theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)
              : theme.textTheme.bodySmall),
    );
  }
}
