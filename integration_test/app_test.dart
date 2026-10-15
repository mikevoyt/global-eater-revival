import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:global_eater/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real-device bundled catalog loads and searches without a server', (tester) async {
    app.main();
    // Wait for platform-backed preferences and the bundled catalog to load.
    for (var i = 0; i < 120 && find.text('Search').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search')); await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('food-search')), 'pho');
    await tester.pumpAndSettle();
    expect(find.text('Phở'), findsOneWidget);
    await tester.tap(find.text('Phở')); await tester.pumpAndSettle();
    expect(find.text('Copy definition'), findsOneWidget);
  });
}
