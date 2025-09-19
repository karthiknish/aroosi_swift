import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/features/auth/auth_state.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/widgets/input_field.dart';
import 'package:aroosi_flutter/widgets/primary_button.dart';
import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/widgets/animations/motion.dart';
import 'package:aroosi_flutter/utils/debug_logger.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  ProviderSubscription<AuthState>? _sub;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _sub = ref.listenManual<AuthState>(authControllerProvider, (prev, next) {
      if (!mounted) return;
      // Success condition: no error & not loading after request
      logNav(
        'forgot_password listener: loading=${next.loading} error=${next.error} prevLoading=${prev?.loading}',
      );
      if (!_navigated && !next.loading && next.error == null) {
        // We only navigate after a reset request; rely on button disabling to avoid false triggers.
        _navigated = true;
        logNav('forgot_password: success -> navigate /reset');
        ToastService.instance.success('Reset email sent');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/reset');
        });
      }
    }, fireImmediately: false);
  }

  @override
  void dispose() {
    _sub?.close();
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
                onPressed: auth.loading
                    ? null
                    : () {
                        final email = _email.text;
                        logNav(
                          'forgot_password: Send reset link pressed email=$email',
                        );
                        authCtrl.requestPasswordReset(email);
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
