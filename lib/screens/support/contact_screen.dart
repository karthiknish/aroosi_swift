import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/features/support/support_repository.dart';
import 'package:aroosi_flutter/theme/colors.dart';
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

  BoxDecoration cupertinoDecoration(
    BuildContext context, {
    bool hasError = false,
  }) {
    return BoxDecoration(
      color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      border: Border.all(
        color: hasError ? CupertinoColors.destructiveRed : AppColors.primary,
        width: 1.5,
      ),
      borderRadius: BorderRadius.circular(10.0),
    );
  }

  Padding cupertinoFieldPadding(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child,
    );
  }

  Future<void> _showCategoryPicker() async {
    String? selectedCategory = _category;

    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Done'),
                    onPressed: () {
                      setState(() => _category = selectedCategory ?? 'General');
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: [
                    'General',
                    'Billing',
                    'Technical',
                    'Safety',
                  ].indexOf(_category),
                ),
                onSelectedItemChanged: (int index) {
                  selectedCategory = [
                    'General',
                    'Billing',
                    'Technical',
                    'Safety',
                  ][index];
                },
                children: const [
                  Center(child: Text('General')),
                  Center(child: Text('Billing')),
                  Center(child: Text('Technical')),
                  Center(child: Text('Safety')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    // Manual validation
    final email = _emailCtrl.text.trim();
    if (email.isNotEmpty) {
      final emailValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
      if (!emailValid) {
        ToastService.instance.error('Please enter a valid email address');
        return;
      }
    }

    final message = _messageCtrl.text.trim();
    if (message.isEmpty) {
      ToastService.instance.error('Please describe your issue');
      return;
    }

    setState(() => _submitting = true);
    final repo = SupportRepository();
    final ok = await repo.submitContact(
      email: email.isEmpty ? null : email,
      subject: _subjectCtrl.text.trim().isEmpty
          ? null
          : _subjectCtrl.text.trim(),
      category: _category,
      message: message,
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
            Container(
              decoration: cupertinoDecoration(context),
              child: cupertinoFieldPadding(
                CupertinoTextField(
                  controller: _emailCtrl,
                  placeholder: 'Your email (optional)',
                  keyboardType: TextInputType.emailAddress,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: Icon(CupertinoIcons.mail),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: Colors.transparent),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showCategoryPicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: cupertinoDecoration(context).copyWith(
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(CupertinoIcons.tag),
                    ),
                    Expanded(
                      child: Text(
                        _category,
                        style: TextStyle(
                          color: CupertinoTheme.of(
                            context,
                          ).textTheme.textStyle.color,
                        ),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_down,
                      size: 16,
                      color: CupertinoColors.systemGrey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: cupertinoDecoration(context),
              child: cupertinoFieldPadding(
                CupertinoTextField(
                  controller: _subjectCtrl,
                  placeholder: 'Subject (optional)',
                  textCapitalization: TextCapitalization.sentences,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: Icon(CupertinoIcons.text_bubble),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: Colors.transparent),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: cupertinoDecoration(context),
              child: cupertinoFieldPadding(
                CupertinoTextField(
                  controller: _messageCtrl,
                  placeholder: 'How can we help?',
                  maxLines: 5,
                  minLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: Colors.transparent),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Include basic diagnostics'),
                      Text(
                        'Helps us resolve your issue faster',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: _includeDiagnostics,
                  onChanged: (v) => setState(() => _includeDiagnostics = v),
                ),
              ],
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
