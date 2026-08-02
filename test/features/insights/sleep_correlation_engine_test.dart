import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/health/domain/entities/sleep_night.dart';
import 'package:migraine_tracker/features/insights/domain/entities/sleep_correlation_result.dart';
import 'package:migraine_tracker/features/insights/domain/services/sleep_correlation_engine.dart';

/// Local wall-clock on purpose: `Attack` stores UTC, and the engine converts
/// back before taking a date. Building attacks from local time is what a user
/// in any timezone actually produces, so these assertions hold on any machine.
Attack attackOn(DateTime localStart) => Attack(
  id: 'attack-${localStart.toIso8601String()}',
  startedAt: localStart,
  intensity: 6,
  location: HeadLocation.left,
);

SleepNight night(DateTime date, {required double hours}) => SleepNight(
  date: date,
  duration: Duration(minutes: (hours * 60).round()),
);

/// [hours] one entry per night, starting at 2026-01-02 and running forward.
/// A night whose date is in [attackMornings] is followed by an attack.
({List<SleepNight> nights, List<Attack> attacks}) history({
  required List<double> attackNightHours,
  required List<double> restNightHours,
}) {
  final List<SleepNight> nights = <SleepNight>[];
  final List<Attack> attacks = <Attack>[];
  int day = 2;

  for (final double hours in attackNightHours) {
    final DateTime date = DateTime(2026, 1, day++);
    nights.add(night(date, hours: hours));
    // 10:00 on the morning the night ended.
    attacks.add(attackOn(DateTime(date.year, date.month, date.day, 10)));
  }
  for (final double hours in restNightHours) {
    nights.add(night(DateTime(2026, 1, day++), hours: hours));
  }

  return (nights: nights, attacks: attacks);
}

