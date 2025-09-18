import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
// Theme is configured inside App via buildAppTheme()

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  // Initialize Firebase (uses ios/Runner/GoogleService-Info.plist and android/app/google-services.json)
  // Note: On desktop (e.g., macOS) there is no default config file.
  // Initialize only on mobile where default files are present.
  final platform = defaultTargetPlatform;
  final isMobile =
      !kIsWeb &&
      (platform == TargetPlatform.iOS || platform == TargetPlatform.android);
  if (isMobile) {
    await Firebase.initializeApp();
  }
  runApp(const ProviderScope(child: App()));
}
