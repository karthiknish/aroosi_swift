import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/widgets/input_field.dart';
import 'package:aroosi_flutter/widgets/primary_button.dart';
import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/widgets/animations/motion.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final authCtrl = ref.read(authControllerProvider.notifier);
    return AppScaffold(
      title: 'Forgot password',
      child: FadeThrough(
        delay: AppMotionDurations.fast,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FadeIn(
              duration: AppMotionDurations.short,
              child: Text('Enter your email to reset your password.'),
            ),
            const SizedBox(height: 8),
            FadeSlideIn(
              duration: AppMotionDurations.medium,
              beginOffset: const Offset(0, 0.08),
              child: InputField(controller: _email, label: 'Email'),
            ),
            const SizedBox(height: 24),
            FadeScaleIn(
              delay: AppMotionDurations.fast,
              child: PrimaryButton(
                label: 'Send reset link',
                loading: auth.loading,
                onPressed: () async {
                  final email = _email.text;
                  await authCtrl.requestPasswordReset(email);
                  final noError =
                      ref.read(authControllerProvider).error == null;
                  if (!context.mounted) return;
                  if (noError) {
                    ToastService.instance.success('Reset email sent');
                    if (!context.mounted) return;
                    context.go('/reset');
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
