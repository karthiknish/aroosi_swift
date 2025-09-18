import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/features/support/support_repository.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _category = 'General';
  bool _includeDiagnostics = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Prefill email from profile if available
    final profile = ref.read(authControllerProvider).profile;
    if (profile?.email != null && profile!.email!.isNotEmpty) {
      _emailCtrl.text = profile.email!;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final repo = SupportRepository();
    final ok = await repo.submitContact(
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      subject: _subjectCtrl.text.trim().isEmpty
          ? null
          : _subjectCtrl.text.trim(),
      category: _category,
      message: _messageCtrl.text.trim(),
      metadata: _includeDiagnostics ? _buildDiagnostics() : null,
    );
    setState(() => _submitting = false);
    if (ok) {
      ToastService.instance.success('Thanks! Our team will get back to you.');
      if (mounted) context.pop();
    } else {
      ToastService.instance.error(
        'Couldn\'t submit right now. Try email instead.',
      );
      _mailtoFallback();
    }
  }

  Map<String, dynamic> _buildDiagnostics() {
    final auth = ref.read(authControllerProvider);
    final userId = auth.profile?.id;
    final plan = auth.profile?.plan ?? 'free';
    return {
      if (userId != null) 'userId': userId,
      'plan': plan,
      'platform': 'flutter',
    };
  }

  void _mailtoFallback() {
    final subject = Uri.encodeComponent(
      _subjectCtrl.text.trim().isEmpty
          ? 'Aroosi Support: $_category'
          : _subjectCtrl.text.trim(),
    );
    final body = Uri.encodeComponent(_messageCtrl.text.trim());
    final email = _emailCtrl.text.trim();
    final mailto =
        'mailto:support@aroosi.app?subject=$subject&body=$body'
        '${email.isNotEmpty ? '&cc=$email' : ''}';
    launchUrlString(mailto);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Support')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Need more help?', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Reach us at support@aroosi.app or fill out the form below.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Your email (optional)',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return null;
                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
                return ok ? null : 'Enter a valid email';
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: const [
                DropdownMenuItem(value: 'General', child: Text('General')),
                DropdownMenuItem(value: 'Billing', child: Text('Billing')),
                DropdownMenuItem(value: 'Technical', child: Text('Technical')),
                DropdownMenuItem(value: 'Safety', child: Text('Safety')),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'General'),
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subjectCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Subject (optional)',
                prefixIcon: Icon(Icons.subject_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageCtrl,
              maxLines: 5,
              minLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'How can we help?',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please describe your issue'
                  : null,
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              value: _includeDiagnostics,
              onChanged: (v) => setState(() => _includeDiagnostics = v),
              title: const Text('Include basic diagnostics'),
              subtitle: const Text('Helps us resolve your issue faster'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/support/ai-chatbot'),
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: const Text('Try AI Chatbot'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _mailtoFallback,
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Email support'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
