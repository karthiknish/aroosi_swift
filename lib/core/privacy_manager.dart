
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'att_service.dart';
import 'analytics_service.dart';
import '../widgets/privacy_tracking_dialog.dart';

/// Service for managing privacy and tracking compliance
class PrivacyManager {
  static final PrivacyManager _instance = PrivacyManager._internal();
  factory PrivacyManager() => _instance;
  PrivacyManager._internal();

  final AppTrackingTransparencyService _attService = AppTrackingTransparencyService();

  bool _isInitialized = false;
  bool _hasRequestedPermission = false;

  /// Initialize privacy services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize ATT service
      await _attService.initialize();
      
      // Initialize analytics service (will respect ATT permissions)
      await AnalyticsService().initialize();
      
      // Load saved preference
      final prefs = await SharedPreferences.getInstance();
      _hasRequestedPermission = prefs.getBool('has_requested_att_permission') ?? false;
      
      // Listen for ATT status changes and update analytics accordingly
      _attService.addStatusListener(_onAttStatusChanged);
      
      _isInitialized = true;
      debugPrint('PrivacyManager initialized');
    } catch (e) {
      debugPrint('Error initializing PrivacyManager: $e');
    }
  }

  /// Handle ATT status changes
  void _onAttStatusChanged() {
    // Update analytics collection status when ATT permission changes
    AnalyticsService().updateAnalyticsStatus();
  }

  /// Check if ATT permission is needed
  bool needsAttPermission() {
    return _attService.shouldShowAttRequest() && !_hasRequestedPermission;
  }

  /// Show ATT permission dialog
  Future<bool> requestAttPermission() async {
    _hasRequestedPermission = true;
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_requested_att_permission', true);

    return await _attService.requestTrackingPermission();
  }

  /// Check if tracking is authorized
  bool get isTrackingAuthorized => _attService.isTrackingAuthorized;

  /// Show privacy tracking dialog
  Future<bool> showPrivacyDialog() async {
    return await showDialog<bool>(
      context: navigatorKey.currentContext!,
      builder: (context) => const PrivacyTrackingDialog(),
    ) ?? false;
  }

  /// Show privacy settings dialog
  Future<void> showPrivacySettings() async {
    await showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => const PrivacySettingsDialog(),
    );
  }

  /// Reset privacy preferences (for testing)
  Future<void> resetPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_requested_att_permission');
    _hasRequestedPermission = false;
  }
}

/// Provider for privacy management
final privacyManagerProvider = Provider<PrivacyManager>((ref) {
  return PrivacyManager();
});

/// Global navigator key for showing dialogs outside of widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
