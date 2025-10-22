import 'package:flutter/material.dart';

import 'package:aroosi_flutter/theme/colors.dart';

/// Traditional insights card for Afghan matchmaking guidance
class TraditionalInsightsCard extends StatelessWidget {
  const TraditionalInsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      color: AppColors.primary.withAlpha(13),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_edu, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Traditional Afghan Matchmaking',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              context,
              'Family Involvement',
              'In traditional Afghan culture, family approval is essential. Consider involving elders in the decision-making process.',
              Icons.family_restroom,
            ),
            const SizedBox(height: 8),
            _buildInsightItem(
              context,
              'Respectful Courtship',
              'Traditional Afghan courtship values modesty and patience. Take time to build trust through respectful communication.',
              Icons.handshake,
            ),
            const SizedBox(height: 8),
            _buildInsightItem(
              context,
              'Cultural Compatibility',
              'Shared cultural values, language, and traditions form the foundation of lasting relationships in Afghan culture.',
              Icons.diversity_3,
            ),
            const SizedBox(height: 8),
            _buildInsightItem(
              context,
              'Religious Considerations',
              'Religious alignment and practice levels are important factors in traditional Afghan matchmaking.',
              Icons.mosque,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// Modern insights card for contemporary Afghan dating guidance
class ModernInsightsCard extends StatelessWidget {
  const ModernInsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      color: AppColors.secondary.withAlpha(13),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(
                  'Modern Afghan Dating',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              context,
              'Balanced Approach',
              'Modern Afghan dating often balances traditional values with contemporary relationship expectations.',
              Icons.balance,
            ),
            const SizedBox(height: 8),
            _buildInsightItem(
              context,
              'Personal Connection',
              'While family input remains valued, modern approach emphasizes personal compatibility and mutual interests.',
              Icons.favorite,
            ),
            const SizedBox(height: 8),
            _buildInsightItem(
              context,
              'Cultural Pride',
              'Modern Afghans often seek partners who understand and respect their heritage while embracing contemporary life.',
              Icons.public,
            ),
            const SizedBox(height: 8),
            _buildInsightItem(
              context,
              'Open Communication',
              'Modern approach encourages more direct communication while maintaining cultural respect and boundaries.',
              Icons.chat,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
