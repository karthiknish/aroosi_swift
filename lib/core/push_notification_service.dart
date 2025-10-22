import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/utils/debug_logger.dart';

/// Service for managing push notifications and APNs compliance
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _keyNotificationConsent = 'push_notification_consent';
  static const String _keyNotificationToken = 'notification_token';
  static const String _keyNotificationEnabled = 'notification_enabled';

  bool _isInitialized = false;
  bool _hasUserConsent = false;
  String? _deviceToken;

  /// Initialize the push notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      logDebug('Initializing Push Notification Service...');

      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: false, // We'll request permissions manually
            requestBadgePermission: false,
            requestSoundPermission: false,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Initialize Firebase Messaging
      await _initializeFirebaseMessaging();

      // Load user consent preference
      await _loadUserConsent();

      _isInitialized = true;
      logDebug('Push Notification Service initialized successfully');
    } catch (e) {
      logDebug('Failed to initialize Push Notification Service', error: e);
    }
  }

  /// Initialize Firebase Messaging settings
  Future<void> _initializeFirebaseMessaging() async {
    // Request permission for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: false, // We'll handle this in our consent flow
      badge: false,
      sound: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    logDebug(
      'Firebase Messaging permission status',
      data: settings.authorizationStatus,
    );

    // Get the device token
    _deviceToken = await _firebaseMessaging.getToken();
    if (_deviceToken != null) {
      logDebug('FCM Token obtained', data: _deviceToken);
      await _saveDeviceToken(_deviceToken!);
    }

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      logDebug('FCM Token refreshed', data: token);
      _saveDeviceToken(token);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  }

  /// Show push notification consent dialog
  Future<bool> showNotificationConsentDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            const Text('Push Notification Consent'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aroosi uses push notifications to provide a better dating experience:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildNotificationPurpose(
                'New Matches',
                'Get notified when someone matches with you',
                Icons.favorite,
                Colors.pink,
              ),
              _buildNotificationPurpose(
                'Messages',
                'Never miss important conversations',
                Icons.chat,
                Colors.blue,
              ),
              _buildNotificationPurpose(
                'Profile Views',
                'Know when someone views your profile',
                Icons.visibility,
                Colors.green,
              ),
              _buildNotificationPurpose(
                'App Updates',
                'Important safety and feature announcements',
                Icons.announcement,
                Colors.orange,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.privacy_tip, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Your privacy is important. We only use notifications for the app features above. You can disable them anytime in Settings.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              if (Platform.isIOS) ...[
                const SizedBox(height: 12),
                const Text(
                  'Note: Notifications use Apple Push Notification service (APNs) for instant delivery.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enable Notifications'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _saveUserConsent(true);
      await requestNotificationPermissions();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications enabled successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      await _saveUserConsent(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can enable notifications later in Settings'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    return result ?? false;
  }

  Widget _buildNotificationPurpose(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Request notification permissions from the user
  Future<bool> requestNotificationPermissions() async {
    try {
      // Request Android permissions
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        if (status != PermissionStatus.granted) {
          return false;
        }
      }

      // Request Firebase messaging permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      logDebug(
        'Notification permission status',
        data: settings.authorizationStatus,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      logDebug('Error requesting notification permissions', error: e);
      return false;
    }
  }

  /// Enable/disable push notifications
  Future<void> setNotificationEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNotificationEnabled, enabled);

      if (enabled && _hasUserConsent) {
        await enableNotifications();
      } else {
        await disableNotifications();
      }
    } catch (e) {
      logDebug('Error setting notification enabled', error: e);
    }
  }

  /// Enable notifications
  Future<void> enableNotifications() async {
    try {
      final granted = await requestNotificationPermissions();
      if (granted && _deviceToken != null) {
        // Here you would send the token to your backend
        await _subscribeToTopics();
        logDebug('Notifications enabled', data: _deviceToken);
      }
    } catch (e) {
      logDebug('Error enabling notifications', error: e);
    }
  }

  /// Disable notifications
  Future<void> disableNotifications() async {
    try {
      await _firebaseMessaging.deleteToken();
      await _unsubscribeFromTopics();
      logDebug('Notifications disabled');
    } catch (e) {
      logDebug('Error disabling notifications', error: e);
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    logDebug('Received foreground message', data: message.messageId);

    // Show local notification for foreground messages
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'aroosi_high_importance_channel',
          'Aroosi Notifications',
          channelDescription: 'Important notifications from Aroosi dating app',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  /// Handle notification taps
  Future<void> _handleMessageTap(RemoteMessage message) async {
    logDebug('Notification tapped', data: message.messageId);
    // Navigate to appropriate screen based on message data
    if (message.data['screen'] != null) {
      // Handle navigation
    }
  }

  /// Handle local notification taps
  void _onNotificationTapped(NotificationResponse response) {
    logDebug('Local notification tapped', data: response.payload);
    // Handle navigation from local notification
  }

  /// Subscribe to notification topics
  Future<void> _subscribeToTopics() async {
    try {
      await _firebaseMessaging.subscribeToTopic('all_users');
      await _firebaseMessaging.subscribeToTopic('matches');
      await _firebaseMessaging.subscribeToTopic('messages');
      logDebug('Subscribed to notification topics');
    } catch (e) {
      logDebug('Error subscribing to topics', error: e);
    }
  }

  /// Unsubscribe from notification topics
  Future<void> _unsubscribeFromTopics() async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('all_users');
      await _firebaseMessaging.unsubscribeFromTopic('matches');
      await _firebaseMessaging.unsubscribeFromTopic('messages');
      logDebug('Unsubscribed from notification topics');
    } catch (e) {
      logDebug('Error unsubscribing from topics', error: e);
    }
  }

  /// Save user consent
  Future<void> _saveUserConsent(bool consent) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNotificationConsent, consent);
      _hasUserConsent = consent;
      logDebug('Push notification consent saved', data: consent);
    } catch (e) {
      logDebug('Error saving notification consent', error: e);
    }
  }

  /// Load user consent
  Future<void> _loadUserConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasUserConsent = prefs.getBool(_keyNotificationConsent) ?? false;
      logDebug('Push notification consent loaded', data: _hasUserConsent);
    } catch (e) {
      logDebug('Error loading notification consent', error: e);
      _hasUserConsent = false;
    }
  }

  /// Save device token
  Future<void> _saveDeviceToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyNotificationToken, token);
      _deviceToken = token;
    } catch (e) {
      logDebug('Error saving device token', error: e);
    }
  }

  /// Check if user has given consent
  bool get hasUserConsent => _hasUserConsent;

  /// Check if notifications are enabled
  Future<bool> isNotificationEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyNotificationEnabled) ?? false;
    } catch (e) {
      logDebug('Error checking notification enabled', error: e);
      return false;
    }
  }

  /// Check if notification consent is needed
  bool get needsConsent => !_hasUserConsent;

  /// Get device token
  String? get deviceToken => _deviceToken;
}

/// Provider for push notification service
final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return PushNotificationService();
});
