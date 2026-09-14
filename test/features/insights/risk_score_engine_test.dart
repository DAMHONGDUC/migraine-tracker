import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/health/domain/entities/cycle_day.dart';
import 'package:migraine_tracker/features/health/domain/entities/sleep_night.dart';
import 'package:migraine_tracker/features/insights/domain/entities/risk_score.dart';
import 'package:migraine_tracker/features/insights/domain/services/risk_score_engine.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_report.dart';

void main() {
  const RiskScoreEngine engine = RiskScoreEngine();
  final DateTime now = DateTime(2026, 9, 4, 8);

  /// A flat day, then a fall of [drop] hPa across it.
  WeatherReport weatherFalling({required double drop, int days = 7}) =>
      WeatherReport(
        hours: <WeatherHourly>[
          for (int day = 0; day < days; day++)
            for (int hour = 0; hour < 24; hour += 6)
              WeatherHourly(
                time: DateTime(2026, 9, 4 + day, hour).toUtc(),
                pressureHpa: 1013 - (drop * hour / 18),
              ),
        ],
        days: const <WeatherDaily>[],
      );

  Attack attackAt(DateTime at) => Attack(
    id: at.toIso8601String(),
    startedAt: at.toUtc(),
    intensity: 6,
    regions: const <HeadRegion>[HeadRegion.templeR],
  );

  RiskContribution contributionOf(DailyRisk day, RiskSignal signal) =>
      day.contributions.firstWhere((RiskContribution c) => c.signal == signal);

  RiskForecast run({
    WeatherReport? weather,
    double thresholdHpa = 5,
    List<CycleDay> cycleDays = const <CycleDay>[],
    List<SleepNight> nights = const <SleepNight>[],
    List<Attack>? attacks,
  }) => engine.forecast(
    now: now,
    weather: weather,
    thresholdHpa: thresholdHpa,
    cycleDays: cycleDays,
    nights: nights,
    // Three weeks of history by default, so the frequency baseline is not what fails a test about something else.
    attacks:
        attacks ??
        <Attack>[
          attackAt(now.subtract(const Duration(days: 20))),
          attackAt(now.subtract(const Duration(days: 13))),
        ],
  );

  test('it covers seven days, today first', () {
    final RiskForecast forecast = run(weather: weatherFalling(drop: 4));

    expect(forecast.days, hasLength(7));
    expect(forecast.days.first.day, DateTime(2026, 9, 4));
    expect(forecast.days.last.day, DateTime(2026, 9, 10));
  });

  group('the pressure signal', () {
    test('a drop at twice the threshold scores the whole weight', () {
      final RiskContribution pressure = contributionOf(
        run(weather: weatherFalling(drop: 10)).days.first,
        RiskSignal.pressureDrop,
      );

      expect(pressure.isAvailable, isTrue);
      expect(pressure.points, RiskScoreEngine.pressureWeight.toDouble());
      expect(pressure.dropHpa, closeTo(10, 0.01));
    });

    // The user's own setting is what the score is measured against, never a number the app picked.
    test('the same drop scores less against a higher threshold', () {
      final double lenient = contributionOf(
        run(weather: weatherFalling(drop: 5), thresholdHpa: 10).days.first,
        RiskSignal.pressureDrop,
      ).points;
      final double strict = contributionOf(
        run(weather: weatherFalling(drop: 5), thresholdHpa: 3).days.first,
        RiskSignal.pressureDrop,
      ).points;

      expect(strict, greaterThan(lenient));
    });

    // No forecast is not a calm day, and the two must never score the same.
    test('no forecast leaves the signal unavailable, not zero', () {
      final DailyRisk today = run().days.first;

      expect(
        contributionOf(today, RiskSignal.pressureDrop).isAvailable,
        isFalse,
      );
      expect(today.missing, contains(RiskSignal.pressureDrop));
      expect(
        today.availablePoints,
        lessThan(
          RiskScoreEngine.pressureWeight +
              RiskScoreEngine.cycleWeight +
              RiskScoreEngine.sleepWeight +
              RiskScoreEngine.frequencyWeight,
        ),
      );
    });
  });

  group('the cycle signal', () {
    List<CycleDay> startingOn(DateTime day) => <CycleDay>[
      CycleDay(day: day, hasFlow: true, isPeriodStart: true),
    ];

    test('a day inside the window takes the whole weight', () {
      final RiskContribution cycle = contributionOf(
        run(cycleDays: startingOn(DateTime(2026, 9, 5))).days.first,
        RiskSignal.cycleWindow,
      );

      expect(cycle.points, RiskScoreEngine.cycleWeight.toDouble());
      expect(cycle.dayInCycle, -1);
    });

    // Knowing the cycle and being outside the window is a real zero, unlike having no cycle data at all.
    test('a day outside the window scores zero but stays available', () {
      final RiskContribution cycle = contributionOf(
        run(cycleDays: startingOn(DateTime(2026, 8, 1))).days.first,
        RiskSignal.cycleWindow,
      );

      expect(cycle.isAvailable, isTrue);
      expect(cycle.points, 0);
    });

    test('no cycle data leaves the signal unavailable', () {
      expect(
        contributionOf(run().days.first, RiskSignal.cycleWindow).isAvailable,
        isFalse,
      );
    });
  });

  group('the sleep signal', () {
    List<SleepNight> nightsEndingWith(int lastHours) => <SleepNight>[
      for (int i = 10; i > 0; i--)
        SleepNight(
          date: DateTime(2026, 8, 20 + (10 - i)),
          duration: const Duration(hours: 7, minutes: 10),
        ),
      SleepNight(
        date: DateTime(2026, 9, 4),
        duration: Duration(hours: lastHours),
      ),
    ];

    test('two hours short of the personal median scores the whole weight', () {
      final RiskContribution sleep = contributionOf(
        run(nights: nightsEndingWith(5)).days.first,
        RiskSignal.sleepDebt,
      );

      expect(sleep.points, RiskScoreEngine.sleepWeight.toDouble());
      expect(sleep.sleepDebtMinutes, 130);
    });

    test('a long night scores nothing rather than a negative', () {
      expect(
        contributionOf(
          run(nights: nightsEndingWith(9)).days.first,
          RiskSignal.sleepDebt,
        ).points,
        0,
      );
    });

    // Last night is a fact about today; carrying it forward would score Friday on how Monday slept.
    test('tomorrow has no sleep reading at all', () {
      final RiskForecast forecast = run(nights: nightsEndingWith(5));

      expect(
        contributionOf(forecast.days[1], RiskSignal.sleepDebt).isAvailable,
        isFalse,
      );
    });
  });

  group('the score', () {
    // A day missing its sleep reading must not score low for the reason that nothing was known about it.
    test('it is a share of what could be read, not of a fixed 100', () {
      final DailyRisk today = run(
        weather: weatherFalling(drop: 10),
        cycleDays: <CycleDay>[
          CycleDay(
            day: DateTime(2026, 9, 4),
            hasFlow: true,
            isPeriodStart: true,
          ),
        ],
      ).days.first;

      // Pressure 40/40 and cycle 25/25 with no sleep and a quiet week: 65 of 80.
      expect(today.availablePoints, 80);
      expect(today.score, 81);
      expect(today.band, RiskBand.high);
    });

    test('nothing readable is a zero rather than a crash', () {
      final DailyRisk today = run(attacks: const <Attack>[]).days.first;

      expect(today.availablePoints, 0);
      expect(today.score, 0);
      expect(today.band, RiskBand.low);
    });
  });

  group('the gate', () {
    test('a fortnight of history is what it waits for', () {
      final RiskForecast thin = run(
        weather: weatherFalling(drop: 4),
        attacks: <Attack>[attackAt(now.subtract(const Duration(days: 3)))],
      );

      expect(thin.isReady, isFalse);
      expect(thin.requiredHistoryDays, 14);
    });

    test('enough history and one readable signal is ready', () {
      expect(run(weather: weatherFalling(drop: 4)).isReady, isTrue);
    });
  });
}
