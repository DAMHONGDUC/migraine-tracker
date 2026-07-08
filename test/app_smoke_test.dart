import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('app boots into the log flow with bottom navigation', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('How intense is the pain?'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('bottom navigation switches between tabs', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('History'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('No attacks logged yet.'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Language'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('theme is dark with no pure white surfaces', (tester) async {
    await pumpApp(tester);

    final context = tester.element(find.byType(NavigationBar));
    final theme = Theme.of(context);
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, isNot(Colors.white));
    expect(theme.colorScheme.surface, isNot(Colors.white));

    await finishTest(tester);
  });
}
