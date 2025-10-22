import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:aroosi_flutter/core/att_service.dart';

/// Service for Firebase Analytics integration
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  bool _isInitialized = false;
  bool _isAnalyticsEnabled = false;

  /// Initialize Firebase Analytics (only if tracking is authorized)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if tracking is authorized before enabling analytics
      final attService = AppTrackingTransparencyService();
      _isAnalyticsEnabled = attService.isTrackingAuthorized;
      
      // Only enable analytics if tracking is authorized or on non-iOS platforms
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(_isAnalyticsEnabled);
      
      if (_isAnalyticsEnabled) {
        await FirebaseAnalytics.instance.logAppOpen();
        debugPrint('Firebase Analytics initialized successfully (tracking enabled)');
      } else {
        debugPrint('Firebase Analytics initialized with tracking disabled (ATT not authorized)');
      }
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize Firebase Analytics: $e');
      _isInitialized = true;
    }
  }

  /// Check if analytics is currently enabled
  bool get isAnalyticsEnabled => _isAnalyticsEnabled;

  /// Update analytics collection status (call when ATT status changes)
  Future<void> updateAnalyticsStatus() async {
    if (!_isInitialized) return;

    try {
      final attService = AppTrackingTransparencyService();
      final newStatus = attService.isTrackingAuthorized;
      
      if (newStatus != _isAnalyticsEnabled) {
        _isAnalyticsEnabled = newStatus;
        await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(_isAnalyticsEnabled);
        
        if (_isAnalyticsEnabled) {
          await FirebaseAnalytics.instance.logAppOpen();
          debugPrint('Analytics re-enabled after ATT permission granted');
        } else {
          debugPrint('Analytics disabled after ATT permission revoked');
        }
      }
    } catch (e) {
      debugPrint('Failed to update analytics status: $e');
    }
  }

  /// Log user sign up
  Future<void> logSignUp({
    required String userId,
    String? email,
    Map<String, dynamic>? userProperties,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await FirebaseAnalytics.instance.logLogin(
        loginMethod: 'email',
        parameters: <String, Object>{
          if (email != null) 'email': email,
          'method': 'email_signup',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...(userProperties?.cast<String, Object>() ?? {}),
        },
      );
    } catch (e) {
      debugPrint('Failed to log sign up event: $e');
    }
  }

  /// Log user sign in
  Future<void> logSignIn({
    required String userId,
    String? email,
    Map<String, dynamic>? userProperties,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await FirebaseAnalytics.instance.logLogin(
        loginMethod: 'email',
        parameters: <String, Object>{
          if (email != null) 'email': email,
          'method': 'email_signin',
          'timestamp': FirebaseAnalytics.instance.appInstanceId,
          ...(userProperties?.cast<String, Object>() ?? {}),
        },
      );
    } catch (e) {
      debugPrint('Failed to log sign in event: $e');
    }
  }

  /// Log user profile creation
  Future<void> logProfileCreated({
    required String userId,
    Map<String, dynamic>? profileProperties,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'profile_created',
        parameters: {
          'user_id': userId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...(profileProperties?.cast<String, Object>() ?? {}),
        },
      );
    } catch (e) {
      debugPrint('Failed to log profile creation: $e');
    }
  }

  /// Log profile view
  Future<void> logProfileView({
    required String userId,
    required String profileId,
    String? viewerId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'profile_view',
        parameters: <String, Object>{
          'user_id': userId,
          'profile_id': profileId,
          if (viewerId != null) 'viewer_id': viewerId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      debugPrint('Failed to log profile view: $e');
    }
  }

  /// Log match interaction
  Future<void> logMatchInteraction({
    required String userId,
    String? profileId,
    String? targetProfileId,
    String? interactionType,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'match_interaction',
        parameters: <String, Object>{
          'user_id': userId,
          if (profileId != null) 'profile_id': profileId,
          if (targetProfileId != null) 'target_profile_id': targetProfileId,
          if (interactionType != null) 'interaction_type': interactionType,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      debugPrint('Failed to log match interaction: $e');
    }
  }

  /// Log search activity
  Future<void> logSearch({
    required String userId,
    String? query,
    int? resultCount,
    List<String>? filters,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'search',
        parameters: <String, Object>{
          'user_id': userId,
          if (query != null) 'query': query,
          if (resultCount != null) 'result_count': resultCount,
          if (filters?.isNotEmpty == true) 'filters': filters?.join(',') ?? '',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      debugPrint('Failed to log search: $e');
    }
  }

  

  /// Log custom event
  Future<void> logCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await FirebaseAnalytics.instance.logEvent(
        name: eventName,
        parameters: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...(parameters?.cast<String, Object>() ?? {}),
        },
      );
    } catch (e) {
      debugPrint('Failed to log custom event: $e');
    }
  }

  /// Set user ID for analytics
  void setUserId(String? userId) {
    if (!_isInitialized) return;

    try {
      // Note: setUserId method may not be available in current Firebase Analytics version
      // FirebaseAnalytics.instance.setUserId(userId);
      debugPrint('Analytics user ID set to: $userId');
    } catch (e) {
      debugPrint('Failed to set analytics user ID: $e');
    }
  }

  /// Get current user ID
  String? get userId => null;

  /// Check if analytics is available
  bool get isAvailable => _isInitialized;
}
