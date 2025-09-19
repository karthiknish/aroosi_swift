import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/theme/theme.dart';
import 'package:aroosi_flutter/core/api_client.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

import 'router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the messenger key from provider for scaffold messenger
    final messengerKey = ref.read(toastMessengerKeyProvider);

    // Attach Firebase bearer-token interceptor (mirrors RN Axios setup)
    // Only enable on mobile where Firebase is initialized by main().
    final platform = defaultTargetPlatform;
    final isMobile =
        !kIsWeb &&
        (platform == TargetPlatform.iOS || platform == TargetPlatform.android);
    if (isMobile) {
      enableBearerTokenAuth(
        FirebaseAuthTokenProvider(fb.FirebaseAuth.instance),
      );
    }
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Aroosi',
      theme: buildAppTheme(),
      routerConfig: router,
      scaffoldMessengerKey: messengerKey,
    );
  }
}
