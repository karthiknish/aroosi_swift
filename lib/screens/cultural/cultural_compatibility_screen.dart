import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/features/cultural/cultural_controller.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';

class CulturalCompatibilityScreen extends ConsumerStatefulWidget {
  final String userId1;
  final String userId2;
  final String? userName2;

  const CulturalCompatibilityScreen({
    super.key,
    required this.userId1,
    required this.userId2,
    this.userName2,
  });

  @override
  ConsumerState<CulturalCompatibilityScreen> createState() => _CulturalCompatibilityScreenState();
}

class _CulturalCompatibilityScreenState extends ConsumerState<CulturalCompatibilityScreen> {
  Map<String, dynamic>? _compatibilityData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCompatibility();
  }

  Future<void> _loadCompatibility() async {
    setState(() => _loading = true);

    final result = await ref.read(culturalControllerProvider.notifier)
        .getCulturalCompatibility(widget.userId1, widget.userId2);

    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _compatibilityData = result;
        _error = null;
      } else {
        _error = result['error'] ?? 'Failed to load compatibility';
      }
    });
  }

  Widget _buildCompatibilityScore(double score) {
    final percentage = (score * 100).round();
    final color = switch (percentage) {
      >= 80 => Colors.green,
      >= 60 => Colors.lightGreen,
      >= 40 => Colors.orange,
      _ => Colors.red,
    };

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getCompatibilityLabel(percentage),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getCompatibilityDescription(percentage),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getCompatibilityLabel(int percentage) {
    if (percentage >= 80) return 'Excellent Match';
    if (percentage >= 60) return 'Good Match';
    if (percentage >= 40) return 'Fair Match';
    return 'Challenging Match';
  }

  String _getCompatibilityDescription(int percentage) {
    if (percentage >= 80) {
      return 'Your cultural backgrounds align very well. This suggests strong potential for understanding and harmony.';
    } else if (percentage >= 60) {
      return 'There are some cultural differences, but with open communication and respect, this can work beautifully.';
    } else if (percentage >= 40) {
      return 'Cultural differences may require extra effort and understanding from both sides.';
    } else {
      return 'Significant cultural differences may present challenges. Consider if you\'re both willing to bridge these gaps.';
    }
  }

  Widget _buildCompatibilityFactor({
    required String title,
    required String value,
    required double score,
    required String insight,
  }) {
    final color = switch ((score * 100).round()) {
      >= 80 => Colors.green,
      >= 60 => Colors.lightGreen,
      >= 40 => Colors.orange,
      _ => Colors.red,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(score * 100).round()}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                insight,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsList(List<dynamic> insights) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Insights',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        ...insights.map((insight) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildCompatibilityDetails() {
    if (_compatibilityData == null) return const SizedBox.shrink();

    final compatibility = _compatibilityData!['compatibility'] as Map<String, dynamic>? ?? {};
    final insights = _compatibilityData!['insights'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Religion Compatibility
        if (compatibility['religion'] != null)
          _buildCompatibilityFactor(
            title: 'Religious Compatibility',
            value: compatibility['religion']['description'] ?? '',
            score: compatibility['religion']['score'] ?? 0.0,
            insight: compatibility['religion']['insight'] ?? '',
          ),

        // Language Compatibility
        if (compatibility['language'] != null)
          _buildCompatibilityFactor(
            title: 'Language Compatibility',
            value: compatibility['language']['description'] ?? '',
            score: compatibility['language']['score'] ?? 0.0,
            insight: compatibility['language']['insight'] ?? '',
          ),

        // Cultural Values
        if (compatibility['culture'] != null)
          _buildCompatibilityFactor(
            title: 'Cultural Values',
            value: compatibility['culture']['description'] ?? '',
            score: compatibility['culture']['score'] ?? 0.0,
            insight: compatibility['culture']['insight'] ?? '',
          ),

        // Family Values
        if (compatibility['family'] != null)
          _buildCompatibilityFactor(
            title: 'Family Values',
            value: compatibility['family']['description'] ?? '',
            score: compatibility['family']['score'] ?? 0.0,
            insight: compatibility['family']['insight'] ?? '',
          ),

        const SizedBox(height: 24),

        // Insights
        _buildInsightsList(insights),

        const SizedBox(height: 24),

        // Recommendations
        Card(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.recommend,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recommendations',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Take time to learn about each other\'s cultural backgrounds\n'
                  '• Discuss family expectations and traditions openly\n'
                  '• Consider involving family members in the process\n'
                  '• Be respectful of religious practices and observances\n'
                  '• Communication is key - ask questions and listen actively',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Cultural Compatibility',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to load compatibility',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadCompatibility,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCompatibility,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compatibility with ${widget.userName2 ?? 'this person'}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cultural compatibility analysis based on religious background, values, and traditions.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Overall Score
                        if (_compatibilityData != null)
                          _buildCompatibilityScore(
                            (_compatibilityData!['score'] as num?)?.toDouble() ?? 0.0,
                          ),

                        const SizedBox(height: 32),

                        // Detailed Factors
                        _buildCompatibilityDetails(),

                        const SizedBox(height: 32),

                        // Disclaimer
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'This analysis is based on the information provided in cultural profiles. '
                                  'Real compatibility depends on personal chemistry, communication, and mutual respect.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
