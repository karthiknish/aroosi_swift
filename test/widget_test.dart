// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:aroosi_flutter/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App renders startup, login, or dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
  // Allow navigation and async bootstrapping without risking timeout
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(App), findsOneWidget);
    // Depending on auth state, we see Startup, Login, or Dashboard
    final isLogin = find.text('Login').evaluate().isNotEmpty;
    final isDashboard = find.text('Dashboard').evaluate().isNotEmpty;
    final isStartup = find.text('Welcome to Aroosi').evaluate().isNotEmpty;
    expect(isLogin || isDashboard || isStartup, true);
  });
}
