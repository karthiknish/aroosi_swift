import 'package:flutter/cupertino.dart';
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
import 'package:aroosi_flutter/theme/colors.dart';
import 'package:aroosi_flutter/theme/typography.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  ProviderSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // Riverpod 3: use listenManual inside initState; store subscription to cancel.
    // Navigate only on unauthenticated -> authenticated transition.
    // Only listen for auth state changes for error or loading UI; navigation is handled by router redirect.
    _authSub = ref.listenManual<AuthState>(authControllerProvider, (
      prev,
      next,
    ) {
      // No-op: navigation is handled by router redirect logic.
      // Optionally, you can log state transitions here for debugging.
      logNav(
        'login_screen listener: prevAuth=${prev?.isAuthenticated} nextAuth=${next.isAuthenticated} loading=${next.loading} error=${next.error}',
      );
    }, fireImmediately: false);
  }

  @override
  void dispose() {
    _authSub?.close();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final authCtrl = ref.read(authControllerProvider.notifier);

    // If already authenticated, redirect to search (prevents showing login form)
    if (auth.isAuthenticated) {
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentLoc = GoRouterState.of(context).uri.toString();
        if (currentLoc != '/search') {
          context.go('/search');
        }
      });
      return const SizedBox.shrink();
    }

    return AppScaffold(
      title: 'Login',
      child: Stack(
        children: [
          FadeThrough(
            delay: AppMotionDurations.fast,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
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
                          style: AppTypography.body.copyWith(
                            color: AppColors.error,
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
                      label: 'Sign in with Email',
                      loading: auth.loading,
                      onPressed: auth.loading
                          ? null
                          : () {
                              logNav(
                                'login_screen: Sign in pressed email=${_email.text}',
                              );
                              authCtrl.login(_email.text, _password.text);
                            },
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeScaleIn(
                    delay: AppMotionDurations.fast,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.text,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CupertinoButton(
                        onPressed: auth.loading
                            ? null
                            : () {
                                logNav('login_screen: Apple sign in pressed');
                                authCtrl.loginWithApple();
                              },
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.arrow_up_right_square_fill,
                              color: AppColors.onPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sign in with Apple',
                              style: AppTypography.bodySemiBold.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeIn(
                    delay: const Duration(milliseconds: 220),
                    child: Text(
                      'Apple Sign In includes "Hide My Email" for privacy',
                      style: AppTypography.caption.copyWith(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeIn(
                    delay: const Duration(milliseconds: 220),
                    child: CupertinoButton(
                      onPressed: () => context.go('/forgot'),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  FadeIn(
                    delay: const Duration(milliseconds: 260),
                    child: CupertinoButton(
                      onPressed: () => context.go('/signup'),
                      child: const Text('Create account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (auth.loading)
            Positioned.fill(
              child: Container(
                color: AppColors.text.withValues(alpha: 0.4),
                child: const Center(child: CupertinoActivityIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
