import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/features/cultural/cultural_controller.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';

import 'package:aroosi_flutter/widgets/error_states.dart';

import 'package:aroosi_flutter/l10n/app_localizations.dart';

class CompatibilityDetailsScreen extends ConsumerStatefulWidget {
  const CompatibilityDetailsScreen({
    super.key,
    required this.userId1,
    required this.userId2,
  });

  final String userId1;
  final String userId2;

  @override
  ConsumerState<CompatibilityDetailsScreen> createState() =>
      _CompatibilityDetailsScreenState();
}

class _CompatibilityDetailsScreenState
    extends ConsumerState<CompatibilityDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(culturalControllerProvider.notifier)
          .loadCompatibility(widget.userId1, widget.userId2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final compatibilityState = ref.watch(culturalControllerProvider);

    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      title: l10n.compatibilityTitle,
      child: SafeArea(
        child: compatibilityState.loading
            ? _CompatibilityLoading(l10n: l10n)
            : compatibilityState.error != null
            ? ErrorStateWithRetry(
                title: 'Compatibility Error',
                subtitle: compatibilityState.error!,
                onRetry: () => ref
                    .read(culturalControllerProvider.notifier)
                    .loadCompatibility(widget.userId1, widget.userId2),
              )
            : _CompatibilityContent(
                compatibility: compatibilityState.compatibility,
                l10n: l10n,
              ),
      ),
    );
  }
}

class _CompatibilityLoading extends StatelessWidget {
  const _CompatibilityLoading({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 16),
          Text(l10n.compatibilityAnalyzing),
        ],
      ),
    );
  }
}

class _CompatibilityContent extends StatelessWidget {
  const _CompatibilityContent({
    required this.compatibility,
    required this.l10n,
  });

  final dynamic compatibility;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final overall = compatibility['overall'] ?? 0;
    final factors = compatibility['factors'] ?? {};
    final insights = List<String>.from(compatibility['insights'] ?? []);
    final recommendations = List<String>.from(
      compatibility['recommendations'] ?? [],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Score Header
          _buildOverallScore(context, overall),

          const SizedBox(height: 32),

          // Factor Breakdown
          _buildFactorBreakdown(context, factors),

          const SizedBox(height: 32),

          // Insights
          if (insights.isNotEmpty) ...[
            _buildInsightsSection(context, insights),
            const SizedBox(height: 32),
          ],

          // Recommendations
          if (recommendations.isNotEmpty) ...[
            _buildRecommendationsSection(context, recommendations),
            const SizedBox(height: 32),
          ],

          // Action Buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildOverallScore(BuildContext context, int overall) {
    final theme = Theme.of(context);
    final scoreColor = _getScoreColor(overall);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withValues(alpha: 0.1),
            scoreColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          // Score Circle - Responsive sizing
          Container(
            width: MediaQuery.of(context).size.width > 600 ? 140 : 120,
            height: MediaQuery.of(context).size.width > 600 ? 140 : 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [scoreColor, scoreColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: scoreColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$overall%',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            l10n.compatibilityOverall,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            _getCompatibilityDescription(overall, l10n),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFactorBreakdown(
    BuildContext context,
    Map<String, dynamic> factors,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compatibility Factors',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 16),

        ...factors.entries.map((entry) {
          final factor = entry.value as Map<String, dynamic>;
          final score = factor['score'] ?? 0;
          final explanation = factor['explanation'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _capitalizeFirst(entry.key),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(
                          score.toInt(),
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${score.toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getScoreColor(score.toInt()),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Progress Bar
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(score.toInt()),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  explanation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInsightsSection(BuildContext context, List<String> insights) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.compatibilityInsights,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        ...insights.map(
          (insight) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection(
    BuildContext context,
    List<String> recommendations,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.recommend_rounded,
              color: theme.colorScheme.secondary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.compatibilityRecommendations,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        ...recommendations.map(
          (recommendation) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recommendation,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/cultural/family-approval'),
            icon: const Icon(Icons.family_restroom_rounded),
            label: Text(l10n.compatibilityFamilyApproval),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () =>
                context.go('/cultural/supervised-conversation/initiate'),
            icon: const Icon(Icons.chat_rounded),
            label: Text(l10n.compatibilitySupervisedConversation),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              side: BorderSide(color: theme.colorScheme.primary),
              foregroundColor: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.yellow.shade700;
    return Colors.red;
  }

  String _getCompatibilityDescription(int score, AppLocalizations l10n) {
    if (score >= 80) return l10n.compatibilityExcellent;
    if (score >= 60) return l10n.compatibilityGood;
    if (score >= 40) return l10n.compatibilityModerate;
    return l10n.compatibilityLow;
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
