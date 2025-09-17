import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final authCtrl = ref.read(authControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(auth.isAuthenticated ? 'Logged in' : 'Logged out'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: auth.isAuthenticated ? () async {
                await authCtrl.logout();
              } : null,
              child: const Text('Logout'),
            )
          ],
        ),
      ),
    );
  }
}