void main() {
  const SleepCorrelationEngine engine = SleepCorrelationEngine();

  group('insufficient data', () {
    test('no nights at all', () {
      final SleepCorrelationResult result = engine.analyze(
        attacks: const <Attack>[],
        nights: const <SleepNight>[],
      );

      expect(result, isA<SleepInsufficientData>());
      result as SleepInsufficientData;
      expect(result.nightsWithSleep, 0);
      expect(result.requiredNights, 15);
    });

    test('14 nights is one short of the minimum', () {
      final ({List<Attack> attacks, List<SleepNight> nights}) data = history(
        attackNightHours: List<double>.filled(5, 5),
        restNightHours: List<double>.filled(9, 8),
      );
      final SleepCorrelationResult result = engine.analyze(
        attacks: data.attacks,
        nights: data.nights,
      );

      expect(result, isA<SleepInsufficientData>());
      expect((result as SleepInsufficientData).nightsWithSleep, 14);
    });

    test('enough nights but too few before an attack', () {
      // 2 attack nights against the 3-per-group floor.
      final ({List<Attack> attacks, List<SleepNight> nights}) data = history(
        attackNightHours: List<double>.filled(2, 5),
        restNightHours: List<double>.filled(18, 8),
      );
      final SleepCorrelationResult result = engine.analyze(
        attacks: data.attacks,
        nights: data.nights,
      );

      expect(result, isA<SleepInsufficientData>());
      result as SleepInsufficientData;
      expect(result.attackNights, 2);
      expect(result.restNights, 18);
      expect(result.requiredPerGroup, 3);
    });

    test('enough nights but every one of them follows an attack', () {
      final ({List<Attack> attacks, List<SleepNight> nights}) data = history(
        attackNightHours: List<double>.filled(20, 5),
        restNightHours: const <double>[],
      );
      final SleepCorrelationResult result = engine.analyze(
        attacks: data.attacks,
        nights: data.nights,
      );

      expect(result, isA<SleepInsufficientData>());
      expect((result as SleepInsufficientData).restNights, 0);
    });
  });

  group('no variation', () {
    test('identical averages carry no signal', () {
      final ({List<Attack> attacks, List<SleepNight> nights}) data = history(
        attackNightHours: List<double>.filled(8, 7),
        restNightHours: List<double>.filled(12, 7),
      );
      final SleepCorrelationResult result = engine.analyze(
        attacks: data.attacks,
        nights: data.nights,
      );

      expect(result, isA<SleepNoVariation>());
      expect((result as SleepNoVariation).nightsAnalyzed, 20);
    });

    test('a gap under 15 minutes still counts as the same sleep', () {
      final ({List<Attack> attacks, List<SleepNight> nights}) data = history(
        // 7h00 vs 7h10.
        attackNightHours: List<double>.filled(8, 7),
        restNightHours: List<double>.filled(12, 7 + 10 / 60),
      );
      final SleepCorrelationResult result = engine.analyze(
        attacks: data.attacks,
        nights: data.nights,
      );

      expect(result, isA<SleepNoVariation>());
    });
  });

  group('insight', () {
    test('computes both averages and the shortfall', () {
      final ({List<Attack> attacks, List<SleepNight> nights}) data = history(
        attackNightHours: List<double>.filled(5, 5),
        restNightHours: List<double>.filled(10, 8),
      );
      final SleepCorrelationResult result = engine.analyze(
        attacks: data.attacks,
        nights: data.nights,
      );

      expect(result, isA<SleepInsight>());
      result as SleepInsight;
      expect(result.attackNightAverage, const Duration(hours: 5));
      expect(result.restNightAverage, const Duration(hours: 8));
      expect(result.shortfall, const Duration(hours: 3));
      expect(result.sleptLessBeforeAttacks, isTrue);
      expect(result.attackNights, 5);
      expect(result.restNights, 10);
      expect(result.nightsAnalyzed, 15);
    });

    test('sleeping MORE before attacks is reported, not flipped', () {
      final ({List<Attack> attacks, List<SleepNight> nights}) data = history(
        attackNightHours: List<double>.filled(5, 9),
        restNightHours: List<double>.filled(10, 7),
      );
      final SleepCorrelationResult result = engine.analyze(
        attacks: data.attacks,
        nights: data.nights,
      );

      result as SleepInsight;
      expect(result.sleptLessBeforeAttacks, isFalse);
      expect(result.shortfall, const Duration(hours: -2));
    });

    test('several attacks on one day count that night once', () {
      final ({List<Attack> attacks, List<SleepNight> nights}) data = history(
        attackNightHours: List<double>.filled(5, 5),
        restNightHours: List<double>.filled(10, 8),
      );
      // A second attack the same afternoon.
      final DateTime firstMorning = data.nights.first.date;
      final SleepCorrelationResult result = engine.analyze(
        attacks: <Attack>[
          ...data.attacks,
          attackOn(
            DateTime(
              firstMorning.year,
              firstMorning.month,
              firstMorning.day,
              16,
            ),
          ),
        ],
        nights: data.nights,
      );

      result as SleepInsight;
      expect(result.attackNights, 5);
      expect(result.restNights, 10);
    });

    test('an attack on a day with no sleep record changes nothing', () {
      final ({List<Attack> attacks, List<SleepNight> nights}) data = history(
        attackNightHours: List<double>.filled(5, 5),
        restNightHours: List<double>.filled(10, 8),
      );
      final SleepCorrelationResult result = engine.analyze(
        attacks: <Attack>[...data.attacks, attackOn(DateTime(2025, 6, 1, 9))],
        nights: data.nights,
      );

      result as SleepInsight;
      expect(result.nightsAnalyzed, 15);
    });
  });

  group('night-to-attack join', () {
    test('an attack the day AFTER the morning is not that night', () {
      // One night (the 2nd), attack on the 3rd → the night is a rest night.
      final List<SleepNight> nights = <SleepNight>[
        for (int i = 0; i < 20; i++)
          night(DateTime(2026, 1, 2 + i), hours: 7 + (i % 2)),
      ];
      final SleepCorrelationResult result = engine.analyze(
        attacks: <Attack>[
          for (int i = 0; i < 5; i++) attackOn(DateTime(2026, 2, 1 + i, 9)),
        ],
        nights: nights,
      );

      // Every night is a rest night, so there is nothing to compare.
      expect(result, isA<SleepInsufficientData>());
      expect((result as SleepInsufficientData).attackNights, 0);
    });

    test('an attack just after midnight belongs to that morning', () {
      final ({List<Attack> attacks, List<SleepNight> nights}) data = history(
        attackNightHours: List<double>.filled(5, 5),
        restNightHours: List<double>.filled(10, 8),
      );
      final DateTime morning = data.nights.first.date;
      // Rebuild the attacks at 00:30 instead of 10:00 — same calendar day.
      final SleepCorrelationResult result = engine.analyze(
        attacks: <Attack>[
          for (int i = 0; i < 5; i++)
            attackOn(
              DateTime(morning.year, morning.month, morning.day + i, 0, 30),
            ),
        ],
        nights: data.nights,
      );

      result as SleepInsight;
      expect(result.attackNights, 5);
    });
  });

  group('tuning', () {
    test('a stricter minimum pushes a valid sample back to insufficient', () {
      const SleepCorrelationEngine strict = SleepCorrelationEngine(
        minNights: 30,
      );
      final ({List<Attack> attacks, List<SleepNight> nights}) data = history(
        attackNightHours: List<double>.filled(5, 5),
        restNightHours: List<double>.filled(10, 8),
      );

      expect(
        strict.analyze(attacks: data.attacks, nights: data.nights),
        isA<SleepInsufficientData>(),
      );
    });

    test('a wider epsilon swallows a small difference', () {
      const SleepCorrelationEngine tolerant = SleepCorrelationEngine(
        variationEpsilon: Duration(hours: 4),
      );
      final ({List<Attack> attacks, List<SleepNight> nights}) data = history(
        attackNightHours: List<double>.filled(5, 5),
        restNightHours: List<double>.filled(10, 8),
      );

      expect(
        tolerant.analyze(attacks: data.attacks, nights: data.nights),
        isA<SleepNoVariation>(),
      );
    });
  });
}
