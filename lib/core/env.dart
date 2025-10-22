import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:aroosi_flutter/firebase_options.dart';

/// Mirrors the environment switching used in aroosi-mobile so both apps hit
/// the same backend tiers by default.
class Env {
  Env._();

  static const String _defaultDevBase = 'http://localhost:3000/api';
  static const String _defaultStagingBase = 'https://staging.aroosi.app/api';
  static const String _defaultProdBase = 'https://www.aroosi.app/api';

  static String get environment {
    final value = _read('ENVIRONMENT');
    switch (value.toLowerCase()) {
      case 'development':
      case 'dev':
        return 'development';
      case 'staging':
        return 'staging';
      case 'production':
      case 'prod':
      default:
        return 'production';
    }
  }

  static String get apiBaseUrl {
    final override = _read('API_BASE_URL');
    if (override.isNotEmpty) {
      return _normalizeBase(override);
    }
    switch (environment) {
      case 'development':
        return _defaultDevBase;
      case 'staging':
        return _defaultStagingBase;
      case 'production':
      default:
        return _defaultProdBase;
    }
  }

  /// Mobile billing toggle. When false (default), subscriptions stay on the
  /// free tier and purchase flows are disabled.
  static bool get subscriptionsEnabled {
    final value = _read('SUBSCRIPTIONS_ENABLED');
    if (value.isEmpty) return false;
    switch (value.toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'on':
        return true;
      default:
        return false;
    }
  }

  static String _read(String key) {
    try {
      final value = dotenv.env[key];
      return value?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  static String _normalizeBase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  /// Firebase Storage bucket, overridable via env (FIREBASE_STORAGE_BUCKET).
  /// Falls back to the bucket in DefaultFirebaseOptions.
  static String get storageBucket {
    final override = _read('FIREBASE_STORAGE_BUCKET').trim();
    if (override.isNotEmpty) return override;
    try {
      return DefaultFirebaseOptions.currentPlatform.storageBucket ?? '';
    } catch (_) {
      return '';
    }
  }
}
