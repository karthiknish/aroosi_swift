import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/core/responsive.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/core/att_service.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attService = AppTrackingTransparencyService();
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
      ),
      body: ResponsiveBuilder(
        builder: (context, screenType) {
          return ListView(
            padding: Responsive.screenPadding(context).copyWith(top: 16, bottom: 32),
            children: [
              _buildAnalyticsSection(context, attService),
              const SizedBox(height: 24),
              _buildDataSection(context),
              const SizedBox(height: 24),
              _buildAccountSection(context, auth),
              const SizedBox(height: 24),
              _buildLegalSection(context),
            ],
          );
        },
      ),
    );
  }


  Widget _buildAnalyticsSection(
    BuildContext context,
    AppTrackingTransparencyService attService,
  ) {
    return _buildSection(
      context: context,
      title: 'Analytics & Tracking',
      children: [
        _buildSwitchTile(
          context: context,
          title: 'App Tracking Transparency',
          subtitle: 'Control app tracking for personalized ads',
          value: attService.isTrackingAuthorized,
          onChanged: (value) {
            attService.requestTrackingPermission();
          },
          icon: Icons.analytics_outlined,
          color: Colors.blue,
        ),
        _buildInfoTile(
          context: context,
          title: 'Firebase Analytics',
          subtitle: 'Anonymous usage statistics for app improvement',
          icon: Icons.insert_chart_outlined,
          color: Colors.green,
          trailing: Text(
            attService.isTrackingAuthorized ? 'Enabled' : 'Disabled',
            style: TextStyle(
              color: attService.isTrackingAuthorized
                  ? Colors.green
                  : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataSection(BuildContext context) {
    return _buildSection(
      context: context,
      title: 'Data & Privacy',
      children: [
        _buildActionTile(
          context: context,
          title: 'Privacy Policy',
          subtitle: 'Read our complete privacy policy',
          icon: Icons.privacy_tip_outlined,
          color: Colors.purple,
          onTap: () => GoRouter.of(context).pushNamed('privacyPolicy'),
        ),
        _buildActionTile(
          context: context,
          title: 'Download My Data',
          subtitle: 'Request a copy of your personal data',
          icon: Icons.download_outlined,
          color: Colors.blue,
          onTap: () => _showDataDownloadDialog(context),
        ),
        _buildActionTile(
          context: context,
          title: 'Clear Cache',
          subtitle: 'Remove local app data from your device',
          icon: Icons.cleaning_services_outlined,
          color: Colors.orange,
          onTap: () => _showClearCacheDialog(context),
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context, dynamic auth) {
    return _buildSection(
      context: context,
      title: 'Account Control',
      children: [
        _buildActionTile(
          context: context,
          title: 'Profile Visibility',
          subtitle: 'Manage who can see your profile',
          icon: Icons.visibility_outlined,
          color: Colors.teal,
          onTap: () => GoRouter.of(context).pushNamed('mainEditProfile'),
        ),
        _buildActionTile(
          context: context,
          title: 'Blocked Users',
          subtitle: 'Manage users you\'ve blocked',
          icon: Icons.block_outlined,
          color: Colors.red,
          onTap: () => GoRouter.of(context).pushNamed('blockedUsers'),
        ),
      ],
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    return _buildSection(
      context: context,
      title: 'Legal',
      children: [
        _buildActionTile(
          context: context,
          title: 'Terms of Service',
          subtitle: 'Read our terms and conditions',
          icon: Icons.description_outlined,
          color: Colors.indigo,
          onTap: () => _showTermsDialog(context),
        ),
        _buildActionTile(
          context: context,
          title: 'Data Processing',
          subtitle: 'GDPR-compliant data processing information',
          icon: Icons.gavel_outlined,
          color: Colors.brown,
          onTap: () => _showDataProcessingDialog(context),
        ),
      ],
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.screenPadding(context).left,
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: Responsive.screenPadding(context).left,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: color.withValues(alpha: 0.5),
        activeThumbColor: color,
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }

  void _showDataDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Data Download'),
        content: const Text(
          'We\'ll prepare a complete copy of your personal data and send it to your registered email address within 30 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data download request submitted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear App Cache'),
        content: const Text(
          'This will clear temporary data stored on your device. Your account and cloud data will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement cache clearing logic here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using Aroosi, you agree to:\n\n'
            '1. Be honest and authentic in your profile\n'
            '2. Respect other users\n'
            '3. Follow Afghan laws and cultural norms\n'
            '4. Not share inappropriate content\n'
            '5. Use the platform for legitimate dating purposes\n\n'
            'Full terms available at: https://aroosi.af/terms',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDataProcessingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Processing'),
        content: const SingleChildScrollView(
          child: Text(
            'We process your data for:\n\n'
            '• Service provision and improvement\n'
            '• Security and fraud prevention\n'
            '• Legal compliance\n'
            '• Analytics with your consent\n\n'
            'We use industry-standard security measures and never sell your data to third parties.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}
