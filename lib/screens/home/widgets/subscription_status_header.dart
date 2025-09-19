import 'package:flutter/material.dart';
import 'package:aroosi_flutter/features/subscription/subscription_models.dart';

class SubscriptionStatusHeader extends StatelessWidget {
  const SubscriptionStatusHeader({
    super.key,
    required this.plan,
    required this.isActive,
    required this.expiresAt,
    required this.isApproachingExpiry,
    required this.daysUntilExpiry,
    required this.onUpgrade,
  });
  final SubscriptionPlan plan;
  final bool isActive;
  final DateTime? expiresAt;
  final bool isApproachingExpiry;
  final int? daysUntilExpiry;
  final VoidCallback onUpgrade;

  String getTierDisplayName(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return 'Free';
      case SubscriptionPlan.premium:
        return 'Premium';
      case SubscriptionPlan.premiumPlus:
        return 'Premium Plus';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Plan',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  getTierDisplayName(plan),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isActive && expiresAt != null)
                  Text(
                    (isApproachingExpiry ? 'Expires ' : 'Renews ') +
                        '${_formatDate(expiresAt!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          if (!isActive)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: ElevatedButton(
                onPressed: onUpgrade,
                child: const Text('Upgrade'),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }
}
