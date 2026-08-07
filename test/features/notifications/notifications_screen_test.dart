import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:migraine_tracker/features/notifications/data/repositories/drift_notification_repository.dart';
import 'package:migraine_tracker/features/notifications/domain/entities/app_notification.dart';
import 'package:migraine_tracker/features/notifications/domain/enums/notification_type.dart';
import 'package:system_design/index.dart';

import '../../helpers/pump_app.dart';

Future<void> seedNotifications(PumpedApp app) async {
  await DriftMedicationRepository(
    app.db,
  ).upsert(const Medication(id: 'm1', name: 'Sumatriptan'));
  await DriftNotificationRepository(app.db).addMissing(<AppNotification>[
    AppNotification(
      id: 'rem:r1:100',
      type: NotificationType.medicationReminder,
      occurredAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
      medicationId: 'm1',
      reminderId: 'r1',
    ),
    AppNotification(
      id: 'pa:evt-1',
      type: NotificationType.pressureAlert,
      occurredAt: DateTime.now().toUtc().subtract(const Duration(hours: 5)),
      pressureDropHpa: -7.5,
    ),
  ]);
}

void main() {
  testWidgets('the bell wears a dot only while something is unread', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);

    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(
      tester.widget<SdBadgeDotV2>(find.byType(SdBadgeDotV2)).showing,
      isFalse,
      reason: 'nothing has arrived yet',
    );

    await seedNotifications(app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      tester.widget<SdBadgeDotV2>(find.byType(SdBadgeDotV2).first).showing,
      isTrue,
    );

    await finishTest(tester);
  });

  testWidgets('opening the list clears the dot', (tester) async {
    final PumpedApp app = await pumpApp(tester);
    await seedNotifications(app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await openNotifications(tester);
    expect(find.text('Notifications'), findsWidgets);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      tester.widget<SdBadgeDotV2>(find.byType(SdBadgeDotV2).first).showing,
      isFalse,
      reason: 'opening the list marks everything read',
    );

    await finishTest(tester);
  });

  testWidgets('rows read newest first, and name the medication', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    await seedNotifications(app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await openNotifications(tester);

    // Two hours ago beats five hours ago.
    final double reminderY = tester
        .getTopLeft(find.text('Time for Sumatriptan'))
        .dy;
    final double alertY = tester
        .getTopLeft(find.text('Pressure drop ahead'))
        .dy;

    expect(reminderY, lessThan(alertY));

    await finishTest(tester);
  });

  testWidgets('a reminder opens a detail that leads to its medication', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    await seedNotifications(app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await openNotifications(tester);
    await tapVisible(tester, find.text('Time for Sumatriptan'));
    await tester.pump(const Duration(milliseconds: 400));

    // The detail screen, not the medication itself: one tap, one stop.
    expect(find.text('Open this medication'), findsOneWidget);
    expect(find.text('Reminders'), findsNothing);

    await tapVisible(tester, find.text('Open this medication'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Reminders'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('a pressure alert opens a detail with the reading', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    await seedNotifications(app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await openNotifications(tester);
    await tapVisible(tester, find.text('Pressure drop ahead'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('7.5 hPa'), findsOneWidget);
    // The alert branch offers the forecast, never a medication.
    expect(find.text('See the forecast'), findsOneWidget);
    expect(find.text('Open this medication'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('a reminder whose medication is gone cannot open it', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    await seedNotifications(app);
    await app.db.delete(app.db.medications).go();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await openNotifications(tester);
    await tapVisible(tester, find.text('Time for your medication'));
    await tester.pump(const Duration(milliseconds: 400));

    // The button stays, disabled — one that vanished would read as a bug.
    final SdButtonV2 button = tester.widget<SdButtonV2>(
      find.widgetWithText(SdButtonV2, 'Open this medication'),
    );
    expect(button.onPressed, isNull);

    await finishTest(tester);
  });

  testWidgets('an empty list says so', (tester) async {
    await pumpApp(tester);

    await openNotifications(tester);

    expect(
      find.text('Nothing yet. Reminders and pressure alerts show up here.'),
      findsOneWidget,
    );

    await finishTest(tester);
  });
}
