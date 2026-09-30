import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/daily_log/presentation/widgets/daily_check_in_card.dart';
import 'package:migraine_tracker/features/dashboard/presentation/widgets/dashboard_severity_card.dart';
import 'package:migraine_tracker/features/dashboard/presentation/widgets/dashboard_summary_group.dart';
import 'package:migraine_tracker/features/dashboard/presentation/widgets/premium_banner.dart';
import 'package:migraine_tracker/features/history/presentation/widgets/weekly_frequency_chart.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_reminder_repository.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication_reminder.dart';
import 'package:migraine_tracker/features/premium/presentation/screens/paywall_screen/paywall_screen.dart';
import 'package:migraine_tracker/features/settings/presentation/screens/export_screen/export_screen.dart';

import '../../helpers/pump_app.dart';

Future<void> _seedOneAttack(PumpedApp app) async {
  await DriftAttackRepository(app.db).insert(
    Attack(
      id: 'seed',
      startedAt: DateTime.now().toUtc(),
      intensity: 5,
      regions: const <HeadRegion>[HeadRegion.templeL],
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// The explore grid sits below the fold, and its last row is under the floating nav pill — [tapVisible] is what clears both.
Future<void> _tapExploreCard(WidgetTester tester, String title) async {
  await tapVisible(tester, find.text(title));
  await _settle(tester);
}

void main() {
  testWidgets('History shortcut opens History in list view', (tester) async {
    final app = await pumpApp(tester);
    await _seedOneAttack(app);
    await _settle(tester);

    await tester.tap(find.text('History'));
    await _settle(tester);

    // On the History screen (its title), showing the list — not the chart.
    expect(find.text('History'), findsWidgets);
    expect(find.byType(WeeklyFrequencyChart), findsNothing);

    await finishTest(tester);
  });

  testWidgets('severity card shows with data and opens the chart view', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await _seedOneAttack(app);
    await _settle(tester);

    // The severity mix card appears once there are attacks.
    expect(find.text('Severity mix'), findsOneWidget);

    // Chart is wrapped in IgnorePointer so the whole card is one tap target; warnIfMissed lets the hit fall through to the SdPressableScaleV2 behind it.
    final card = find.byType(DashboardSeverityCard);
    await tester.ensureVisible(card);
    await _settle(tester);
    await tester.tap(card, warnIfMissed: false);
    await _settle(tester);

    // Landed on the History chart deck.
    expect(find.byType(WeeklyFrequencyChart), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('next-reminder banner shows the soonest scheduled reminder', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftMedicationRepository(
      app.db,
    ).upsert(const Medication(id: 'm1', name: 'Ibuprofen'));
    await DriftMedicationReminderRepository(app.db).upsert(
      const MedicationReminder(
        id: 'r1',
        medicationId: 'm1',
        minuteOfDay: 9 * 60,
      ),
    );
    await _settle(tester);

    // Two lines, name over time — there is no "Next reminder" title any more.
    expect(find.byType(DailyCheckInCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DailyCheckInCard),
        matching: find.text('Ibuprofen'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(DailyCheckInCard),
        matching: find.textContaining('at 09:00'),
      ),
      findsOneWidget,
    );

    await finishTest(tester);
  });

  testWidgets('tapping the next-reminder banner opens its detail screen', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftMedicationRepository(
      app.db,
    ).upsert(const Medication(id: 'm1', name: 'Ibuprofen'));
    await DriftMedicationReminderRepository(app.db).upsert(
      const MedicationReminder(
        id: 'r1',
        medicationId: 'm1',
        minuteOfDay: 9 * 60,
      ),
    );
    await _settle(tester);

    await tapVisible(tester, find.text('Ibuprofen'));
    await _settle(tester);

    // Landed on that medication's own screen, with the reminder on it — not the Medications tab it used to scroll and flash.
    expect(find.text('Ibuprofen'), findsWidgets);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('reminder card opens Medications', (tester) async {
    await pumpApp(tester);

    await _tapExploreCard(tester, 'Reminders');

    expect(find.text('Medications'), findsWidgets);

    await finishTest(tester);
  });

  testWidgets('insights card opens Insights', (tester) async {
    await pumpApp(tester);

    await _tapExploreCard(tester, 'Insights');

    expect(find.text('Insights'), findsWidgets);

    await finishTest(tester);
  });

  testWidgets('export card opens the Export screen itself', (tester) async {
    // Premium: export is gated in full, and the free branch is the case below.
    await pumpApp(tester, premium: true);

    await _tapExploreCard(tester, 'Export');

    // - not the Settings tab with an "Export data" row.
    expect(find.byType(ExportScreen), findsOneWidget);
    expect(find.text('No exports yet'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('the export card is badged and pitches to a free user', (
    tester,
  ) async {
    await pumpApp(tester);

    await _tapExploreCard(tester, 'Export');

    // The paywall, not the screen — and the cell said so before the tap.
    expect(find.byType(ExportScreen), findsNothing);
    expect(find.text('BaroEase Premium'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('the premium banner follows the readings for a free user', (
    tester,
  ) async {
    await pumpApp(tester);
    await _settle(tester);

    // Below the fold now: the top of the screen is logging and the pressure outlook (2026-09-30 redesign).
    await tester.scrollUntilVisible(
      find.byType(PremiumBanner),
      200,
      // The dashboard's own list; the cards inside it carry scrollables of their own.
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.byType(PremiumBanner), findsOneWidget);
    // After the summary group, which is what "follows the readings" means — the order of the sections list is the whole feature.
    expect(
      tester.getRect(find.byType(PremiumBanner)).top,
      greaterThan(tester.getRect(find.byType(DashboardSummaryGroup)).top),
    );
    // One line and one line only: an offer is never the tallest thing in the list.
    expect(
      find.descendant(
        of: find.byType(PremiumBanner),
        matching: find.byType(Text),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byType(PremiumBanner)).height,
      lessThan(tester.getSize(find.byType(DashboardSummaryGroup)).height),
    );

    await finishTest(tester);
  });

  testWidgets('the premium banner opens the paywall', (tester) async {
    await pumpApp(tester);
    await _settle(tester);

    await tapVisible(tester, find.byType(PremiumBanner));
    await _settle(tester);

    expect(find.byType(PaywallScreen), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('a subscriber is not sold what they already bought', (
    tester,
  ) async {
    await pumpApp(tester, premium: true);
    await _settle(tester);

    expect(find.byType(PremiumBanner), findsNothing);

    await finishTest(tester);
  });
}
