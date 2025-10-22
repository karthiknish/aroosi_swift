import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/core/push_notification_service.dart';
import 'package:aroosi_flutter/core/responsive.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _pushEnabled = false;
  bool _isLoading = true;
  late PushNotificationService _pushService;

  @override
  void initState() {
    super.initState();
    _pushService = ref.read(pushNotificationServiceProvider);
    _loadNotificationStatus();
  }

  Future<void> _loadNotificationStatus() async {
    try {
      final enabled = await _pushService.isNotificationEnabled();
      if (mounted) {
        setState(() {
          _pushEnabled = enabled;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notification status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _togglePushNotifications(bool value) async {
    setState(() {
      _pushEnabled = value;
    });

    try {
      if (value && !_pushService.hasUserConsent) {
        // Show consent dialog if user hasn't given consent yet
        final consent = await _pushService.showNotificationConsentDialog(
          context,
        );
        if (!consent) {
          // User denied consent, revert toggle
          if (mounted) {
            setState(() {
              _pushEnabled = false;
            });
          }
          return;
        }
      }

      await _pushService.setNotificationEnabled(value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Push notifications enabled'
                  : 'Push notifications disabled',
            ),
            backgroundColor: value ? Colors.green : Colors.grey,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error toggling push notifications: $e');
      if (mounted) {
        setState(() {
          _pushEnabled = !value; // Revert on error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to change notification settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.pink.withValues(alpha: 0.1),
                Colors.pink.withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: Responsive.screenPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildAPNsDisclosure(),
                  const SizedBox(height: 32),
                  _buildNotificationTypes(),
                  const SizedBox(height: 32),
                  _buildAppNotificationSettings(),
                ],
              ),
            ),
    );
  }

  Widget _buildAPNsDisclosure() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.apple, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Apple Push Notification Service (APNs)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Aroosi uses Apple\'s Push Notification service to deliver important app notifications. We only use APNs for:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ...[
            '• New matches and likes',
            '• Messages from other users',
            '• Profile activity notifications',
            '• Important app updates and security alerts',
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text(
                item,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your privacy is protected. We do not collect personal data through APNs beyond what\'s necessary for notification delivery.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTypes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Push Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
          child: SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.pink, size: 20),
                const SizedBox(width: 12),
                const Text('Enable Push Notifications'),
              ],
            ),
            subtitle: const Text(
              'Get notified about matches, messages, and activity',
            ),
            value: _pushEnabled,
            onChanged: _togglePushNotifications,
            activeThumbColor: Colors.pink,
          ),
        ),
        const SizedBox(height: 16),
        if (!_pushService.hasUserConsent)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade700,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Tap enable to see what notifications we use and provide consent',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAppNotificationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification Types',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...[
          {
            'icon': Icons.favorite,
            'title': 'Matches & Likes',
            'description':
                'When someone matches with you or likes your profile',
            'color': Colors.pink,
          },
          {
            'icon': Icons.chat,
            'title': 'Messages',
            'description': 'New messages from your matches',
            'color': Colors.blue,
          },
          {
            'icon': Icons.visibility,
            'title': 'Profile Views',
            'description': 'When someone views your profile',
            'color': Colors.green,
          },
          {
            'icon': Icons.announcement,
            'title': 'App Updates',
            'description': 'Important announcements and security updates',
            'color': Colors.orange,
          },
        ].map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['description'] as String,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(
                  _pushEnabled ? 'Active' : 'Disabled',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _pushEnabled ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
