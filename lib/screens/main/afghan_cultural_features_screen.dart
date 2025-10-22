import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:aroosi_flutter/theme/colors.dart';

class AfghanCulturalFeaturesScreen extends ConsumerWidget {
  const AfghanCulturalFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Afghan Cultural Features',
          style: GoogleFonts.nunitoSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surfaceSecondary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            _buildHeroSection(),

            const SizedBox(height: 24),

            // Cultural Traditions
            _buildCulturalTraditions(),

            const SizedBox(height: 24),

            // Halal Dating Guidelines
            _buildHalalDatingGuidelines(context),

            const SizedBox(height: 24),

            // Family Values
            _buildFamilyValues(),

            const SizedBox(height: 24),

            // Cultural Events & Celebrations
            _buildCulturalEvents(),

            const SizedBox(height: 24),

            // Traditional Afghan Cuisine
            _buildAfghanCuisine(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.diversity_3,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            'Embrace Afghan Culture',
            style: GoogleFonts.nunitoSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Find meaningful connections while honoring our rich cultural heritage and traditions',
            style: GoogleFonts.nunitoSans(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCulturalTraditions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderPrimary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_edu,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Afghan Cultural Traditions',
                style: GoogleFonts.nunitoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._culturalTraditions.map(
            (tradition) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.adjust,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tradition,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        color: Colors.grey[700],
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

  Widget _buildHalalDatingGuidelines(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderPrimary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Halal Dating Guidelines',
                style: GoogleFonts.nunitoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._halalGuidelines.map(
            (guideline) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      guideline,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(
                    'Understanding Halal Dating',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halal dating means dating in accordance with Islamic principles:',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• No physical intimacy before marriage\n• Respectful communication\n• Family involvement when appropriate\n• Clear intention of marriage',
                          style: GoogleFonts.nunitoSans(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text('Got it'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.info_outline),
            label: Text(
              'Learn More About Halal Dating',
              style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyValues() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderPrimary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.family_restroom,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Family Values in Relationships',
                style: GoogleFonts.nunitoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._familyValues.map(
            (value) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.home,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        color: Colors.grey[700],
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

  Widget _buildCulturalEvents() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderPrimary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.celebration,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Cultural Events & Celebrations',
                style: GoogleFonts.nunitoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _culturalEvents.length,
            itemBuilder: (context, index) {
              final event = _culturalEvents[index];
              return _EventCard(
                icon: event.icon,
                title: event.title,
                subtitle: event.subtitle,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAfghanCuisine() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderPrimary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Traditional Afghan Cuisine',
                style: GoogleFonts.nunitoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Share the joy of Afghan culinary traditions with your matches. Food is an important part of Afghan culture and relationships.',
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _afghanDishes.map(
              (dish) => Chip(
                label: Text(
                  dish,
                  style: GoogleFonts.nunitoSans(fontSize: 12),
                ),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }

}

class _EventCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EventCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderPrimary,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.nunitoSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: GoogleFonts.nunitoSans(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

final List<String> _culturalTraditions = [
  'Honor-based relationships built on mutual respect and understanding',
  'Traditional courtship with family involvement and blessing',
  'Emphasis on long-term commitment leading to marriage',
  'Cultural preservation through intergenerational connections',
  'Islamic values integrated with traditional Afghan customs',
  'Community-oriented relationship building',
];

final List<String> _halalGuidelines = [
  'No physical intimacy before marriage',
  'Public meetings with proper supervision',
  'Focus on getting to know each other\'s character and values',
  'Clear intentions about marriage from the beginning',
  'Respect for cultural and religious boundaries',
  'Involvement of families in the dating process',
];

final List<String> _familyValues = [
  'Respect for elders and family hierarchy',
  'Family approval before serious relationship commitment',
  'Regular family gatherings and celebrations',
  'Support for extended family networks',
  'Cultural education and preservation',
  'Balancing personal happiness with family expectations',
];


final List<_CulturalEvent> _culturalEvents = [
  _CulturalEvent(
    icon: Icons.favorite,
    title: 'Nikaah',
    subtitle: 'Islamic Marriage Ceremony',
  ),
  _CulturalEvent(
    icon: Icons.cake,
    title: 'Engagement',
    subtitle: 'Family Engagement Party',
  ),
  _CulturalEvent(
    icon: Icons.people,
    title: 'Mehndi',
    subtitle: 'Traditional Henna Ceremony',
  ),
  _CulturalEvent(
    icon: Icons.music_note,
    title: 'Atan',
    subtitle: 'Traditional Afghan Dance',
  ),
];

class _CulturalEvent {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CulturalEvent({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

final List<String> _afghanDishes = [
  'Kabuli Palaw',
  'Mantu',
  'Ashak',
  'Bolani',
  'Qorma',
  'Kebab',
  'Shir Berinj',
  'Sheer Khurma',
];