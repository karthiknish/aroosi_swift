import 'package:flutter/material.dart';

class InlineUpgradeBanner extends StatelessWidget {
  const InlineUpgradeBanner({
    super.key,
    required this.message,
    required this.ctaLabel,
    required this.onPressed,
    this.icon,
    this.margin,
  });

  final String message;
  final String ctaLabel;
  final VoidCallback onPressed;
  final IconData? icon;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconData = icon ?? Icons.star_outline;

    return Card(
      margin: margin ?? EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(iconData, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(onPressed: onPressed, child: Text(ctaLabel)),
            ),
          ],
        ),
      ),
    );
  }
}
