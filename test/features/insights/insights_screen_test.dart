import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/history/presentation/widgets/weekly_frequency_chart.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

import '../../helpers/pump_app.dart';

Attack seededAttack(int i, {double? pressureDelta}) {
  final startedAt = DateTime.now().toUtc().subtract(Duration(days: i % 40));
  return Attack(
    id: 'seed-$i',
    startedAt: startedAt,
    intensity: 5,
    location: HeadLocation.left,
    weather: pressureDelta == null
        ? null
        : WeatherSnapshot(
            capturedAt: startedAt,
            pressureHpa: 1010,
            pressureDelta24hHpa: pressureDelta,
          ),
  );
}

Future<void> openInsights(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.insights_outlined));
  // Real frames so the correlation count-up can run (see premium test note).
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('locked state shows remaining count and progress', (
    tester,
  ) async {
    await pumpApp(tester);
    await openInsights(tester);

    expect(
      find.text('Log 15 more attacks with weather data to unlock this insight.'),
      findsOneWidget,
    );
    expect(find.text('0 of 15 attacks with weather'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets(
    'with 15+ attacks a premium user sees the drop-share hero number',
    (tester) async {
    final app = await pumpApp(tester, premium: true);
    final repository = DriftAttackRepository(app.db);
    // 9 during rapid drops, 6 during stable weather → 60%.
    for (var i = 0; i < 9; i++) {
      await repository.insert(seededAttack(i, pressureDelta: -7));
    }
    for (var i = 9; i < 15; i++) {
      await repository.insert(seededAttack(i, pressureDelta: 2));
    }

    await openInsights(tester);

    expect(find.text('60%'), findsOneWidget);
    expect(find.text('Based on 15 attacks with weather data'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('history shows the weekly frequency chart once attacks exist', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    final repository = DriftAttackRepository(app.db);
    await repository.insert(seededAttack(0, pressureDelta: -7));

    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // History defaults to list mode; switch to chart via the app-bar toggle.
    await tester.tap(find.byIcon(Icons.bar_chart));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The chart deck now stacks several charts (some also BarCharts), so
    // target the weekly-frequency one specifically.
    expect(find.byType(WeeklyFrequencyChart), findsOneWidget);
    expect(find.text('Attacks per week'), findsOneWidget);

    await finishTest(tester);
  });
}
