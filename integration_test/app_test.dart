import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter/material.dart';
import 'package:playspot_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final screenshot = Screenshot();

  testWidgets('App launches and renders home screen', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Take screenshot of home screen
    final image = await screenshot.capture(
      widget: tester.widget(find.byType(MaterialApp)),
      context: tester.element(find.byType(MaterialApp)),
      pixelRatio: 1.0,
      delay: Duration(milliseconds: 100),
    );

    expect(image, isNotNull);
  });

  testWidgets('Profile save flow', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Navigate to profile
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Take screenshot of profile screen
    final profileImage = await screenshot.capture(
      widget: tester.widget(find.byType(Scaffold)),
      context: tester.element(find.byType(Scaffold)),
      pixelRatio: 1.0,
      delay: Duration(milliseconds: 100),
    );

    expect(profileImage, isNotNull);
  });

  testWidgets('Social feed with stories', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Navigate to social feed
    await tester.tap(find.text('Social'));
    await tester.pumpAndSettle();

    // Take screenshot of social feed
    final feedImage = await screenshot.capture(
      widget: tester.widget(find.byType(Scaffold)),
      context: tester.element(find.byType(Scaffold)),
      pixelRatio: 1.0,
      delay: Duration(milliseconds: 100),
    );

    expect(feedImage, isNotNull);
  });
}
