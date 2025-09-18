import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/widgets/input_field.dart';
import 'package:aroosi_flutter/widgets/primary_button.dart';
import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/widgets/animations/motion.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final authCtrl = ref.read(authControllerProvider.notifier);

    return AppScaffold(
      title: 'Login',
      child: FadeThrough(
        delay: AppMotionDurations.fast,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (auth.error != null)
              FadeIn(
                duration: AppMotionDurations.short,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    auth.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            FadeSlideIn(
              duration: AppMotionDurations.medium,
              beginOffset: const Offset(0, 0.08),
              child: InputField(controller: _email, label: 'Email'),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: AppMotionDurations.fast,
              beginOffset: const Offset(0, 0.1),
              child: InputField(
                controller: _password,
                label: 'Password',
                obscure: true,
              ),
            ),
            const SizedBox(height: 24),
            FadeScaleIn(
              delay: AppMotionDurations.fast,
              child: PrimaryButton(
                label: 'Sign in',
                loading: auth.loading,
                onPressed: () async {
                  await authCtrl.login(_email.text, _password.text);
                  if (context.mounted &&
                      ref.read(authControllerProvider).isAuthenticated) {
                    context.go('/dashboard');
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            FadeIn(
              delay: const Duration(milliseconds: 200),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Continue with Google'),
                onPressed: auth.loading
                    ? null
                    : () async {
                        await authCtrl.loginWithGoogle();
                        if (context.mounted &&
                            ref.read(authControllerProvider).isAuthenticated) {
                          context.go('/dashboard');
                        }
                      },
              ),
            ),
            const SizedBox(height: 12),
            FadeIn(
              delay: const Duration(milliseconds: 220),
              child: TextButton(
                onPressed: () => context.go('/forgot'),
                child: const Text('Forgot password?'),
              ),
            ),
            FadeIn(
              delay: const Duration(milliseconds: 260),
              child: TextButton(
                onPressed: () => context.go('/signup'),
                child: const Text('Create account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
