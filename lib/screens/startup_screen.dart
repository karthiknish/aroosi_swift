import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const FlutterLogo(size: 96),
              const SizedBox(height: 24),
              Text(
                'Welcome to Aroosi',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Discover matches, manage your profile, and get ready for meaningful conversations.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go('/onboarding'),
                child: const Text('Get Started'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/login'),
                child: const Text('I already have an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
