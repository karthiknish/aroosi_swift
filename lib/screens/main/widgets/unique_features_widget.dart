import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/theme/colors.dart';

class UniqueFeaturesWidget extends ConsumerWidget {
  const UniqueFeaturesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unique Features',
            style: GoogleFonts.nunitoSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Feature Cards
          _FeatureCard(
            icon: Icons.diversity_3,
            title: 'Cultural Matching',
            description: 'Find matches based on shared Afghan values, traditions, and family backgrounds',
            color: AppColors.primary,
            onTap: () => context.go('/main/cultural-compatibility'),
          ),
          const SizedBox(height: 12),

          _FeatureCard(
            icon: Icons.favorite,
            title: 'Halal Dating',
            description: 'Respectful dating guidelines aligned with Islamic values and traditions',
            color: AppColors.secondary,
            onTap: () => context.go('/main/free-features'),
          ),
          const SizedBox(height: 12),

          _FeatureCard(
            icon: Icons.groups,
            title: 'Family Approval',
            description: 'Involve family in the matching process with our unique family features',
            color: AppColors.accent,
            onTap: () => context.go('/main/free-features'),
          ),
          const SizedBox(height: 12),

          _FeatureCard(
            icon: Icons.language,
            title: 'Language Support',
            description: 'Connect in English, Farsi (Dari), or Pashto with full app localization',
            color: Colors.green[600]!,
            onTap: () => context.go('/main/language'),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderPrimary,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}