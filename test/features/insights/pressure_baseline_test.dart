import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/insights/domain/entities/correlation_result.dart';
import 'package:migraine_tracker/features/insights/domain/services/correlation_engine.dart';
import 'package:migraine_tracker/features/weather/domain/entities/daily_pressure.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

/// The denominator: what the correlation could not say before, because
/// `WeatherSnapshots` is keyed by attackId and days without an attack carried
/// no weather at all.
void main() {
  const CorrelationEngine engine = CorrelationEngine();
  final DateTime start = DateTime(2026, 6, 1);

  /// The delta varies with the day so the engine does not read the history as
  /// "all the same weather" — a real history never is.
  Attack attackOn(int dayOffset, {double? delta}) => Attack(
    id: 'a$dayOffset',
    startedAt: start.add(Duration(days: dayOffset, hours: 9)),
    intensity: 6,
    location: HeadLocation.right,
    weather: WeatherSnapshot(
      capturedAt: start.add(Duration(days: dayOffset, hours: 9)),
      pressureHpa: 1005,
      pressureDelta24hHpa: delta ?? -7.0 - dayOffset,
    ),
  );

  DailyPressure day(int dayOffset, {required double delta}) => DailyPressure(
    day: start.add(Duration(days: dayOffset)),
    pressureHpa: 1010,
    pressureDelta24hHpa: delta,
  );

  /// [dropsWithAttack] drop days that ended in an attack, then the rest.
  ({List<Attack> attacks, List<DailyPressure> days}) history({
    required int dropDays,
    required int dropsWithAttack,
    required int calmDays,
    required int calmWithAttack,
  }) {
    final List<DailyPressure> days = <DailyPressure>[];
    final List<Attack> attacks = <Attack>[];
    int offset = 0;

    for (int i = 0; i < dropDays; i++, offset++) {
      days.add(day(offset, delta: -8));
      if (i < dropsWithAttack) attacks.add(attackOn(offset));
    }
    for (int i = 0; i < calmDays; i++, offset++) {
      days.add(day(offset, delta: 1));
      // A calm DAY can still hold an attack whose own snapshot fell — the two
      // readings are taken at different times.
      if (i < calmWithAttack) attacks.add(attackOn(offset, delta: 1.0 + i));
    }
    return (attacks: attacks, days: days);
  }

  test('no recorded days means no baseline, and the share still stands', () {
    final CorrelationResult result = engine.analyze(<Attack>[attackOn(0)]);

    expect(result, isA<CorrelationInsight>());
    expect((result as CorrelationInsight).baseline, isNull);
    // The old figure is untouched — an existing user whose history predates
    // the daily readings must not lose the card.
    expect(result.attacksDuringPressureDrop, 1);
  });

  test('compares the attack rate on drop days against the rest', () {
    final ({List<Attack> attacks, List<DailyPressure> days}) h = history(
      dropDays: 10,
      dropsWithAttack: 6,
      calmDays: 20,
      calmWithAttack: 2,
    );

    final PressureBaseline baseline =
        (engine.analyze(h.attacks, days: h.days) as CorrelationInsight)
            .baseline!;

    expect(baseline.dropDays, 10);
    expect(baseline.dropDaysWithAttack, 6);
    expect(baseline.calmDays, 20);
    expect(baseline.calmDaysWithAttack, 2);
    expect(baseline.dropDayAttackPercent, 60);
    expect(baseline.calmDayAttackPercent, 10);
    expect(baseline.timesMoreLikely, 6);
  });

  // The exact failure the denominator exists to fix: someone in a stormy
  // climate whose attacks have nothing to do with pressure. Their share of
  // attacks-during-drops is high, and the baseline says so.
  test('a stormy climate no longer looks like a finding', () {
    final ({List<Attack> attacks, List<DailyPressure> days}) h = history(
      dropDays: 25,
      dropsWithAttack: 5,
      calmDays: 5,
      calmWithAttack: 1,
    );
    final CorrelationInsight result =
        engine.analyze(h.attacks, days: h.days) as CorrelationInsight;

    // Most of their attacks fell on drop days...
    expect(result.dropSharePercent, greaterThan(80));
    // ...but a drop day is no more likely to end in one than a calm day.
    expect(result.baseline!.dropDayAttackPercent, 20);
    expect(result.baseline!.calmDayAttackPercent, 20);
    expect(result.baseline!.timesMoreLikely, 1);
  });

  group('when the sample is too thin to state', () {
    test('too few drop days means no baseline at all', () {
      final ({List<Attack> attacks, List<DailyPressure> days}) h = history(
        dropDays: 2,
        dropsWithAttack: 2,
        calmDays: 30,
        calmWithAttack: 3,
      );

      // 2 of 2 is 100%, which reads as a finding off two days' weather.
      expect(
        (engine.analyze(h.attacks, days: h.days) as CorrelationInsight)
            .baseline,
        isNull,
      );
    });

    test('too few calm days means no baseline either', () {
      final ({List<Attack> attacks, List<DailyPressure> days}) h = history(
        dropDays: 30,
        dropsWithAttack: 10,
        calmDays: 3,
        calmWithAttack: 0,
      );

      expect(
        (engine.analyze(h.attacks, days: h.days) as CorrelationInsight)
            .baseline,
        isNull,
      );
    });

    // Dividing by zero would print "infinitely more likely" off a handful of
    // quiet days.
    test('no calm day with an attack means no multiplier, but still rates', () {
      final ({List<Attack> attacks, List<DailyPressure> days}) h = history(
        dropDays: 10,
        dropsWithAttack: 5,
        calmDays: 10,
        calmWithAttack: 0,
      );
      final PressureBaseline baseline =
          (engine.analyze(h.attacks, days: h.days) as CorrelationInsight)
              .baseline!;

      expect(baseline.timesMoreLikely, isNull);
      expect(baseline.dropDayAttackPercent, 50);
      expect(baseline.calmDayAttackPercent, 0);
    });
  });

  // Three attacks in one day is still one day that ended in an attack;
  // counting them separately would let a single bad day carry the comparison.
  test('a day counts once however many attacks it held', () {
    final List<DailyPressure> days = <DailyPressure>[
      for (int i = 0; i < 10; i++) day(i, delta: -8),
      for (int i = 10; i < 20; i++) day(i, delta: 1),
    ];
    final List<Attack> attacks = <Attack>[
      for (final (int index, int hour) in <int>[9, 15, 21].indexed)
        Attack(
          id: 'x$index',
          startedAt: start.add(Duration(hours: hour)),
          intensity: 5,
          location: HeadLocation.left,
          weather: WeatherSnapshot(
            capturedAt: start.add(Duration(hours: hour)),
            pressureHpa: 1005,
            pressureDelta24hHpa: -6.0 - index,
          ),
        ),
    ];

    final PressureBaseline baseline =
        (engine.analyze(attacks, days: days) as CorrelationInsight).baseline!;

    expect(baseline.dropDaysWithAttack, 1);
  });

  test('a day with a reading but no attack is what fills the calm side', () {
    final ({List<Attack> attacks, List<DailyPressure> days}) h = history(
      dropDays: 5,
      dropsWithAttack: 0,
      calmDays: 5,
      calmWithAttack: 0,
    );
    final CorrelationResult result = engine.analyze(h.attacks, days: h.days);

    // No attacks at all: nothing to analyse, so no insight and no baseline.
    expect(result, isA<CorrelationInsufficientData>());
  });
}
