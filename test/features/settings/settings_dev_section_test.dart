import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

/// The developer group: where it sits, and the one row in it that a widget test can drive end to end.
void main() {
  testWidgets('the developer group is the first thing on Settings', (
    tester,
  ) async {
    await pumpApp(tester);
    await openSettings(tester);

    // Owner's rule: above every real section, not below them all. Measured against General, which was the top of the screen before.
    expect(
      tester.getRect(find.text('Developer')).top,
      lessThan(tester.getRect(find.text('General')).top),
    );

    await finishTest(tester);
  });

  testWidgets('the dev row schedules a local test notification', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    await openSettings(tester);

    expect(app.scheduler.testScheduled, isFalse);

    // It moved here from the medications tab's app bar, where a developer tool sat in the chrome of a screen users see.
    await tapVisible(tester, find.text('Test local notification (device)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(app.scheduler.testScheduled, isTrue);
    expect(
      find.textContaining('Local test notification in 10s'),
      findsOneWidget,
    );

    await finishTest(tester);
  });

  testWidgets('the dev delete-all row empties the database and stays put', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);

    await logAttack(tester);
    expect(await app.db.select(app.db.attacks).get(), hasLength(1));

    await openSettings(tester);
    await tapVisible(tester, find.text('Delete all data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(await app.db.select(app.db.attacks).get(), isEmpty);
    // Unlike "Reset the app", onboarding is not replayed: the row is for looking at empty states, so the screen it was tapped from is still there.
    expect(find.text('Developer'), findsOneWidget);

    await finishTest(tester);
  });
}
