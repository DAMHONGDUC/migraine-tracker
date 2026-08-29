import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/theme/app_icon_constant.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('app boots into the dashboard with bottom navigation', (
    tester,
  ) async {
    await pumpApp(tester);

    // The dashboard's hero log button is front and centre.
    expect(find.text('Log an attack'), findsOneWidget);
    // Icon-only bottom nav: Home is selected (filled), the rest outlined.
    expect(find.byIcon(AppIconConstant.home), findsOneWidget);
    expect(find.byIcon(AppIconConstant.history), findsWidgets);
    expect(find.byIcon(AppIconConstant.medication), findsWidgets);
    expect(find.byIcon(AppIconConstant.insights), findsWidgets);
    expect(find.byIcon(AppIconConstant.settings), findsWidgets);

    await finishTest(tester);
  });

  testWidgets('bottom navigation switches between tabs', (tester) async {
    await pumpApp(tester);

    // `.last` is the nav bar: the dashboard's quick-access tile draws the same glyph, since the tile and the tab it opens share one constant.
    await tester.tap(find.byIcon(AppIconConstant.history).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('No attacks logged yet.'), findsOneWidget);

    await tester.tap(find.byIcon(AppIconConstant.settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Language'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('theme is dark with no pure white surfaces', (tester) async {
    await pumpApp(tester);

    final context = tester.element(find.byIcon(AppIconConstant.home));
    final theme = Theme.of(context);
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, isNot(Colors.white));
    expect(theme.colorScheme.surface, isNot(Colors.white));

    await finishTest(tester);
  });
}
