import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/features/auth/auth_state.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/widgets/input_field.dart';
import 'package:aroosi_flutter/widgets/primary_button.dart';
import 'package:aroosi_flutter/utils/debug_logger.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  ProviderSubscription<AuthState>? _sub;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _sub = ref.listenManual<AuthState>(authControllerProvider, (prev, next) {
      if (!mounted) return;
      // Success when not loading and no error after resetPassword call
      logNav(
        'reset_password listener: loading=${next.loading} error=${next.error} prevLoading=${prev?.loading}',
      );
      if (!_navigated && !next.loading && next.error == null) {
        _navigated = true;
        logNav('reset_password: success -> navigate /login');
        ToastService.instance.success('Password reset successful');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/login');
        });
      }
    }, fireImmediately: false);
  }

  @override
  void dispose() {
    _sub?.close();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final authCtrl = ref.read(authControllerProvider.notifier);

    return AppScaffold(
      title: 'Reset password',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (auth.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                auth.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          InputField(controller: _email, label: 'Email'),
          const SizedBox(height: 12),
          InputField(
            controller: _password,
            label: 'New password',
            obscure: true,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Reset password',
            loading: auth.loading,
            onPressed: auth.loading
                ? null
                : () {
                    final email = _email.text;
                    final pass = _password.text;
                    logNav(
                      'reset_password: Reset password pressed email=$email',
                    );
                    authCtrl.resetPassword(email, pass);
                  },
          ),
        ],
      ),
    );
  }
}
