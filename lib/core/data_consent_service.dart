import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ConsentStatus { unknown, pending, granted, denied }

enum ConsentType {
  analytics,
  marketing,
  personalization,
  communication,
  location,
}

/// Service for managing user data consent and privacy preferences
class DataConsentService {
  static final DataConsentService _instance = DataConsentService._internal();
  factory DataConsentService() => _instance;
  DataConsentService._internal();

  static const String _keyConsentStatus = 'data_consent_status';
  static const String _keyAnalyticsConsent = 'analytics_consent';
  static const String _keyMarketingConsent = 'marketing_consent';
  static const String _keyPersonalizationConsent = 'personalization_consent';
  static const String _keyCommunicationConsent = 'communication_consent';
  static const String _keyPlayerLocationConsent = 'player_location_consent';

  bool _isInitialized = false;

  /// Initialize service and load saved consent preferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      print('Loading data consent preferences...');

      // Initialize default consent for first-time users
      if (!prefs.containsKey(_keyConsentStatus)) {
        print('First-time user - setting default consent to pending');
        await updateConsentStatus(ConsentStatus.pending);
      }

      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize DataConsentService: $e');
    }
  }

  /// Show comprehensive consent dialog for new users
  Future<Map<ConsentType, ConsentStatus>> showConsentDialog(
    BuildContext context,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Check existing consents
    final existingAnalyticsConsent =
        prefs.getBool(_keyAnalyticsConsent) ?? false;
    final existingMarketingConsent =
        prefs.getBool(_keyMarketingConsent) ?? false;
    final existingPersonalizationConsent =
        prefs.getBool(_keyPersonalizationConsent) ?? false;
    final existingCommunicationConsent =
        prefs.getBool(_keyCommunicationConsent) ?? false;

    final consents = <ConsentType, ConsentStatus>{
      ConsentType.analytics: existingAnalyticsConsent
          ? ConsentStatus.granted
          : ConsentStatus.pending,
      ConsentType.marketing: existingMarketingConsent
          ? ConsentStatus.granted
          : ConsentStatus.pending,
      ConsentType.personalization: existingPersonalizationConsent
          ? ConsentStatus.granted
          : ConsentStatus.pending,
      ConsentType.communication: existingCommunicationConsent
          ? ConsentStatus.granted
          : ConsentStatus.pending,
    };

    final results = await showDialog<Map<ConsentType, ConsentStatus>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Data Collection Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aroosi is committed to protecting your privacy. We only collect information that is essential for providing our dating service.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              _buildConsentSection(
                'Analytics',
                'Anonymous usage data for app improvement and bug fixes',
                'Used to fix bugs and improve user experience',
                consents[ConsentType.analytics]!,
                (value) => consents[ConsentType.analytics] = value,
              ),
              _buildConsentSection(
                'Marketing & Communications',
                'Occasional promotional content and important app updates',
                'Used for app updates and important notifications',
                consents[ConsentType.marketing]!,
                (value) => consents[ConsentType.marketing] = value,
              ),
              _buildConsentSection(
                'Personalization',
                'Profile details, photos, and preferences',
                'Used to provide personalized matching and profiles',
                consents[ConsentType.personalization]!,
                (value) => consents[ConsentType.personalization] = value,
              ),
              _buildConsentSection(
                'In-App Messages',
                'Messages and notifications from other users',
                'Used for communication between verified users',
                consents[ConsentType.communication]!,
                (value) => consents[ConsentType.communication] = value,
              ),
              const SizedBox(height: 24),
              const Text(
                'You can change these preferences anytime in Settings → Privacy Settings.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(null);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Show confirmation
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your privacy preferences have been saved'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
              Navigator.of(context).pop(consents);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept & Continue'),
          ),
        ],
      ),
    );

    return results ?? {};
  }

  Widget _buildConsentSection(
    String title,
    String description,
    String impact,
    ConsentStatus currentStatus,
    ValueChanged<ConsentStatus> onChanged,
  ) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          impact,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Simple toggle buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          final newStatus =
                              currentStatus == ConsentStatus.pending
                              ? ConsentStatus.granted
                              : currentStatus == ConsentStatus.granted
                              ? ConsentStatus.denied
                              : ConsentStatus.pending;
                          setState(() {
                            onChanged(newStatus);
                          });
                        },
                        child: Text(
                          currentStatus == ConsentStatus.granted
                              ? 'Granted'
                              : currentStatus == ConsentStatus.denied
                              ? 'Denied'
                              : 'Pending',
                          style: TextStyle(
                            color: currentStatus == ConsentStatus.granted
                                ? Colors.green
                                : currentStatus == ConsentStatus.denied
                                ? Colors.red
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Check if user needs to see consent dialog
  bool needsConsentDialog() {
    return true; // Always show for new users
  }

  /// Update consent status
  Future<void> updateConsentStatus(ConsentStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyConsentStatus, status.name);
      print('Updated consent status to: ${status.name}');
    } catch (e) {
      print('Failed to update consent status: $e');
    }
  }

  /// Update specific consent type
  Future<void> updateConsentType(
    ConsentType consentType,
    ConsentStatus status,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (consentType) {
        case ConsentType.analytics:
          await prefs.setBool(
            _keyAnalyticsConsent,
            status == ConsentStatus.granted,
          );
          break;
        case ConsentType.marketing:
          await prefs.setBool(
            _keyMarketingConsent,
            status == ConsentStatus.granted,
          );
          break;
        case ConsentType.personalization:
          await prefs.setBool(
            _keyPersonalizationConsent,
            status == ConsentStatus.granted,
          );
          break;
        case ConsentType.communication:
          await prefs.setBool(
            _keyCommunicationConsent,
            status == ConsentStatus.granted,
          );
          break;
        case ConsentType.location:
          await prefs.setBool(
            _keyPlayerLocationConsent,
            status == ConsentStatus.granted,
          );
          break;
      }
      print('Updated ${consentType.name} consent to: ${status.name}');
    } catch (e) {
      print('Failed to update consent type ${consentType.name}: $e');
    }
  }

  Future<ConsentStatus> _getConsentStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusString = prefs.getString(_keyConsentStatus);
      switch (statusString) {
        case 'denied':
          return ConsentStatus.denied;
        case 'granted':
          return ConsentStatus.granted;
        case 'pending':
          return ConsentStatus.pending;
        default:
          return ConsentStatus.unknown;
      }
    } catch (e) {
      print('Error getting consent status: $e');
      return ConsentStatus.unknown;
    }
  }

  /// Get user-friendly consent status text
  Future<String> getConsentStatusText() async {
    final status = await _getConsentStatus();
    switch (status) {
      case ConsentStatus.granted:
        return 'All data collection enabled';
      case ConsentStatus.denied:
        return 'Some tracking disabled';
      case ConsentStatus.pending:
        return 'Your choice is important';
      default:
        return 'Review and select preferences';
    }
  }
}
