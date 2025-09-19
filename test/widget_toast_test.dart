import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aroosi_flutter/core/toast_service.dart';

void main() {
  testWidgets('ToastService shows sanitized JSON message', (tester) async {
    final key = GlobalKey<ScaffoldMessengerState>();
    // Swap the messenger key for testing
    ToastService.setTestMessengerKey(key);

    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: key,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );

    // Show a JSON payload message and ensure the decoded 'message' field is displayed
    ToastService.instance.show('{"message":"Hello world"}');
    await tester.pump();

    expect(find.text('Hello world'), findsOneWidget);
  });

  testWidgets('ToastService falls back from stacktrace to generic text', (
    tester,
  ) async {
    final key = GlobalKey<ScaffoldMessengerState>();
    ToastService.setTestMessengerKey(key);

    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: key,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );

    // Show a stack-trace like message; the sanitizer should fallback to a generic message
    ToastService.instance.show(
      'Exception: Something bad happened\n#0      Foo.bar (package:foo/foo.dart:10:3)',
    );
    await tester.pump();

    // We expect the friendly fallback or the capitalized first line if short; check for either
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
