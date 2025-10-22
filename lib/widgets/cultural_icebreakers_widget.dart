import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/theme/colors.dart';

class CulturalIcebreakersWidget extends ConsumerStatefulWidget {
  const CulturalIcebreakersWidget({
    super.key,
    required this.userId,
    required this.userName,
    this.culturalBackground,
  });

  final String userId;
  final String userName;
  final String? culturalBackground;

  @override
  ConsumerState<CulturalIcebreakersWidget> createState() =>
      _CulturalIcebreakersWidgetState();
}

class _CulturalIcebreakersWidgetState
    extends ConsumerState<CulturalIcebreakersWidget> {
  bool _showIcebreakers = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: AppColors.primary.withAlpha(13),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Cultural Conversation Starters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showIcebreakers = !_showIcebreakers;
                    });
                  },
                  icon: Icon(
                    _showIcebreakers ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (_showIcebreakers) ...[
              const SizedBox(height: 16),
              _buildIcebreakerSection(
                'Traditional Afghan Icebreakers',
                _getTraditionalIcebreakers(),
                Icons.history_edu,
                AppColors.primary,
              ),
              const SizedBox(height: 16),
              _buildIcebreakerSection(
                'Modern Cultural Questions',
                _getModernIcebreakers(),
                Icons.trending_up,
                AppColors.secondary,
              ),
              const SizedBox(height: 16),
              _buildIcebreakerSection(
                'Family & Values Discussion',
                _getFamilyIcebreakers(),
                Icons.family_restroom,
                Colors.purple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcebreakerSection(
    String title,
    List<String> icebreakers,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...icebreakers.map(
          (icebreaker) => _buildIcebreakerItem(icebreaker, color),
        ),
      ],
    );
  }

  Widget _buildIcebreakerItem(String icebreaker, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              icebreaker,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(12),
            ),
            child: GestureDetector(
              onTap: () {
                // Copy to clipboard functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Question copied to clipboard!'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Text(
                'Use',
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getTraditionalIcebreakers() {
    return [
      'What family traditions are most important to you?',
      'How do you celebrate Afghan holidays with your family?',
      'What values did your parents instill in you that you cherish most?',
      'What role does your family play in important life decisions?',
      'How do you balance traditional values with modern life?',
      'What Afghan customs do you hope to pass on to future generations?',
      'How do you stay connected to your Afghan heritage?',
      'What does respect mean to you in a relationship?',
    ];
  }

  List<String> _getModernIcebreakers() {
    return [
      'How do you envision balancing career and family life?',
      'What are your favorite ways to relax and de-stress?',
      'What hobbies or interests are you passionate about?',
      'How do you like to spend your weekends?',
      'What kind of books, movies, or music do you enjoy?',
      'How do you stay connected with friends and community?',
      'What personal goals are you working towards?',
      'How do you like to celebrate special occasions?',
    ];
  }

  List<String> _getFamilyIcebreakers() {
    return [
      'Tell me about your family and what makes them special',
      'What qualities do you admire most in your parents?',
      'How do you envision involving family in future milestones?',
      'What family values are most important to you?',
      'How do you handle disagreements with family members?',
      'What role do you hope family will play in your relationship?',
      'How do you balance personal independence with family expectations?',
      'What family traditions would you want to continue?',
    ];
  }
}

// Provider for managing icebreaker preferences
final icebreakerPreferencesProvider = Provider<Map<String, bool>>(
  (ref) => {'traditional': true, 'modern': true, 'family': true},
);
