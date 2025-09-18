import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
// auth_state imported via controller state, no direct usage here

class EmailVerificationBanner extends ConsumerStatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  ConsumerState<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState
    extends ConsumerState<EmailVerificationBanner> {
  int _cooldown = 0;
  Timer? _timer;
  bool _checking = false;
  bool _sending = false;
  bool _dismissed = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _cooldown = (_cooldown - 1).clamp(0, 60);
        if (_cooldown == 0) {
          _timer?.cancel();
          _timer = null;
        }
      });
    });
  }

  Future<void> _resend() async {
    if (_sending || _cooldown > 0) return;
    setState(() => _sending = true);
    try {
      final ok = await ref
          .read(authControllerProvider.notifier)
          .resendEmailVerification();
      if (ok) {
        ToastService.instance.info('Verification email sent');
        _startCooldown();
      } else {
        ToastService.instance.error('Failed to send verification email');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final verified = await ref
          .read(authControllerProvider.notifier)
          .refreshAndCheckEmailVerified();
      if (verified) {
        ToastService.instance.success('Email verified!');
      } else {
        ToastService.instance.info('Still unverified. Try again shortly.');
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final auth = ref.watch(authControllerProvider);
    final profile = auth.profile;

    final needs =
        auth.isAuthenticated && (profile?.needsEmailVerification ?? false);
    if (!needs) return const SizedBox.shrink();

    final email = profile?.email ?? '';
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme
            .tertiaryContainer, // use tertiary as a warning-like container
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.mark_email_unread_outlined,
            color: scheme.onTertiaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify your email',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email.isNotEmpty
                      ? 'We\'ve sent a verification link to $email. Please verify to unlock all features.'
                      : 'We\'ve sent a verification link. Please verify to unlock all features.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: (_cooldown > 0 || _sending) ? null : _resend,
                      child: _sending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _cooldown > 0
                                  ? 'Resend (${_cooldown}s)'
                                  : 'Resend email',
                            ),
                    ),
                    FilledButton(
                      onPressed: _checking ? null : _check,
                      child: _checking
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('I have verified'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            onPressed: () => setState(() => _dismissed = true),
            icon: Icon(Icons.close, color: scheme.onTertiaryContainer),
          ),
        ],
      ),
    );
  }
}
