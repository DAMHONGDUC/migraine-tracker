import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/core/theme/app_colors.dart';
import 'package:migraine_tracker/core/theme/app_icon_constant.dart';
import 'package:migraine_tracker/core/widgets/settings_tile.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:migraine_tracker/features/notifications/data/repositories/drift_notification_repository.dart';
import 'package:migraine_tracker/features/notifications/domain/entities/app_notification.dart';
import 'package:migraine_tracker/features/notifications/domain/enums/notification_type.dart';
import 'package:migraine_tracker/features/notifications/presentation/screens/notifications_screen/notifications_screen.dart';
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

/// Pops the topmost route. Not `pageBack()`: with the list and a detail both pushed there are two back buttons in the tree, and it insists on exactly one.
Future<void> popTop(WidgetTester tester) async {
  await tester.tap(find.byIcon(SdAppBarButtonV2.backIcon).last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The unread dots on the list's own rows — not the dashboard's bell, which is an `SdBadgeV2` too and sits under the pushed route.
Iterable<SdBadgeV2> rowDots(WidgetTester tester) => tester
    .widgetList<SdBadgeV2>(
      find.descendant(
        of: find.byType(NotificationsScreen),
        matching: find.byType(SdBadgeV2),
      ),
    )
    .where((SdBadgeV2 badge) => badge.showing);

void main() {
  testWidgets('the bell wears the unread count', (tester) async {
    final PumpedApp app = await pumpApp(tester);

    expect(find.byIcon(AppIconConstant.notifications), findsOneWidget);
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

  testWidgets('opening the list reads nothing — the badge stays', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    await seedNotifications(app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await openNotifications(tester);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Looking at a list is not reading its items.
    expect(tester.widget<SdBadgeV2>(find.byType(SdBadgeV2).first).count, 2);

    await finishTest(tester);
  });

  testWidgets('opening one detail reads that one, and only that one', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    await seedNotifications(app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await openNotifications(tester);
    // Both rows are unread, so both wear a dot.
    expect(rowDots(tester), hasLength(1), reason: 'one row, one dot');

    await tapVisible(tester, find.text('Time for Sumatriptan'));
    await tester.pump(const Duration(milliseconds: 400));
    await popTop(tester);

    // That row's dot is gone; the alert on the other tab is untouched.
    expect(rowDots(tester), isEmpty);

    // One at a time, not all at once.
    final List<AppNotificationRow> rows = await app.db
        .select(app.db.appNotifications)
        .get();

    expect(
      rows.where((AppNotificationRow r) => r.readAt == null),
      hasLength(1),
    );
    expect(
      rows.firstWhere((AppNotificationRow r) => r.readAt != null).type,
      NotificationType.medicationReminder,
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

    // Centred in the track, not sitting against its top edge.
    final Rect track = tester.getRect(find.byType(SdSegmentedTabsV2));
    final Rect label = tester.getRect(find.text('Reminders'));

    expect(label.center.dy, moreOrLessEquals(track.center.dy, epsilon: 1));

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

  testWidgets('Settings has a row into the list, showing the unread count', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    await seedNotifications(app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await openSettings(tester);

    // The count sits at the end of the row, next to the chevron.
    final SettingsTile tile = tester.widget<SettingsTile>(
      find.widgetWithText(SettingsTile, 'Notifications'),
    );

    expect(tile.value, '2');

    await tapVisible(tester, find.text('Notifications'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SdSegmentedTabsV2), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('the Settings row states no count when nothing is unread', (
    tester,
  ) async {
    await pumpApp(tester);

    await openSettings(tester);

    // Not "0" — an empty row saying zero is noise.
    final SettingsTile tile = tester.widget<SettingsTile>(
      find.widgetWithText(SettingsTile, 'Notifications'),
    );

    expect(tile.value, isNull);

    await finishTest(tester);
  });
}
