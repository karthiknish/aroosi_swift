import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/widgets/animations/motion.dart';

class OnboardingCompleteScreen extends StatelessWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Set!')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: FadeThrough(
          delay: AppMotionDurations.fast,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              FadeScaleIn(
                duration: AppMotionDurations.medium,
                beginScale: 0.8,
                child: Icon(
                  Icons.check_circle,
                  size: 96,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              FadeIn(
                delay: AppMotionDurations.fast,
                child: Text(
                  'Your profile looks great',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              const FadeIn(
                delay: Duration(milliseconds: 220),
                child: Text(
                  'Jump in to start exploring new connections tailored to your preferences.',
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              FadeScaleIn(
                delay: AppMotionDurations.fast,
                child: FilledButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Go to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
