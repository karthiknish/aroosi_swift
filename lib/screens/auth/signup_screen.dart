import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/widgets/input_field.dart';
import 'package:aroosi_flutter/widgets/primary_button.dart';
import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/widgets/animations/motion.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final authCtrl = ref.read(authControllerProvider.notifier);

    return AppScaffold(
      title: 'Sign up',
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
              child: InputField(controller: _name, label: 'Name'),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: AppMotionDurations.fast,
              beginOffset: const Offset(0, 0.1),
              child: InputField(controller: _email, label: 'Email'),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 240),
              beginOffset: const Offset(0, 0.12),
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
                label: 'Create account',
                loading: auth.loading,
                onPressed: () async {
                  await authCtrl.signup(
                    _name.text,
                    _email.text,
                    _password.text,
                  );
                  if (context.mounted &&
                      ref.read(authControllerProvider).isAuthenticated) {
                    context.go('/dashboard');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
