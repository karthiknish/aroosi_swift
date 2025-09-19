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
        'Find your perfect match with advanced filters',
      ),
      PremiumFeatureItem(
        'See Who Viewed You',
        Icons.visibility,
        features.canViewProfileViewers,
        'Know who checked out your profile',
      ),
      PremiumFeatureItem(
        'Read Receipts',
        Icons.done_all,
        features.canSeeReadReceipts,
        'See when your messages are read',
      ),
      PremiumFeatureItem(
        'See Who Liked You',
        Icons.favorite,
        features.canViewProfileViewers,
        'Discover who showed interest in you',
      ),
      PremiumFeatureItem(
        'Incognito Mode',
        Icons.visibility_off,
        features.canUseIncognitoMode,
        'Browse profiles without being seen',
      ),
      PremiumFeatureItem(
        'Priority Support',
        Icons.headset_mic,
        features.canAccessPrioritySupport,
        'Get priority customer support',
      ),
    ];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Premium Features',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return PremiumFeatureCard(
                title: item.title,
                icon: item.icon,
                available: item.available,
                description: item.description,
                onUpgrade: onUpgrade,
              );
            },
          ),
        ],
      ),
    );
  }
}

class PremiumFeatureItem {
  const PremiumFeatureItem(this.title, this.icon, this.available, this.description);
  final String title;
  final IconData icon;
  final bool available;
  final String description;
}

class PremiumFeatureCard extends StatelessWidget {
  const PremiumFeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.available,
    required this.description,
    required this.onUpgrade,
  });
  final String title;
  final IconData icon;
  final bool available;
  final String description;
  final VoidCallback onUpgrade;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: available ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: available ? Colors.green.shade200 : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: available ? null : onUpgrade,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: available 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: available ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: available ? Colors.green.shade800 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 11,
                            color: available ? Colors.green.shade600 : Colors.grey.shade600,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!available) ...[
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Upgrade',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ] else ...[
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Available',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
