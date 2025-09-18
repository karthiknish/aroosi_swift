import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/widgets/animations/motion.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Defer navigation to next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authControllerProvider);
      if (!mounted) return;
      context.go(auth.isAuthenticated ? '/dashboard' : '/startup');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeScaleIn(
          duration: AppMotionDurations.slow,
          beginScale: 0.85,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlutterLogo(size: 96),
              SizedBox(height: 16),
              Text(
                'Aroosi',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
