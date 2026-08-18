import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('app boots into the dashboard with bottom navigation', (
    tester,
  ) async {
    await pumpApp(tester);

    // The dashboard's hero log button is front and centre.
    expect(find.text('Log an attack'), findsOneWidget);
    // Icon-only bottom nav: Home is selected (filled), the rest are outlined.
    //
    // `findsWidgets` for the outlined four, not `findsOneWidget`: the
    // dashboard's quick-access tiles draw some of the same glyphs, so an
    // exact count here fails on a screen that is perfectly correct. The
    // filled home icon is the bar's alone, and the tab-switch test below is
    // what proves the bar is wired rather than merely drawn.
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsWidgets);
    expect(find.byIcon(Icons.medication_outlined), findsWidgets);
    expect(find.byIcon(Icons.insights_outlined), findsWidgets);
    expect(find.byIcon(Icons.settings_outlined), findsWidgets);

    await finishTest(tester);
  });

  testWidgets('bottom navigation switches between tabs', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('No attacks logged yet.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Language'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('theme is dark with no pure white surfaces', (tester) async {
    await pumpApp(tester);

    final context = tester.element(find.byIcon(Icons.home));
    final theme = Theme.of(context);
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, isNot(Colors.white));
    expect(theme.colorScheme.surface, isNot(Colors.white));

    await finishTest(tester);
  });
}
