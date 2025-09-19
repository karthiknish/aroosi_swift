import 'package:flutter/material.dart';
import 'package:aroosi_flutter/features/subscription/subscription_features.dart';

class PremiumFeaturesGrid extends StatelessWidget {
  const PremiumFeaturesGrid({
    super.key,
    required this.features,
    required this.onUpgrade,
  });
  final SubscriptionFeatures features;
  final VoidCallback onUpgrade;
  @override
  Widget build(BuildContext context) {
    final items = [
      PremiumFeatureItem(
        'Advanced Search Filters',
        Icons.filter_alt,
        features.canUseAdvancedFilters,
      ),
      PremiumFeatureItem(
        'See Who Viewed You',
        Icons.visibility,
        features.canViewProfileViewers,
      ),
      PremiumFeatureItem(
        'Read Receipts',
        Icons.done_all,
        features.canSeeReadReceipts,
      ),
      PremiumFeatureItem(
        'See Who Liked You',
        Icons.favorite,
        features.canViewProfileViewers,
      ),
      PremiumFeatureItem(
        'Incognito Mode',
        Icons.visibility_off,
        features.canUseIncognitoMode,
      ),
      PremiumFeatureItem(
        'Priority Support',
        Icons.headset_mic,
        features.canAccessPrioritySupport,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Premium Features',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return PremiumFeatureCard(
              title: item.title,
              icon: item.icon,
              available: item.available,
              onUpgrade: onUpgrade,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class PremiumFeatureItem {
  const PremiumFeatureItem(this.title, this.icon, this.available);
  final String title;
  final IconData icon;
  final bool available;
}

class PremiumFeatureCard extends StatelessWidget {
  const PremiumFeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.available,
    required this.onUpgrade,
  });
  final String title;
  final IconData icon;
  final bool available;
  final VoidCallback onUpgrade;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: available ? Colors.green.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
        border: available
            ? null
            : Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: available ? Colors.green : Colors.grey),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: available ? Colors.green : Colors.grey),
          ),
          if (!available)
            TextButton(onPressed: onUpgrade, child: const Text('Upgrade')),
        ],
      ),
    );
  }
}
