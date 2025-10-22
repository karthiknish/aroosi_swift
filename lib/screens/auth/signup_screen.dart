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

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _birthDate = TextEditingController();
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
        logNav('signup_screen: trigger navigation to /search');
        _navigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/search');
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
    _birthDate.dispose();
    super.dispose();
  }

  void _showCupertinoAlert(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Alert'),
          content: Text(message),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 216,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                CupertinoButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: DateTime.now().subtract(
                      const Duration(days: 365 * 25),
                    ), // 25 years ago
                    minimumDate: DateTime.now().subtract(
                      const Duration(days: 365 * 100),
                    ), // 100 years ago
                    maximumDate: DateTime.now().subtract(
                      const Duration(days: 365 * 18),
                    ), // 18 years ago minimum
                    onDateTimeChanged: (DateTime newDate) {},
                  ),
                ),
                CupertinoButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      DateTime.now().subtract(
                        const Duration(days: 365 * 25),
                      ),
                    );
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null && context.mounted) {
      final age = DateTime.now().year - picked.year;
      final monthDiff = DateTime.now().month - picked.month;
      final dayDiff = DateTime.now().day - picked.day;
      final actualAge = monthDiff < 0 || (monthDiff == 0 && dayDiff < 0)
          ? age - 1
          : age;

      if (actualAge < 18) {
        _showCupertinoAlert('You must be at least 18 years old to use Aroosi');
        _birthDate.clear();
      } else {
        setState(() {
          _birthDate.text =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        });
      }
    }
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
                      color: CupertinoColors.systemRed,
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
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 280),
              beginOffset: const Offset(0, 0.14),
              child: GestureDetector(
                onTap: _selectBirthDate,
                child: CupertinoTextField(
                  controller: _birthDate,
                  placeholder: 'Date of Birth*',
                  prefix: const Icon(
                    CupertinoIcons.calendar,
                    size: 20,
                    color: CupertinoColors.systemGrey,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabled: false,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeIn(
              delay: const Duration(milliseconds: 300),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CupertinoColors.systemOrange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_triangle_fill,
                      color: CupertinoColors.systemOrange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '18+ Only: You must be 18 years or older to use Aroosi',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeScaleIn(
              delay: AppMotionDurations.fast,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: CupertinoColors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CupertinoButton(
                  onPressed: auth.loading
                      ? null
                      : () {
                          logNav('signup_screen: Apple sign up pressed');
                          authCtrl.loginWithApple();
                        },
                  color: CupertinoColors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        CupertinoIcons.device_phone_portrait,
                        color: CupertinoColors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Sign up with Apple',
                        style: TextStyle(
                          color: CupertinoColors.white,
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
            FadeScaleIn(
              delay: AppMotionDurations.fast,
              child: PrimaryButton(
                label: 'Create account with Email',
                loading: auth.loading,
                onPressed: auth.loading
                    ? null
                    : () {
                        // Validate form
                        if (_name.text.trim().isEmpty) {
                          _showCupertinoAlert('Please enter your name');
                          return;
                        }

                        if (_email.text.trim().isEmpty ||
                            !_email.text.contains('@')) {
                          _showCupertinoAlert('Please enter a valid email address');
                          return;
                        }

                        if (_password.text.length < 6) {
                          _showCupertinoAlert('Password must be at least 6 characters');
                          return;
                        }

                        if (_birthDate.text.isEmpty) {
                          _showCupertinoAlert('Please enter your date of birth');
                          return;
                        }

                        // Validate age
                        final birthDateParts = _birthDate.text.split('-');
                        if (birthDateParts.length == 3) {
                          final birthDate = DateTime(
                            int.parse(birthDateParts[0]),
                            int.parse(birthDateParts[1]),
                            int.parse(birthDateParts[2]),
                          );
                          final age = DateTime.now().year - birthDate.year;
                          final monthDiff =
                              DateTime.now().month - birthDate.month;
                          final dayDiff = DateTime.now().day - birthDate.day;
                          final actualAge =
                              monthDiff < 0 || (monthDiff == 0 && dayDiff < 0)
                              ? age - 1
                              : age;

                          if (actualAge < 18) {
                            _showCupertinoAlert('You must be at least 18 years old to use Aroosi');
                            return;
                          }
                        }

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
            const SizedBox(height: 24),
            FadeIn(
              delay: const Duration(milliseconds: 320),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: CupertinoColors.systemGrey3,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'By creating an account, you agree to our',
                          style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: CupertinoColors.systemGrey3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CupertinoButton(
                        onPressed: () =>
                            context.pushNamed('settingsTermsOfService'),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        child: Text(
                          'Terms of Service',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemBlue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Text(
                        ' and ',
                        style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                      ),
                      CupertinoButton(
                        onPressed: () =>
                            context.pushNamed('settingsPrivacyPolicy'),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemBlue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
