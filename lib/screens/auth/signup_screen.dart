import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/features/auth/auth_state.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/widgets/input_field.dart';
import 'package:aroosi_flutter/widgets/primary_button.dart';
import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/widgets/animations/motion.dart';
import 'package:aroosi_flutter/utils/debug_logger.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  ProviderSubscription<AuthState>? _sub;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _sub = ref.listenManual<AuthState>(authControllerProvider, (prev, next) {
      if (!mounted) return;
      logNav(
        'signup_screen listener: prevAuth=${prev?.isAuthenticated} -> nextAuth=${next.isAuthenticated} loading=${next.loading} error=${next.error} profile=${next.profile == null ? 'null' : 'present'}',
      );
      if (!_navigated && next.isAuthenticated) {
        logNav('signup_screen: trigger navigation to /dashboard');
        _navigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/dashboard');
        });
      }
    }, fireImmediately: false);
  }

  @override
  void dispose() {
    _sub?.close();
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
                onPressed: auth.loading
                    ? null
                    : () {
                        logNav(
                          'signup_screen: Create account pressed name=${_name.text} email=${_email.text}',
                        );
                        authCtrl.signup(
                          _name.text,
                          _email.text,
                          _password.text,
                        );
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
