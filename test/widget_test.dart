import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_eater/app.dart';
import 'package:global_eater/state/app_state.dart';
import 'fixtures.dart';

Future<AppState> mount(WidgetTester tester) async {
  final state = AppState(catalog: fixtureCatalog(), store: MemoryUserStore());
  await state.load();
  await tester.pumpWidget(GlobalEaterApp(state: state));
  await tester.pumpAndSettle();
  addTearDown(state.dispose);
  return state;
}

void main() {
  testWidgets('browse, search, save, and reopen a food', (tester) async {
    final state = await mount(tester);
    expect(find.text('Global Eater'), findsOneWidget);
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('food-search')), 'pho');
    await tester.pumpAndSettle();
    expect(find.text('Phở'), findsOneWidget);
    await tester.tap(find.byTooltip('Save Phở'));
    await tester.pumpAndSettle();
    expect(state.isSaved('pho'), isTrue);
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Phở'), findsOneWidget);
    await tester.tap(find.text('Phở'));
    await tester.pumpAndSettle();
    expect(find.text('Copy definition'), findsOneWidget);
    expect(state.recent.single.id, 'pho');
    expect(tester.takeException(), isNull);
  });
  testWidgets('alphabet filters only offer existing letters and reset on search', (tester) async {
    await mount(tester);
    await tester.tap(find.text('Search')); await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'Z'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'M')); await tester.pumpAndSettle();
    expect(find.text('Ma Poh dow fu'), findsOneWidget);
    expect(find.text('Phở'), findsNothing);
    await tester.enterText(find.byKey(const Key('food-search')), 'pho');
    await tester.pumpAndSettle();
    expect(find.text('Phở'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('empty saved state and no results are usable', (tester) async {
    await mount(tester);
    await tester.tap(find.text('Saved')); await tester.pumpAndSettle();
    expect(find.text('Your next great meal starts here.'), findsOneWidget);
    await tester.tap(find.text('Search')); await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('food-search')), 'zzzzzzzz');
    await tester.pumpAndSettle();
    expect(find.text('No matching foods'), findsOneWidget);
    await tester.tap(find.text('Clear search filters')); await tester.pumpAndSettle();
    expect(find.text('No matching foods'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('narrow display with large text does not overflow on explore', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.7;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await mount(tester);
    expect(tester.takeException(), isNull);
  });
}
