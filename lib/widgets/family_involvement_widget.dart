import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FamilyInvolvementWidget extends ConsumerStatefulWidget {
  const FamilyInvolvementWidget({
    super.key,
    required this.userId,
    required this.userName,
    this.interestStatus,
  });

  final String userId;
  final String userName;
  final String? interestStatus;

  @override
  ConsumerState<FamilyInvolvementWidget> createState() =>
      _FamilyInvolvementWidgetState();
}

class _FamilyInvolvementWidgetState
    extends ConsumerState<FamilyInvolvementWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showFamilyOptions = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: Colors.purple.withAlpha(13),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.family_restroom, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Family Involvement',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showFamilyOptions = !_showFamilyOptions;
                    });
                    if (_showFamilyOptions) {
                      _animationController.forward();
                    } else {
                      _animationController.reverse();
                    }
                  },
                  icon: Icon(
                    _showFamilyOptions ? Icons.expand_less : Icons.expand_more,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            if (_showFamilyOptions) ...[
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFamilyOption(
                      'Request Family Introduction',
                      'Invite family elders to formally introduce both parties',
                      Icons.people_alt,
                      () => _handleFamilyIntroduction(),
                    ),
                    const SizedBox(height: 12),
                    _buildFamilyOption(
                      'Share Family Values',
                      'Exchange information about family traditions and values',
                      Icons.diversity_3,
                      () => _handleFamilyValues(),
                    ),
                    const SizedBox(height: 12),
                    _buildFamilyOption(
                      'Request Family Approval',
                      'Seek formal approval from family elders',
                      Icons.verified,
                      () => _handleFamilyApproval(),
                    ),
                    const SizedBox(height: 12),
                    _buildFamilyOption(
                      'Arrange Family Meeting',
                      'Plan a respectful meeting with family members',
                      Icons.event,
                      () => _handleFamilyMeeting(),
                    ),
                    const SizedBox(height: 16),
                    _buildFamilyGuidance(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyOption(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.withAlpha(51)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.purple, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyGuidance() {
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
                'Afghan Family Guidance',
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
            'In Afghan culture, family involvement is a crucial step in the matchmaking process. '
            'Respectful communication with family elders and adherence to traditional values '
            'are essential for building a strong foundation for a lasting relationship.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
            ),
          ),
        ],
      ),
    );
  }

  void _handleFamilyIntroduction() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Family Introduction'),
        content: const Text(
          'This will send a formal request to introduce both families through respected intermediaries. '
          'This is a traditional step in Afghan matchmaking that shows respect for family values.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Family introduction request sent!'),
                ),
              );
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _handleFamilyValues() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Family Values'),
        content: const Text(
          'This will allow you to share information about your family traditions, values, and '
          'cultural expectations with the other party. Understanding each other\'s family '
          'values is important in Afghan culture.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Family values shared successfully!'),
                ),
              );
            },
            child: const Text('Share Values'),
          ),
        ],
      ),
    );
  }

  void _handleFamilyApproval() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Family Approval'),
        content: const Text(
          'This will initiate the process of seeking formal approval from family elders. '
          'In Afghan culture, family approval is a crucial step before proceeding with '
          'a relationship.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Family approval request initiated!'),
                ),
              );
            },
            child: const Text('Request Approval'),
          ),
        ],
      ),
    );
  }

  void _handleFamilyMeeting() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arrange Family Meeting'),
        content: const Text(
          'This will help arrange a respectful meeting with family members in a '
          'family-friendly setting. In Afghan culture, proper family meetings are '
          'conducted with dignity and respect for all participants.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Family meeting arrangement initiated!'),
                ),
              );
            },
            child: const Text('Arrange Meeting'),
          ),
        ],
      ),
    );
  }
}

// Provider for managing family involvement preferences
final familyInvolvementPreferencesProvider = Provider<Map<String, bool>>(
  (ref) => {
    'introduction': true,
    'values': true,
    'approval': true,
    'meeting': true,
  },
);
