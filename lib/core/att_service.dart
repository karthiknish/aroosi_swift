import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

/// Service for managing App Tracking Transparency (ATT)
class AppTrackingTransparencyService {
  static final AppTrackingTransparencyService _instance = AppTrackingTransparencyService._internal();
  factory AppTrackingTransparencyService() => _instance;
  AppTrackingTransparencyService._internal();

  bool? _trackingStatus;
  final List<VoidCallback> _statusListeners = [];

  /// Initialize ATT service and check current tracking status
  Future<void> initialize() async {
    // Only check ATT on iOS
    if (!Platform.isIOS) {
      _updateStatus(true); // Non-iOS platforms don't need ATT
      return;
    }

    try {
      // Check current tracking authorization status
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      _updateStatus(status == TrackingStatus.authorized);
    } catch (e) {
      debugPrint('Error checking ATT status: $e');
      // Default to false if we can't determine status
      _updateStatus(false);
    }
  }

  /// Request tracking permission from user
  Future<bool> requestTrackingPermission() async {
    // Non-iOS platforms don't need ATT
    if (!Platform.isIOS) {
      return true;
    }

    try {
      final status = await AppTrackingTransparency.requestTrackingAuthorization();
      final isAuthorized = status == TrackingStatus.authorized;
      _updateStatus(isAuthorized);
      return isAuthorized;
    } catch (e) {
      debugPrint('Error requesting ATT permission: $e');
      return false;
    }
  }

  /// Get current tracking authorization status
  Future<TrackingStatus?> getAuthorizationStatus() async {
    try {
      return AppTrackingTransparency.trackingAuthorizationStatus;
    } catch (e) {
      debugPrint('Error getting ATT status: $e');
      return null;
    }
  }

  /// Check if tracking is currently authorized
  bool get isTrackingAuthorized {
    return _trackingStatus ?? false;
  }

  /// Add listener for status changes
  void addStatusListener(VoidCallback listener) {
    _statusListeners.add(listener);
  }

  /// Remove status listener
  void removeStatusListener(VoidCallback listener) {
    _statusListeners.remove(listener);
  }

  void _updateStatus(bool status) {
    if (_trackingStatus != status) {
      _trackingStatus = status;
      for (final listener in _statusListeners) {
        listener();
      }
    }
  }

  /// Get appropriate message for requesting ATT permission
  String getAttRequestMessage() {
    return '''
This app may collect data for the following purposes:

• App performance and crash analytics
• User engagement metrics 
• Subscription and in-app purchase tracking
• Device and app version information

This data helps us improve your experience and provide better service. 
We do not collect personal location data or share your information with third parties for advertising.

You can choose to allow or deny this tracking at any time in your device settings.
Your privacy is important to us.
    ''';
  }

  /// Check if the app should show ATT request
  bool shouldShowAttRequest() {
    // Show ATT request on iOS 14+ when tracking is not authorized
    return Platform.isIOS && !isTrackingAuthorized;
  }

  /// Show native ATT permission dialog
  Future<void> showAttPermissionDialog() async {
    if (!Platform.isIOS) return;

    try {
      await AppTrackingTransparency.requestTrackingAuthorization();
    } catch (e) {
      debugPrint('Error showing ATT dialog: $e');
    }
  }
}
