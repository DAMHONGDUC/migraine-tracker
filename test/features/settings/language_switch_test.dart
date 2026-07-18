import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('switching to Vietnamese relocalizes the UI and persists', (
    tester,
  ) async {
    final app = await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Language'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Tiếng Việt'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // UI is now Vietnamese.
    expect(find.text('Cài đặt'), findsWidgets);
    expect(find.text('Ngôn ngữ'), findsOneWidget);
    // Choice is persisted for the next launch.
    expect(app.prefs.getString('app_locale'), 'vi');

    // The log flow is Vietnamese too.
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Cơn đau dữ dội mức nào?'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('a persisted Vietnamese locale is restored on launch', (
    tester,
  ) async {
    await pumpApp(tester, initialPrefs: {'app_locale': 'vi'});

    expect(find.text('Cơn đau dữ dội mức nào?'), findsOneWidget);
    // The Log app bar title relocalized (the icon-only nav has no labels).
    expect(find.text('Ghi cơn đau'), findsOneWidget);

    await finishTest(tester);
  });
}
