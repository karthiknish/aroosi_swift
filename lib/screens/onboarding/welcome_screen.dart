import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/widgets/animations/motion.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background image filling the screen
          Positioned.fill(
            child: FadeIn(
              duration: AppMotionDurations.medium,
              child: Image.asset(
                'assets/images/welcome.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                  );
                },
              ),
            ),
          ),
          // Subtle gradient overlay for readability
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.10),
                      Colors.black.withOpacity(0.40),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Foreground content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeThrough(
                delay: AppMotionDurations.fast,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    FadeIn(
                      delay: const Duration(milliseconds: 80),
                      child: Text(
                        'Find your match on Aroosi',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeIn(
                      delay: const Duration(milliseconds: 140),
                      child: Text(
                        'Answer a few quick questions to personalize your experience and start exploring.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeScaleIn(
                      delay: AppMotionDurations.fast,
                      child: FilledButton(
                        onPressed: () =>
                            context.push('/onboarding/profile-setup'),
                        child: const Text('Get Started'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // White Google sign-in lookalike that routes to Login (actual Google sign-in happens on Login screen)
                    FadeIn(
                      delay: const Duration(milliseconds: 180),
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Colors.transparent),
                        ),
                        icon: const Icon(Icons.login, color: Colors.black87),
                        label: const Text(
                          'Continue with Google',
                          style: TextStyle(color: Colors.black87),
                        ),
                        onPressed: () => context.push('/login'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeIn(
                      delay: const Duration(milliseconds: 220),
                      child: TextButton(
                        onPressed: () => context.push('/login'),
                        child: const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
