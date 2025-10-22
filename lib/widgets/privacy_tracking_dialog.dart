import 'package:flutter/material.dart';

import '../core/att_service.dart';

/// Dialog for requesting App Tracking Transparency permission
class PrivacyTrackingDialog extends StatefulWidget {
  const PrivacyTrackingDialog({super.key});

  @override
  State<PrivacyTrackingDialog> createState() => _PrivacyTrackingDialogState();
}

class _PrivacyTrackingDialogState extends State<PrivacyTrackingDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        'Privacy & Tracking',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            AppTrackingTransparencyService().getAttRequestMessage(),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'What we track:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...[
                  '• App usage patterns and crashes',
                  '• Device and app version information',
                  '• General app performance metrics',
                ].map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(item, style: theme.textTheme.bodySmall),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can change your tracking preferences at any time in your device settings.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Maybe Later'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : () => _requestPermissionAndContinue(),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Allow Tracking'),
        ),
      ],
    );
  }

  Future<void> _requestPermissionAndContinue() async {
    final theme = Theme.of(context);
    setState(() => _isLoading = true);

    try {
      final granted = await AppTrackingTransparencyService()
          .requestTrackingPermission();

      if (granted && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Thank you for enabling tracking. This helps us improve the app.',
            ),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.of(context).pop();
      } else if (mounted) {
        // User denied or didn't grant permission
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error requesting ATT permission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process permission request'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Dialog for privacy settings and preferences
class PrivacySettingsDialog extends StatelessWidget {
  const PrivacySettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        'Privacy Settings',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Manage your privacy preferences and tracking permissions.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(
              AppTrackingTransparencyService().isTrackingAuthorized
                  ? Icons.check_circle
                  : Icons.privacy_tip_outlined,
              color: AppTrackingTransparencyService().isTrackingAuthorized
                  ? Colors.green
                  : theme.colorScheme.onSurfaceVariant,
            ),
            title: const Text('App Tracking'),
            subtitle: Text(
              AppTrackingTransparencyService().isTrackingAuthorized
                  ? 'Tracking is enabled'
                  : 'Tracking is disabled',
            ),
            trailing: Switch(
              value: AppTrackingTransparencyService().isTrackingAuthorized,
              onChanged: (value) async {
                if (value) {
                  await AppTrackingTransparencyService()
                      .showAttPermissionDialog();
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            subtitle: const Text('Read our full privacy policy'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              Navigator.of(context).pop();
              // Navigate to privacy policy
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Device Settings'),
            subtitle: const Text('Manage app permissions'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
