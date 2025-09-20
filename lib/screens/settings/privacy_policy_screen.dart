import 'package:flutter/material.dart';
import 'package:aroosi_flutter/theme/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          Text(
            'Privacy Policy',
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
            title: 'Information We Collect',
            content: '''
We collect information you provide directly to us, such as when you create an account, update your profile, or contact us for support.

Personal Information:
• Name, email address, and phone number
• Profile information (photos, bio, preferences)
• Location data (city, country)
• Usage data and preferences

Automatically Collected Information:
• Device information (type, OS, app version)
• Usage statistics and app performance data
• IP address and location data for security
''',
            theme: theme,
          ),

          _buildSection(
            title: 'How We Use Your Information',
            content: '''
We use the information we collect to:
• Provide, maintain, and improve our services
• Process transactions and send related information
• Send technical notices and support messages
• Communicate with you about products, services, and events
• Monitor and analyze trends, usage, and activities
• Personalize your experience and provide tailored content
• Detect, investigate, and prevent fraudulent transactions
''',
            theme: theme,
          ),

          _buildSection(
            title: 'Information Sharing',
            content: '''
We do not sell, trade, or rent your personal information to third parties. We may share your information only in the following circumstances:

• With your consent
• To comply with legal obligations
• To protect our rights and prevent fraud
• With service providers who assist us in operating our platform
• In connection with a business transfer or acquisition
''',
            theme: theme,
          ),

          _buildSection(
            title: 'Data Security',
            content: '''
We implement appropriate technical and organizational security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. These measures include:

• Encryption of data in transit and at rest
• Regular security assessments and updates
• Access controls and authentication procedures
• Secure data centers and cloud infrastructure
''',
            theme: theme,
          ),

          _buildSection(
            title: 'Your Rights',
            content: '''
You have the following rights regarding your personal information:
• Access: Request a copy of your personal data
• Rectification: Request correction of inaccurate data
• Erasure: Request deletion of your personal data
• Portability: Request transfer of your data
• Restriction: Request limitation of processing
• Objection: Object to processing based on legitimate interests

To exercise these rights, please contact us using the information provided below.
''',
            theme: theme,
          ),

          _buildSection(
            title: 'Data Retention',
            content: '''
We retain your personal information for as long as necessary to provide our services and fulfill the purposes outlined in this policy, unless a longer retention period is required by law.

Account data is retained until you delete your account or request data deletion. Some data may be retained for legal, regulatory, or legitimate business purposes.
''',
            theme: theme,
          ),

          _buildSection(
            title: 'International Data Transfers',
            content: '''
Your information may be transferred to and processed in countries other than your country of residence. We ensure that such transfers comply with applicable data protection laws and implement appropriate safeguards.
''',
            theme: theme,
          ),

          _buildSection(
            title: 'Cookies and Tracking',
            content: '''
We use cookies and similar technologies to enhance your experience, analyze usage patterns, and improve our services. You can control cookie settings through your device or browser preferences.

We may also use third-party analytics services to understand how our app is used and to improve our services.
''',
            theme: theme,
          ),

          _buildSection(
            title: 'Third-Party Services',
            content: '''
Our app may contain links to third-party websites or integrate with third-party services. We are not responsible for the privacy practices of these third parties. We encourage you to review their privacy policies before providing any personal information.
''',
            theme: theme,
          ),

          _buildSection(
            title: 'Children's Privacy',
            content: '''
Our services are not intended for children under 18 years of age. We do not knowingly collect personal information from children under 18. If we become aware that we have collected personal information from a child under 18, we will take steps to delete such information.
''',
            theme: theme,
          ),

          _buildSection(
            title: 'Changes to This Policy',
            content: '''
We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date. We encourage you to review this Privacy Policy periodically.
''',
            theme: theme,
          ),

          _buildSection(
            title: 'Contact Us',
            content: '''
If you have any questions about this Privacy Policy or our data practices, please contact us at:

Email: privacy@aroosi.com
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
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Text(
              'This privacy policy is effective as of the date listed above and applies to all users of the Aroosi platform.',
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