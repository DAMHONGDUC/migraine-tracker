import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:migraine_tracker/features/notifications/data/repositories/drift_notification_repository.dart';
import 'package:migraine_tracker/features/notifications/domain/entities/app_notification.dart';
import 'package:migraine_tracker/features/notifications/domain/enums/notification_kind.dart';
import 'package:system_design/index.dart';

import '../../helpers/pump_app.dart';

Future<void> seedNotifications(PumpedApp app) async {
  await DriftMedicationRepository(
    app.db,
  ).upsert(const Medication(id: 'm1', name: 'Sumatriptan'));
  await DriftNotificationRepository(app.db).addMissing(<AppNotification>[
    AppNotification(
      id: 'rem:r1:100',
      kind: NotificationKind.medicationReminder,
      occurredAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
      medicationId: 'm1',
      reminderId: 'r1',
    ),
    AppNotification(
      id: 'pa:evt-1',
      kind: NotificationKind.pressureAlert,
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

  testWidgets('a medication reminder opens its medication', (tester) async {
    final PumpedApp app = await pumpApp(tester);
    await seedNotifications(app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await openNotifications(tester);
    await tapVisible(tester, find.text('Time for Sumatriptan'));
    await tester.pump(const Duration(milliseconds: 400));

    // The medication detail screen, not a sheet.
    expect(find.text('Reminders'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('a pressure alert opens a sheet, not a screen', (tester) async {
    final PumpedApp app = await pumpApp(tester);
    await seedNotifications(app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await openNotifications(tester);
    await tapVisible(tester, find.text('Pressure drop ahead'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('7.5 hPa'), findsOneWidget);
    expect(find.text('See the forecast'), findsOneWidget);
    // Still on the list underneath — a sheet, not a push.
    expect(find.byType(SdSheetContentV2), findsOneWidget);

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
