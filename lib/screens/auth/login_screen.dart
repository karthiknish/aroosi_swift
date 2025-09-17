import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_controller.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (auth.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(auth.error!, style: const TextStyle(color: Colors.red)),
              ),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: auth.loading
                  ? null
                  : () async {
                      await authCtrl.login(_email.text, _password.text);
                      if (context.mounted && ref.read(authControllerProvider).isAuthenticated) {
                        if (!context.mounted) return;
                        context.go('/dashboard');
                      }
                    },
              child: auth.loading ? const CircularProgressIndicator() : const Text('Sign in'),
            ),
            TextButton(
              onPressed: () => context.go('/forgot'),
              child: const Text('Forgot password?'),
            ),
            TextButton(
              onPressed: () => context.go('/signup'),
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}
