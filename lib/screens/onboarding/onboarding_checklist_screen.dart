import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/theme/colors.dart';
import 'package:aroosi_flutter/widgets/animations/motion.dart';

class OnboardingChecklistScreen extends StatefulWidget {
  const OnboardingChecklistScreen({super.key});

  @override
  State<OnboardingChecklistScreen> createState() =>
      _OnboardingChecklistScreenState();
}

class _OnboardingChecklistScreenState extends State<OnboardingChecklistScreen> {
  final _items = <_ChecklistItem>[
    _ChecklistItem('Upload a profile photo'),
    _ChecklistItem('Share a short bio'),
    _ChecklistItem('Select your interests'),
    _ChecklistItem('Complete cultural assessment'),
  ];

  @override
  Widget build(BuildContext context) {
    final isComplete = _items.every((item) => item.completed);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complete Your Profile',
          style: GoogleFonts.nunitoSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surfaceSecondary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: FadeThrough(
          delay: AppMotionDurations.fast,
          child: Column(
            children: [
              // Welcome message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome to Aroosi!',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete these steps to find culturally compatible matches',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 80 * index),
                      beginOffset: const Offset(0, 0.05),
                      child: _ChecklistTile(
                        title: item.title,
                        completed: item.completed,
                        onTap: () => _handleItemTap(item, index),
                      ),
                    );
                  },
                ),
              ),
              FadeScaleIn(
                delay: AppMotionDurations.fast,
                child: FilledButton(
                  onPressed: isComplete
                      ? () => context.push('/onboarding/complete')
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    isComplete ? 'Continue to Dashboard' : 'Complete All Steps',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleItemTap(_ChecklistItem item, int index) {
    if (item.title == 'Complete cultural assessment') {
      context.push('/main/cultural-assessment');
    } else {
      setState(() {
        item.completed = !item.completed;
      });
    }
  }
}

class _ChecklistItem {
  _ChecklistItem(this.title);

  final String title;
  bool completed = false;
}

class _ChecklistTile extends StatelessWidget {
  final String title;
  final bool completed;
  final VoidCallback onTap;

  const _ChecklistTile({
    required this.title,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed ? AppColors.primary : AppColors.borderPrimary,
          width: completed ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: completed ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: completed ? AppColors.primary : AppColors.borderPrimary,
                  width: 2,
                ),
              ),
              child: completed
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.nunitoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: completed ? AppColors.primary : Colors.black87,
                ),
              ),
            ),
            if (title == 'Complete cultural assessment')
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
