import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/theme/colors.dart';

class AfghanCourtshipWidget extends ConsumerStatefulWidget {
  const AfghanCourtshipWidget({
    super.key,
    required this.userId,
    required this.userName,
    this.currentStep = 0,
  });

  final String userId;
  final String userName;
  final int currentStep;

  @override
  ConsumerState<AfghanCourtshipWidget> createState() =>
      _AfghanCourtshipWidgetState();
}

class _AfghanCourtshipWidgetState extends ConsumerState<AfghanCourtshipWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _stepController;
  late Animation<double> _fadeAnimation;
  int _currentStep = 0;

  final List<CourtshipStep> _courtshipSteps = [
    CourtshipStep(
      title: 'Initial Interest',
      description: 'Expressing interest with respect and modesty',
      icon: Icons.favorite_border,
      color: AppColors.primary,
      details: [
        'Send a respectful expression of interest',
        'Wait patiently for a response',
        'Maintain modest communication',
      ],
    ),
    CourtshipStep(
      title: 'Family Inquiry',
      description: 'Informal inquiry about family background and values',
      icon: Icons.family_restroom,
      color: Colors.purple,
      details: [
        'Learn about family values and traditions',
        'Understand cultural expectations',
        'Respect family privacy and boundaries',
      ],
    ),
    CourtshipStep(
      title: 'Formal Introduction',
      description: 'Formal introduction through respected intermediaries',
      icon: Icons.people_alt,
      color: Colors.indigo,
      details: [
        'Arrange introduction through family elders',
        'Prepare respectful introduction materials',
        'Follow traditional introduction protocols',
      ],
    ),
    CourtshipStep(
      title: 'Family Meeting',
      description: 'First meeting between families in a respectful setting',
      icon: Icons.groups,
      color: Colors.teal,
      details: [
        'Plan meeting in family-friendly location',
        'Prepare appropriate conversation topics',
        'Show respect to all family members',
      ],
    ),
    CourtshipStep(
      title: 'Cultural Exchange',
      description: 'Sharing and understanding cultural traditions',
      icon: Icons.diversity_3,
      color: Colors.amber,
      details: [
        'Share family traditions and customs',
        'Learn about each other\'s cultural heritage',
        'Find common cultural ground',
      ],
    ),
    CourtshipStep(
      title: 'Family Approval',
      description: 'Seeking formal approval from family elders',
      icon: Icons.verified,
      color: Colors.green,
      details: [
        'Present intentions to family elders',
        'Respectfully address any concerns',
        'Receive family blessing for relationship',
      ],
    ),
    CourtshipStep(
      title: 'Formal Courtship',
      description: 'Beginning formal courtship with family involvement',
      icon: Icons.favorite,
      color: Colors.pink,
      details: [
        'Begin supervised courtship process',
        'Maintain respectful communication',
        'Follow traditional courtship guidelines',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentStep = widget.currentStep;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _stepController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
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
                  'Traditional Afghan Courtship Journey',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress indicator
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(51),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (_currentStep + 1) / _courtshipSteps.length,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Step ${_currentStep + 1} of ${_courtshipSteps.length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Current step details
            FadeTransition(opacity: _fadeAnimation, child: _buildCurrentStep()),
            const SizedBox(height: 16),
            // Step navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentStep > 0
                      ? () {
                          _stepController.reverse().then((_) {
                            setState(() {
                              _currentStep--;
                            });
                            _stepController.forward();
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.withAlpha(51),
                    foregroundColor: Colors.grey,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _currentStep < _courtshipSteps.length - 1
                      ? () {
                          _stepController.reverse().then((_) {
                            setState(() {
                              _currentStep++;
                            });
                            _stepController.forward();
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Cultural guidance
            _buildCulturalGuidance(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    final step = _courtshipSteps[_currentStep];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: step.color.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: step.color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: step.color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(step.icon, color: step.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: step.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Key Considerations:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: step.color,
            ),
          ),
          const SizedBox(height: 8),
          ...step.details.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: step.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      detail,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(204),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCulturalGuidance() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'Afghan Courtship Wisdom',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Traditional Afghan courtship is a sacred journey that honors family values, cultural traditions, '
            'and religious principles. Each step should be taken with patience, respect, and sincere intention. '
            'The blessing of family elders is essential for a blessed and lasting union.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
            ),
          ),
        ],
      ),
    );
  }
}

class CourtshipStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> details;

  CourtshipStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.details,
  });
}

// Provider for managing courtship progress
final courtshipProgressProvider = Provider<int>((ref) => 0);
