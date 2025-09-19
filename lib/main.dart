import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'core/env.dart';
import 'utils/globalkey_error_handler.dart';
// Theme is configured inside App via buildAppTheme()

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await dotenv.load(fileName: '.env');
  // Initialize Firebase using the same options as aroosi-mobile.
  final platform = defaultTargetPlatform;
  final isMobile =
      !kIsWeb &&
      (platform == TargetPlatform.iOS || platform == TargetPlatform.android);
  if (isMobile) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Optional: log storage bucket source (env override vs firebase_options)
    assert(() {
      final bucket = Env.storageBucket;
      // ignore: avoid_print
      print('Using storage bucket: ${bucket.isEmpty ? '(none)' : bucket}');
      return true;
    }());
  }
  
  // Initialize GlobalKey error handler
  GlobalKeyErrorHandler().init();
  
  runApp(const ProviderScope(child: App()));
}
