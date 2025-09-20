import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration shared across the Flutter app. Mirrors the values
/// used in aroosi-mobile so both clients authenticate against the same
/// Firebase project.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web. '
        'Copy the web Firebase config if Flutter web support is needed.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        // No dedicated macOS Firebase app yet.
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS. '
          'Add a macOS Firebase app and update this file.',
        );
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDCJme2CQ949nHabcdj50-sjLM1vXDjoR0',
    appId: '1:762041256503:android:5105c4c27e9e1939ac8db2',
    messagingSenderId: '762041256503',
    projectId: 'aroosi-project',
    storageBucket: 'aroosi-project.firebasestorage.app',
    measurementId: 'G-LW4V9JBD39',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCw-PTFXPUJPH9p-gOqm2zHjW-3vA2-WBY',
    appId: '1:762041256503:ios:a089f0b6e6501531ac8db2',
    messagingSenderId: '762041256503',
    projectId: 'aroosi-project',
    storageBucket: 'aroosi-project.firebasestorage.app',
    iosBundleId: 'com.aroosi.mobile',
    iosClientId:
        '762041256503-uc9qopr13761ictkgj53ba4gomtkvbha.apps.googleusercontent.com',
    androidClientId:
        '762041256503-f949ndu5cidrerbt4ng6ddv4cg7rskd8.apps.googleusercontent.com',
    measurementId: 'G-LW4V9JBD39',
  );
}
