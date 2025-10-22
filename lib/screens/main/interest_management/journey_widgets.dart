import 'package:flutter/material.dart';

import 'package:aroosi_flutter/features/profiles/list_controller.dart';
import 'package:aroosi_flutter/theme/colors.dart';
import 'package:aroosi_flutter/theme/motion.dart';

/// Journey intro widget for the interests management screen
class JourneyIntro extends StatelessWidget {
  final InterestsState state;
  final String currentMode;

  const JourneyIntro({
    super.key,
    required this.state,
    required this.currentMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = state.items.length;
    final modeCopy = <String, String>{
      'sent': 'Introductions you initiated',
      'received': 'Awaiting your response',
      'mutual': 'Mutual celebrations',
      'family_approved': 'Family-reviewed stories',
    };
    final descriptor = modeCopy[currentMode] ?? 'Active connections';
    final labelSuffix = total == 1 ? 'profile' : 'profiles';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Aroosi journey',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Blend Afghan tradition with modern clarity as you nurture every introduction toward a lasting match.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '$descriptor • $total $labelSuffix',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mode selector widget for switching between different interest views
class ModeSelector extends StatelessWidget {
  final String currentMode;
  final Function(String) onModeChanged;

  const ModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modes = [
      {
        'value': 'sent',
        'title': 'Sent interests',
        'subtitle': 'Introductions you initiated',
        'icon': Icons.flight_takeoff,
      },
      {
        'value': 'received',
        'title': 'Received',
        'subtitle': 'Thoughtful requests waiting on you',
        'icon': Icons.inbox_outlined,
      },
      {
        'value': 'mutual',
        'title': 'Mutual',
        'subtitle': 'Matches where affection is shared',
        'icon': Icons.favorite,
      },
      {
        'value': 'family_approved',
        'title': 'Family moments',
        'subtitle': 'Stories guided by family blessing',
        'icon': Icons.family_restroom,
      },
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: modes.map((mode) {
        final value = mode['value']! as String;
        final title = mode['title']! as String;
        final subtitle = mode['subtitle']! as String;
        final icon = mode['icon']! as IconData;
        final selected = currentMode == value;

        return GestureDetector(
          onTap: () {
            if (currentMode == value) return;
            onModeChanged(value);
          },
          child: AnimatedContainer(
            duration: AppMotionDurations.fast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: selected
                  ? LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.85),
                        AppColors.secondary.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: selected
                  ? null
                  : theme.colorScheme.surface.withValues(alpha: 0.9),
              border: Border.all(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.45)
                    : theme.colorScheme.outline.withValues(alpha: 0.12),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.24),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.18)
                        : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: selected ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.9)
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
