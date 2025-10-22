import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_localizations/flutter_localizations.dart';


import 'package:aroosi_flutter/theme/theme.dart';
import 'package:aroosi_flutter/core/api_client.dart';
import 'package:aroosi_flutter/core/privacy_manager.dart';
import 'package:aroosi_flutter/core/push_notification_service.dart';
import 'package:aroosi_flutter/l10n/app_localizations.dart';

import 'router.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize privacy manager
    await PrivacyManager().initialize();
    
    // Initialize push notification service
    await PushNotificationService().initialize();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    // Attach Firebase bearer-token interceptor to match Next.js auth system
    // Enable for all platforms including web
    enableBearerTokenAuth(
      FirebaseAuthTokenProvider(fb.FirebaseAuth.instance),
    );

    return CupertinoApp.router(
      title: 'Aroosi - Free Afghan Dating',
      theme: buildCupertinoTheme(),
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('fa', 'AF'), // Farsi (Dari)
        Locale('ps', 'AF'), // Pashto
      ],
    );
  }
}
