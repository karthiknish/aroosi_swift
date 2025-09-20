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

  Color _getPlanColor(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return Colors.grey.shade600;
      case SubscriptionPlan.premium:
        return Colors.blue.shade600;
      case SubscriptionPlan.premiumPlus:
        return Colors.purple.shade600;
    }
  }

  IconData _getPlanIcon(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return Icons.star_outline;
      case SubscriptionPlan.premium:
        return Icons.star;
      case SubscriptionPlan.premiumPlus:
        return Icons.workspace_premium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final planColor = _getPlanColor(plan);
    final planIcon = _getPlanIcon(plan);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [planColor.withOpacity(0.1), planColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: planColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: planColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(planIcon, color: planColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Plan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        getTierDisplayName(plan),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: planColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isActive)
                  Flexible(
                    child: ElevatedButton(
                      onPressed: onUpgrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: planColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Upgrade'),
                    ),
                  ),
              ],
            ),
            if (isActive && expiresAt != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isApproachingExpiry
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isApproachingExpiry ? Icons.warning_amber : Icons.refresh,
                      color: isApproachingExpiry ? Colors.orange : Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (isApproachingExpiry ? 'Expires ' : 'Renews ') +
                          '${_formatDate(expiresAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isApproachingExpiry
                            ? Colors.orange
                            : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
