import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

String _env(String key) => (dotenv.env[key] ?? '').trim();
String _envFallback(List<String> keys) {
  for (final k in keys) {
    final v = _env(k);
    if (v.isNotEmpty) return v;
  }
  return '';
}

/// Builds a GoogleSignIn instance configured from environment variables so
/// Flutter mirrors aroosi-mobile's auth behavior.
///
/// Expected .env keys:
/// - GOOGLE_WEB_CLIENT_ID: Web client ID (used as serverClientId for offline access)
/// - GOOGLE_IOS_CLIENT_ID: iOS client ID (used as clientId on iOS)
/// - GOOGLE_ANDROID_CLIENT_ID: Android client ID (not strictly required by plugin, but kept for parity)
GoogleSignIn buildGoogleSignIn() {
  final webClientId = _envFallback([
    'GOOGLE_WEB_CLIENT_ID',
    'EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID',
    'EXPO_PUBLIC_GOOGLE_CLIENT_ID',
  ]);
  final iosClientId = _envFallback([
    'GOOGLE_IOS_CLIENT_ID',
    'EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID',
  ]);
  // androidClientId kept for parity (not directly used by google_sign_in)
  // final androidClientId = _env('GOOGLE_ANDROID_CLIENT_ID');

  // On iOS, pass the iOS clientId; on Android it is optional.
  final bool isiOS = Platform.isIOS || Platform.isMacOS;

  return GoogleSignIn(
    scopes: const ['email', 'profile'],
    clientId: isiOS && iosClientId.isNotEmpty ? iosClientId : null,
    serverClientId: webClientId.isNotEmpty ? webClientId : null,
  );
}
