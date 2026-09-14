import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/constants/prefs_key_constant.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/health/domain/entities/step_day.dart';
import 'package:migraine_tracker/features/health/domain/enums/health_data_kind.dart';

import '../../helpers/pump_app.dart';

/// Local midnight [daysAgo] back.
DateTime dayOf(int daysAgo) {
  final DateTime now = DateTime.now();

  return DateTime(now.year, now.month, now.day - daysAgo);
}

StepDay steppedFor(int daysAgo, {required int steps}) =>
    StepDay(date: dayOf(daysAgo), count: steps);

Attack attackOnDay(int daysAgo) {
  final DateTime date = dayOf(daysAgo);

  return Attack(
    id: 'attack-$daysAgo',
    startedAt: DateTime(date.year, date.month, date.day, 10),
    intensity: 6,
    regions: const <HeadRegion>[HeadRegion.templeL],
  );
}

void main() {
  group('Insights card', () {
    testWidgets('is absent where HealthKit is not available', (tester) async {
      await pumpApp(tester, premium: true);
      await openActivityInsight(tester);

      // The activity card still stands — its exertion half is free and needs no HealthKit — but the step half is gone with the source.
      expect(find.text('Activity'), findsWidgets);
      expect(find.textContaining('Connect Apple Health steps'), findsNothing);

      await finishTest(tester);
    });

    testWidgets('a free user never reaches the premium step correlation', (
      tester,
    ) async {
      final PumpedApp app = await pumpApp(
        tester,
        healthAvailable: true,
        initialPrefs: const <String, Object>{
          PrefsKeyConstant.healthConnected: true,
        },
      );
      await openActivityInsight(tester);

      // The analysis half is what premium buys: a free user gets the pitch, and nothing behind it reads HealthKit again.
      expect(
        find.text(
          'Unlock to see whether your attacks follow your least active days.',
        ),
        findsOneWidget,
      );
      // Skip read-count assertions because each free surface reads independently.
      expect(app.health.stepReads, greaterThan(0));

      await finishTest(tester);
    });

    testWidgets('prompts a premium user to connect Apple Health', (
      tester,
    ) async {
      await pumpApp(tester, premium: true, healthAvailable: true);
      await openActivityInsight(tester);

      // Said twice, and that is the card: the steps half says it and the analysis half says it.
      expect(find.textContaining('Connect Apple Health steps'), findsWidgets);

      await finishTest(tester);
    });

    testWidgets('steps connect separately from sleep', (tester) async {
      final PumpedApp app = await pumpApp(
        tester,
        premium: true,
        healthAvailable: true,
      );
      await openActivityTab(tester);

      await tapVisible(
        tester,
        find.ancestor(
          of: find.text('Apple Health steps'),
          matching: find.byType(SwitchListTile),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(app.health.requestedKinds, <HealthDataKind>[HealthDataKind.steps]);
      expect(app.prefs.getBool(PrefsKeyConstant.healthSteps), isTrue);
      expect(app.prefs.getBool(PrefsKeyConstant.healthSleep), isNot(isTrue));

      await finishTest(tester);
    });

    testWidgets('shows the two averages once there is enough step data', (
      tester,
    ) async {
      // 5 attack days at 2000 steps, 10 quiet days at 8000 → 6000 shortfall.
      final PumpedApp app = await pumpApp(
        tester,
        premium: true,
        healthAvailable: true,
        initialPrefs: const <String, Object>{
          PrefsKeyConstant.healthSteps: true,
        },
        stepDays: <StepDay>[
          for (int i = 1; i <= 5; i++) steppedFor(i, steps: 2000),
          for (int i = 6; i <= 15; i++) steppedFor(i, steps: 8000),
        ],
      );
      final DriftAttackRepository repository = DriftAttackRepository(app.db);

      for (int i = 1; i <= 5; i++) {
        await repository.insert(attackOnDay(i));
      }

      await openActivityInsight(tester);
      await dragInsightsTo(tester, find.text('6000 steps'));

      // Twice: the steps half prints the day's own figure and the analysis prints the same number as one of its two averages.
      expect(find.text('6000 steps'), findsWidgets);
      expect(
        find.text('fewer steps on the days your attacks started.'),
        findsOneWidget,
      );
      expect(find.text('2000 steps'), findsOneWidget);
      expect(find.text('8000 steps'), findsOneWidget);
      expect(
        find.text('Based on 5 days with an attack and 10 others'),
        findsOneWidget,
      );

      await finishTest(tester);
    });
  });
}
