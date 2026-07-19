import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('app boots into the log flow with bottom navigation', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('How intense is the pain?'), findsOneWidget);
    // Icon-only bottom nav: Log is selected (filled), the rest are outlined.
    expect(find.byIcon(Icons.add_circle), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    expect(find.byIcon(Icons.insights_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

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

    final context = tester.element(find.byIcon(Icons.add_circle));
    final theme = Theme.of(context);
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, isNot(Colors.white));
    expect(theme.colorScheme.surface, isNot(Colors.white));

    await finishTest(tester);
  });
}
