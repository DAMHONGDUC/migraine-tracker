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

    // The picker is a bottom sheet now: it slides in on the root navigator,
    // so both the open and the dismiss need a full transition, not 100ms.
    await tapVisible(tester, find.text('Language'));
    await tapVisible(tester, find.text('Tiếng Việt'));

    // UI is now Vietnamese.
    expect(find.text('Cài đặt'), findsWidgets);
    expect(find.text('Ngôn ngữ'), findsOneWidget);
    // Choice is persisted for the next launch.
    expect(app.prefs.getString('app_locale'), 'vi');

    // The log flow is Vietnamese too — open it from the dashboard.
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Ghi cơn đau mới'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Cơn đau dữ dội mức nào?'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('a persisted Vietnamese locale is restored on launch', (
    tester,
  ) async {
    await pumpApp(tester, initialPrefs: {'app_locale': 'vi'});

    // Launch lands on the dashboard, relocalized to Vietnamese.
    expect(find.text('Xin chào'), findsOneWidget);
    expect(find.text('Ghi cơn đau mới'), findsOneWidget);

    await finishTest(tester);
  });
}
