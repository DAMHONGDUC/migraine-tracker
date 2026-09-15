import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/health/domain/entities/step_day.dart';
import 'package:migraine_tracker/features/insights/domain/entities/step_correlation_result.dart';
import 'package:migraine_tracker/features/insights/domain/services/step_correlation_engine.dart';

/// Local wall-clock on purpose: `Attack` stores UTC, and the engine converts back before taking a date.
Attack attackOn(DateTime localStart) => Attack(
  id: 'attack-${localStart.toIso8601String()}',
  startedAt: localStart,
  intensity: 6,
  regions: const <HeadRegion>[HeadRegion.templeL],
);

StepDay day(DateTime date, {required int steps}) =>
    StepDay(date: date, count: steps);

/// [attackDaySteps]/[restDaySteps] one entry per day, starting at 2026-01-02 and running forward.
({List<StepDay> days, List<Attack> attacks}) history({
  required List<int> attackDaySteps,
  required List<int> restDaySteps,
}) {
  final List<StepDay> days = <StepDay>[];
  final List<Attack> attacks = <Attack>[];
  int d = 2;

  for (final int steps in attackDaySteps) {
    final DateTime date = DateTime(2026, 1, d++);
    days.add(day(date, steps: steps));
    attacks.add(attackOn(DateTime(date.year, date.month, date.day, 10)));
  }
  for (final int steps in restDaySteps) {
    days.add(day(DateTime(2026, 1, d++), steps: steps));
  }

  return (days: days, attacks: attacks);
}

