import 'package:flutter/material.dart';

import 'package:aroosi_flutter/features/profiles/list_controller.dart';
import 'package:aroosi_flutter/theme/colors.dart';

/// Journey metrics widget showing statistics about interests
class JourneyMetrics extends StatelessWidget {
  final InterestsState state;

  const JourneyMetrics({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = state.items.length;
    final awaitingCount = state.items
        .where((interest) => interest.status == 'pending')
        .length;
    final mutualCount = state.items
        .where(
          (interest) =>
              interest.status == 'reciprocated' ||
              interest.status == 'accepted',
        )
        .length;
    final familyCount = state.items
        .where((interest) => interest.status.contains('family'))
        .length;
    final journeyProgress = total == 0 ? 0.0 : mutualCount / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Journey pulse',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetricTile(
              context,
              label: 'Active stories',
              value: '$total',
              icon: Icons.auto_stories,
              color: AppColors.primary,
            ),
            _buildMetricTile(
              context,
              label: 'Awaiting replies',
              value: '$awaitingCount',
              icon: Icons.pending_actions,
              color: Colors.orange,
            ),
            _buildMetricTile(
              context,
              label: 'Mutual celebrations',
              value: '$mutualCount',
              icon: Icons.favorite,
              color: Colors.pink,
            ),
            _buildMetricTile(
              context,
              label: 'Family moments',
              value: '$familyCount',
              icon: Icons.family_restroom,
              color: Colors.teal,
            ),
          ],
        ),
        if (total > 0) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: journeyProgress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.06,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mutual connections make up ${(journeyProgress * 100).round()}% of your story so far.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Insight controls widget for toggling different view options
class InsightControls extends StatelessWidget {
  final bool showCulturalInsights;
  final bool showCompatibilityScore;
  final Function(bool) onCulturalInsightsChanged;
  final Function(bool) onCompatibilityScoreChanged;

  const InsightControls({
    super.key,
    required this.showCulturalInsights,
    required this.showCompatibilityScore,
    required this.onCulturalInsightsChanged,
    required this.onCompatibilityScoreChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Guidance layers',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildTogglePill(
              context,
              icon: showCulturalInsights
                  ? Icons.insights
                  : Icons.lightbulb_outline,
              title: showCulturalInsights ? 'Insights on' : 'Cultural insights',
              description: 'Cultural wisdom tailored to each view',
              selected: showCulturalInsights,
              accent: AppColors.primary,
              onChanged: onCulturalInsightsChanged,
            ),
            _buildTogglePill(
              context,
              icon: showCompatibilityScore
                  ? Icons.favorite
                  : Icons.favorite_border,
              title: showCompatibilityScore
                  ? 'Compatibility on'
                  : 'Compatibility score',
              description: 'Confidence guide for each introduction',
              selected: showCompatibilityScore,
              accent: Colors.pink,
              onChanged: onCompatibilityScoreChanged,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTogglePill(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool selected,
    required Color accent,
    required Function(bool) onChanged,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onChanged(!selected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.08)
              : theme.colorScheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.3)
                : theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.15)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: selected
                    ? accent
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? accent : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Switch(
              value: selected,
              onChanged: onChanged,
              activeThumbColor: accent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
