import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/history/presentation/widgets/weekly_frequency_chart.dart';

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

/// Some banners sit below the fold on the scrollable dashboard — scroll the
/// target into view before tapping it.
Future<void> _tapBanner(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await _settle(tester);
  await tester.tap(find.text(label));
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

  testWidgets('Chart shortcut opens History in chart view', (tester) async {
    final app = await pumpApp(tester);
    await _seedOneAttack(app);
    await _settle(tester);

    await tester.tap(find.text('Chart'));
    await _settle(tester);

    expect(find.byType(WeeklyFrequencyChart), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('Add medication shortcut opens the add dialog on Medications', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Add medication'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // The add-name dialog auto-opens after landing on the Medications tab.
    expect(find.text('Add a medication'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('reminder banner opens Medications', (tester) async {
    await pumpApp(tester);

    await _tapBanner(tester, 'Medication reminders');

    expect(find.text('Medications'), findsWidgets);

    await finishTest(tester);
  });

  testWidgets('insights banner opens Insights', (tester) async {
    await pumpApp(tester);

    await _tapBanner(tester, 'Pressure & pain insights');

    expect(find.text('Insights'), findsWidgets);

    await finishTest(tester);
  });

  testWidgets('export banner opens Settings export', (tester) async {
    await pumpApp(tester);

    await _tapBanner(tester, 'Export your data');

    expect(find.text('Export data'), findsOneWidget);

    await finishTest(tester);
  });
}
