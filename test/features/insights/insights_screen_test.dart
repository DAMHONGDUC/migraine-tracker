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

void main() {
  testWidgets('a locked pressure card is one pitch, not three', (tester) async {
    await pumpApp(tester);
    await openPressureInsight(tester);

    // The whole card is the purchase now, so the forecast, the correlation and
    // the alert share ONE offer — each carrying its own line made a single
    // offer read as three.
    expect(
      find.text(
        'See the pressure forecast, how closely your attacks track it, and '
        'get alerted before the next drop.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Log 15 more attacks with weather data to unlock this insight.',
      ),
      findsNothing,
    );

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

      await openPressureInsight(tester);

      expect(find.text('60%'), findsOneWidget);
      expect(
        find.text('Based on 15 attacks with weather data'),
        findsOneWidget,
      );

      await finishTest(tester);
    },
  );

  testWidgets('a premium user with one attack sees counts, not a percentage', (
    tester,
  ) async {
    final app = await pumpApp(tester, premium: true);
    final repository = DriftAttackRepository(app.db);
    await repository.insert(seededAttack(0, pressureDelta: -7));

    await openPressureInsight(tester);

    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('100%'), findsNothing);
    expect(find.text('Based on 1 attack with weather data'), findsOneWidget);
    expect(
      find.text('Still settling — the figure will move as you log more.'),
      findsOneWidget,
    );

    await finishTest(tester);
  });

  testWidgets('a premium user below the minimum sees a flagged percentage', (
    tester,
  ) async {
    final app = await pumpApp(tester, premium: true);
    final repository = DriftAttackRepository(app.db);
    // 6 during rapid drops, 4 during stable weather → 60% off 10 attacks.
    for (var i = 0; i < 6; i++) {
      await repository.insert(seededAttack(i, pressureDelta: -7));
    }
    for (var i = 6; i < 10; i++) {
      await repository.insert(seededAttack(i, pressureDelta: 2));
    }

    await openPressureInsight(tester);

    expect(find.text('60%'), findsOneWidget);
    expect(find.text('Based on 10 attacks with weather data'), findsOneWidget);
    expect(
      find.text('Still settling — the figure will move as you log more.'),
      findsOneWidget,
    );

    await finishTest(tester);
  });

  testWidgets('a free user with attacks still gets no figure in the tree', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    final repository = DriftAttackRepository(app.db);
    for (var i = 0; i < 10; i++) {
      await repository.insert(seededAttack(i, pressureDelta: -7));
    }

    await openPressureInsight(tester);

    // The point of the lock is that the number is never computed into a free
    // user's widget tree — not that it is computed and then hidden.
    expect(find.text('60%'), findsNothing);
    expect(find.text('100%'), findsNothing);
    expect(find.text('10/10'), findsNothing);
    expect(find.text('10 of 15 attacks with weather'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('the pressure tab is one card: forecast, correlation, alerts', (
    tester,
  ) async {
    final app = await pumpApp(tester, premium: true);
    final repository = DriftAttackRepository(app.db);
    await repository.insert(seededAttack(0, pressureDelta: -7));

    await openInsights(tester);

    // Insights opens on Weather, and the tabs build lazily — so only the
    // segment naming this card is on screen, none of the card itself.
    expect(find.text('Pressure'), findsOneWidget);
    expect(find.text('Pressure-drop alerts'), findsNothing);

    await tapVisible(tester, find.text('Pressure'));
    await pumpCountUp(tester);

    // ONE card, not a forecast card beside a correlation card: the bodies are
    // cardless and folded in, so the standalone `Pressure correlation` title
    // never appears here.
    expect(find.text('Pressure correlation'), findsNothing);
    expect(find.text('Pressure-drop alerts'), findsOneWidget);
    // A bare Switch inside `_AlertRow`, never a SwitchListTile — that one
    // brings Material's 48pt tap target and makes the two rows different
    // heights, which is what made the pair look unfinished.
    expect(find.byType(Switch), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('a free user gets no alert controls, not disabled ones', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    final repository = DriftAttackRepository(app.db);
    await repository.insert(seededAttack(0, pressureDelta: -7));

    await openPressureInsight(tester);

    // Owner's call, and it reversed the first version: a switch that will not
    // switch and a threshold row that will not open read as a broken screen
    // rather than as an offer, so neither control is built at all.
    expect(find.text('Pressure-drop alerts'), findsNothing);
    expect(find.byType(Switch), findsNothing);

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
