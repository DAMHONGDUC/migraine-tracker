import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/dashboard/presentation/widgets/dashboard_severity_card.dart';
import 'package:migraine_tracker/features/dashboard/presentation/widgets/next_reminder_banner.dart';
import 'package:migraine_tracker/features/history/presentation/widgets/weekly_frequency_chart.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_reminder_repository.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication_reminder.dart';
import 'package:migraine_tracker/features/settings/presentation/screens/export_screen/export_screen.dart';

import '../../helpers/pump_app.dart';

Future<void> _seedOneAttack(PumpedApp app) async {
  await DriftAttackRepository(app.db).insert(
    Attack(
      id: 'seed',
      startedAt: DateTime.now().toUtc(),
      intensity: 5,
      location: HeadLocation.left,
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// The explore grid sits below the fold, and its last row is under the
/// floating nav pill — [tapVisible] is what clears both.
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

    // Chart is wrapped in IgnorePointer so the whole card is one tap target;
    // warnIfMissed lets the hit fall through to the SdPressableScaleV2 behind it.
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
    expect(find.byType(NextReminderBanner), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NextReminderBanner),
        matching: find.text('Ibuprofen'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(NextReminderBanner),
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

    await tapVisible(tester, find.byType(NextReminderBanner));
    await _settle(tester);

    // Landed on that medication's own screen, with the reminder on it —
    // not the Medications tab it used to scroll and flash.
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
    await pumpApp(tester);

    await _tapExploreCard(tester, 'Export');

    // - not the Settings tab with an "Export data" row — the card must land on the screen it advertised
    // - both surfaces carry that title, so match the screen itself, not the text
    expect(find.byType(ExportScreen), findsOneWidget);
    expect(find.text('No exports yet'), findsOneWidget);

    await finishTest(tester);
  });
}
