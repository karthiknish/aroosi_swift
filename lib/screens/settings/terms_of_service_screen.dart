import 'package:flutter/material.dart';
import 'package:aroosi_flutter/theme/theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          Text(
            'Terms of Service',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Last updated: ${DateTime.now().toString().split(' ')[0]}',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: Spacing.xl),

          _buildSection(
            title: 'Acceptance of Terms',
            content: '''
By accessing and using Aroosi, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.

These Terms of Service constitute the entire agreement between you and Aroosi and govern your use of the service, superseding any prior agreements.
''',
            theme: theme,
          ),

          _buildSection(
            title: 'Description of Service',
            content: '''
Aroosi is a platform that connects individuals for the purpose of finding meaningful relationships and marriage partners. Our services include:

• Profile creation and management
• Search and discovery features
• Communication tools
• Safety and moderation tools

We reserve the right to modify or discontinue our services at any time without prior notice.
''',
            theme: theme,
          ),

          _buildSection(
            title: 'User Accounts',
            content: '''
To use our services, you must:
• Be at least 18 years old
• Provide accurate and complete information
• Maintain the security of your account credentials
• Notify us immediately of any unauthorized use

You are responsible for all activities that occur under your account. You may not transfer your account to another person without our prior written consent.

We reserve the right to terminate accounts that violate these terms or engage in inappropriate behavior.
''',
            theme: theme,
          ),

          _buildSection(
            title: 'User Conduct',
            content: '''
You agree to use Aroosi responsibly and in accordance with applicable laws. You must not:

• Use the service for any illegal or unauthorized purpose
• Harass, abuse, or harm other users
• Share inappropriate, offensive, or harmful content
• Impersonate others or provide false information
• Attempt to gain unauthorized access to our systems
• Use automated tools to access or interact with the service
• Engage in spamming or other disruptive activities

We reserve the right to remove content and suspend accounts that violate these guidelines.
''',
            theme: theme,
          ),

          _buildSection(
            title: 'Content and Intellectual Property',
            content: '''
You retain ownership of content you create and share on Aroosi. By posting content, you grant us a license to use, display, and distribute that content as necessary to provide our services.

Aroosi's content, features, and functionality are protected by copyright, trademark, and other intellectual property laws. You may not reproduce, distribute, or create derivative works without our permission.

You are responsible for ensuring that any content you share does not infringe on third-party rights.
''',
            theme: theme,
          ),

          _buildSection(
            title: 'Privacy and Data Protection',
            content: '''
Your privacy is important to us. Our collection and use of personal information is governed by our Privacy Policy, which is incorporated into these Terms by reference.

We implement reasonable security measures to protect your information, but we cannot guarantee absolute security. You use our services at your own risk.
''',
            theme: theme,
          ),

          _buildSection(
            title: 'Disclaimers and Limitations',
            content: '''
Aroosi is provided "as is" without warranties of any kind. We disclaim all warranties, express or implied, including but not limited to:

• Merchantability and fitness for a particular purpose
• Accuracy or completeness of information
• Uninterrupted or error-free service
• Security of data transmission

We are not responsible for:
• User conduct or content
• Interactions between users
• Third-party websites or services
• Technical failures or data loss

Our liability is limited to the maximum extent permitted by law. In no event shall we be liable for indirect, incidental, or consequential damages.
''',
            theme: theme,
          ),

          _buildSection(
            title: 'Indemnification',
            content: '''
You agree to indemnify and hold harmless Aroosi, its officers, directors, employees, and agents from any claims, damages, losses, or expenses arising from:

• Your use of our services
• Your violation of these terms
• Your infringement of third-party rights
• Any disputes with other users

This indemnification obligation will survive the termination of these terms and your use of the service.
''',
            theme: theme,
          ),

          _buildSection(
            title: 'Termination',
            content: '''
We may terminate or suspend your account and access to our services immediately, without prior notice, for any reason, including if we believe you have violated these terms.

You may terminate your account at any time by contacting us or using the account deletion feature in the app.

Upon termination:
• Your right to use the service ceases immediately
• We may delete your account and data
• Provisions that by their nature should survive will continue to apply
''',
            theme: theme,
          ),

          _buildSection(
            title: 'Governing Law',
            content: '''
These Terms of Service are governed by and construed in accordance with the laws of [Jurisdiction], without regard to conflict of law principles.

Any disputes arising from these terms or your use of our services will be resolved through binding arbitration in accordance with the rules of [Arbitration Organization].

You agree to submit to the exclusive jurisdiction of the courts in [Jurisdiction] for any disputes not subject to arbitration.
''',
            theme: theme,
          ),

          _buildSection(
            title: 'Changes to Terms',
            content: '''
We reserve the right to modify these Terms of Service at any time. We will notify users of material changes by:

• Posting the updated terms on our website
• Sending an email notification
• Displaying a notice in the app

Your continued use of our services after changes become effective constitutes acceptance of the new terms. If you disagree with the updated terms, you must stop using our services.
''',
            theme: theme,
          ),

          _buildSection(
            title: 'Contact Information',
            content: '''
If you have questions about these Terms of Service, please contact us:

Email: legal@aroosi.com
Address: [Company Address]
Phone: [Contact Phone Number]

We will respond to your inquiry within 30 days.
''',
            theme: theme,
          ),

          const SizedBox(height: Spacing.xl),
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Text(
              'These Terms of Service are effective as of the date listed above. By using Aroosi, you acknowledge that you have read, understood, and agree to be bound by these terms.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildSection({
  required String title,
  required String content,
  required ThemeData theme,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: Spacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          content,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    ),
  );
}
