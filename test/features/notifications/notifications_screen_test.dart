import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/theme/app_colors.dart';
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
  testWidgets('the bell wears the unread count', (tester) async {
    final PumpedApp app = await pumpApp(tester);

    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(
      tester.widget<SdBadgeV2>(find.byType(SdBadgeV2)).showing,
      isFalse,
      reason: 'nothing has arrived yet',
    );

    await seedNotifications(app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final SdBadgeV2 badge = tester.widget<SdBadgeV2>(
      find.byType(SdBadgeV2).first,
    );

    expect(badge.showing, isTrue);
    expect(badge.count, 2, reason: 'both seeded notifications are unread');
    // Red, not the lavender accent every non-urgent highlight wears.
    expect(badge.color, AppColors.error);

    await finishTest(tester);
  });

  testWidgets('opening the list clears the badge', (tester) async {
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
      tester.widget<SdBadgeV2>(find.byType(SdBadgeV2).first).showing,
      isFalse,
      reason: 'opening the list marks everything read',
    );

    await finishTest(tester);
  });

  testWidgets('the two types are split across tabs, each carrying its count', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    await seedNotifications(app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await openNotifications(tester);

    final SdSegmentedTabsV2 tabs = tester.widget<SdSegmentedTabsV2>(
      find.byType(SdSegmentedTabsV2),
    );

    expect(tabs.segments.map((SdSegmentV2 s) => s.label), <String>[
      'Reminders',
      'Pressure',
    ]);
    expect(tabs.segments.map((SdSegmentV2 s) => s.count), <int>[1, 1]);
    expect(tabs.selectedIndex, 0);

    // Reminders tab: the alert is not on it.
    expect(find.text('Time for Sumatriptan'), findsOneWidget);
    expect(find.text('Pressure drop ahead'), findsNothing);

    await tapVisible(tester, find.text('Pressure'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Pressure drop ahead'), findsOneWidget);
    expect(find.text('Time for Sumatriptan'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('each tab says so when it is the empty one', (tester) async {
    final PumpedApp app = await pumpApp(tester);
    await seedNotifications(app);
    await app.db.delete(app.db.appNotifications).go();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await openNotifications(tester);
    expect(
      find.text('No reminders yet. They show up here once you set one.'),
      findsOneWidget,
    );

    await tapVisible(tester, find.text('Pressure'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No pressure alerts yet.'), findsOneWidget);

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
    await tapVisible(tester, find.text('Pressure'));
    await tester.pump(const Duration(milliseconds: 300));
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
}
