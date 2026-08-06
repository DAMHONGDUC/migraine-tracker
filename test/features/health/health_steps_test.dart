import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/health/domain/entities/step_day.dart';
import 'package:migraine_tracker/features/health/presentation/controllers/health_controller.dart';

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
    location: HeadLocation.left,
  );
}

void main() {
  group('Insights card', () {
    testWidgets('is absent where HealthKit is not available', (tester) async {
      await pumpApp(tester, premium: true);
      await openInsights(tester);

      expect(find.text('Steps & attacks'), findsNothing);

      await finishTest(tester);
    });

    testWidgets('a free user never reaches a step HealthKit read', (
      tester,
    ) async {
      final PumpedApp app = await pumpApp(
        tester,
        healthAvailable: true,
        initialPrefs: const <String, Object>{
          HealthController.connectedKey: true,
        },
      );
      await openInsights(tester);

      // The gate shows its pitch; nothing behind it was built or fetched.
      expect(find.text('Steps & attacks'), findsNothing);
      expect(app.health.stepReads, 0);

      await finishTest(tester);
    });

    testWidgets('prompts a premium user to connect Apple Health', (
      tester,
    ) async {
      await pumpApp(tester, premium: true, healthAvailable: true);
      await openInsights(tester);
      // The step card sits below the sleep card, off the initial viewport.
      await tester.dragUntilVisible(
        find.text('Steps & attacks'),
        find.byType(Scrollable).first,
        const Offset(0, -300),
      );

      expect(find.text('Steps & attacks'), findsOneWidget);
      expect(
        find.textContaining('Connect Apple Health steps in Settings'),
        findsOneWidget,
      );

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
          HealthController.connectedKey: true,
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

      await openInsights(tester);
      // The step card sits below the sleep card, off the initial viewport.
      await tester.dragUntilVisible(
        find.text('Steps & attacks'),
        find.byType(Scrollable).first,
        const Offset(0, -300),
      );

      expect(find.text('6000 steps'), findsOneWidget);
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
