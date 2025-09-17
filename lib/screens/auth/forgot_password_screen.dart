import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Enter your email to reset your password.'),
            const SizedBox(height: 8),
            const TextField(decoration: InputDecoration(labelText: 'Email')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Send reset link'),
            ),
          ],
        ),
      ),
    );
  }
}