void main() {
  const StepCorrelationEngine engine = StepCorrelationEngine();

  group('insufficient data', () {
    test('no days at all', () {
      final StepCorrelationResult result = engine.analyze(
        attacks: const <Attack>[],
        days: const <StepDay>[],
      );

      expect(result, isA<StepInsufficientData>());
      result as StepInsufficientData;
      expect(result.daysWithSteps, 0);
      expect(result.requiredDays, 15);
    });

    test('14 days is one short of the minimum', () {
      final ({List<Attack> attacks, List<StepDay> days}) data = history(
        attackDaySteps: List<int>.filled(5, 2000),
        restDaySteps: const <int>[],
      );
      final StepCorrelationResult result = engine.analyze(
        attacks: data.attacks,
        days: data.days,
      );

      expect(result, isA<StepInsufficientData>());
      expect((result as StepInsufficientData).restDays, 0);
    });
  });

  group('below the minimum the comparison still runs', () {
    test('one day each side already yields both averages', () {
      final ({List<Attack> attacks, List<StepDay> days}) data = history(
        attackDaySteps: const <int>[2000],
        restDaySteps: const <int>[8000],
      );
      final StepCorrelationResult result = engine.analyze(
        attacks: data.attacks,
        days: data.days,
      );

      expect(result, isA<StepInsight>());
      result as StepInsight;
      expect(result.attackDayAverage, 2000);
      expect(result.restDayAverage, 8000);
      // One side under the per-group floor: the gap is not a headline yet.
      expect(result.isCountOnly, isTrue);
      expect(result.isPreliminary, isTrue);
    });

    test('identical averages are not judged while a side is thin', () {
      final ({List<Attack> attacks, List<StepDay> days}) data = history(
        attackDaySteps: const <int>[7000],
        restDaySteps: const <int>[7000],
      );

      expect(
        engine.analyze(attacks: data.attacks, days: data.days),
        isA<StepInsight>(),
      );
    });

    test('both groups past the floor but too few days is preliminary', () {
      final ({List<Attack> attacks, List<StepDay> days}) data = history(
        attackDaySteps: List<int>.filled(4, 2000),
        restDaySteps: List<int>.filled(6, 8000),
      );
      final StepCorrelationResult result = engine.analyze(
        attacks: data.attacks,
        days: data.days,
      );

      result as StepInsight;
      expect(result.daysAnalyzed, 10);
      expect(result.isCountOnly, isFalse);
      expect(result.isPreliminary, isTrue);
    });
  });

  group('no variation', () {
    test('identical averages carry no signal', () {
      final ({List<Attack> attacks, List<StepDay> days}) data = history(
        attackDaySteps: List<int>.filled(8, 7000),
        restDaySteps: List<int>.filled(12, 7000),
      );
      final StepCorrelationResult result = engine.analyze(
        attacks: data.attacks,
        days: data.days,
      );

      expect(result, isA<StepNoVariation>());
      expect((result as StepNoVariation).daysAnalyzed, 20);
    });

    test('a gap under 1000 steps still counts as the same activity', () {
      final ({List<Attack> attacks, List<StepDay> days}) data = history(
        attackDaySteps: List<int>.filled(8, 7000),
        restDaySteps: List<int>.filled(12, 7500),
      );
      final StepCorrelationResult result = engine.analyze(
        attacks: data.attacks,
        days: data.days,
      );

      expect(result, isA<StepNoVariation>());
    });
  });

  group('insight', () {
    test('computes both averages and the shortfall', () {
      final ({List<Attack> attacks, List<StepDay> days}) data = history(
        attackDaySteps: List<int>.filled(5, 2000),
        restDaySteps: List<int>.filled(10, 8000),
      );
      final StepCorrelationResult result = engine.analyze(
        attacks: data.attacks,
        days: data.days,
      );

      expect(result, isA<StepInsight>());
      result as StepInsight;
      expect(result.attackDayAverage, 2000);
      expect(result.restDayAverage, 8000);
      expect(result.shortfall, 6000);
      expect(result.movedLessOnAttackDays, isTrue);
      expect(result.attackDays, 5);
      expect(result.restDays, 10);
      expect(result.daysAnalyzed, 15);
    });

    test('moving MORE on attack days is reported, not flipped', () {
      final ({List<Attack> attacks, List<StepDay> days}) data = history(
        attackDaySteps: List<int>.filled(5, 9000),
        restDaySteps: List<int>.filled(10, 7000),
      );
      final StepCorrelationResult result = engine.analyze(
        attacks: data.attacks,
        days: data.days,
      );

      result as StepInsight;
      expect(result.movedLessOnAttackDays, isFalse);
      expect(result.shortfall, -2000);
    });
  });

  group('day-to-attack join', () {
    test('a day with an attack the day before is a rest day', () {
      // Steps on the 2nd, attack on the 3rd → same-day join means the 2nd is a rest day (unlike sleep, which would count the night of the 2nd).
      final List<StepDay> days = <StepDay>[
        for (int i = 0; i < 20; i++)
          day(DateTime(2026, 1, 2 + i), steps: 7000 + (i % 2) * 1000),
      ];
      final StepCorrelationResult result = engine.analyze(
        attacks: <Attack>[
          for (int i = 0; i < 5; i++) attackOn(DateTime(2026, 2, 1 + i, 9)),
        ],
        days: days,
      );

      expect(result, isA<StepInsufficientData>());
      expect((result as StepInsufficientData).attackDays, 0);
    });

    test('several attacks on one day count that day once', () {
      final ({List<Attack> attacks, List<StepDay> days}) data = history(
        attackDaySteps: List<int>.filled(5, 2000),
        restDaySteps: List<int>.filled(10, 8000),
      );
      final DateTime firstDay = data.days.first.date;
      final StepCorrelationResult result = engine.analyze(
        attacks: <Attack>[
          ...data.attacks,
          attackOn(DateTime(firstDay.year, firstDay.month, firstDay.day, 16)),
        ],
        days: data.days,
      );

      result as StepInsight;
      expect(result.attackDays, 5);
      expect(result.restDays, 10);
    });
  });

  group('tuning', () {
    test('a stricter minimum keeps a valid sample preliminary', () {
      const StepCorrelationEngine strict = StepCorrelationEngine(minDays: 30);
      final ({List<Attack> attacks, List<StepDay> days}) data = history(
        attackDaySteps: List<int>.filled(5, 2000),
        restDaySteps: List<int>.filled(10, 8000),
      );
      final StepCorrelationResult result = strict.analyze(
        attacks: data.attacks,
        days: data.days,
      );

      expect(result, isA<StepInsight>());
      expect((result as StepInsight).isPreliminary, isTrue);
    });

    test('a wider epsilon swallows a small difference', () {
      const StepCorrelationEngine tolerant = StepCorrelationEngine(
        variationEpsilonSteps: 10000,
      );
      final ({List<Attack> attacks, List<StepDay> days}) data = history(
        attackDaySteps: List<int>.filled(5, 2000),
        restDaySteps: List<int>.filled(10, 8000),
      );

      expect(
        tolerant.analyze(attacks: data.attacks, days: data.days),
        isA<StepNoVariation>(),
      );
    });
  });
}
