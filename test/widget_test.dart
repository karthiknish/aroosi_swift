// A minimal widget test that avoids initializing Firebase platform channels.
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/theme/theme.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/features/auth/auth_state.dart';
import 'package:aroosi_flutter/router.dart';

class TestApp extends ConsumerWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return CupertinoApp.router(
      title: 'Aroosi',
      theme: buildCupertinoTheme(),
      routerConfig: router,
    );
  }
}

void main() {
  testWidgets('App renders startup, login, or dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
        ],
        child: const TestApp(),
      ),
    );
    // Allow navigation and async bootstrapping without risking timeout
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(TestApp), findsOneWidget);
    // Depending on auth state, we see Startup, Login, or Dashboard
    final isLogin = find.text('Login').evaluate().isNotEmpty;
    final isDashboard = find.text('Dashboard').evaluate().isNotEmpty;
    final isStartup = find.text('Welcome to Aroosi').evaluate().isNotEmpty;
    expect(isLogin || isDashboard || isStartup, true);
  });
}

class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(isAuthenticated: false, loading: false);
}
