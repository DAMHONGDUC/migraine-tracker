import '../../../attacks/domain/entities/attack.dart';
import '../../../health/domain/entities/cycle_day.dart';
import '../../../health/domain/entities/sleep_night.dart';
import '../../../health/domain/services/cycle_window_calculator.dart';
import '../../../weather/domain/entities/weather_report.dart';
import '../entities/risk_score.dart';

/// The next seven days, scored out of what the app already knows.
///
/// **Deterministic weights, never a model** (`docs/rules/DECISIONS.md`). Every
/// card shows the numbers that produced it, because the user has to be able to
/// disagree with the score — which is the one thing a model could not offer.
class RiskScoreEngine {
  const RiskScoreEngine({this.cycles = const CycleWindowCalculator()});

  /// Weights, out of 100 when every signal can be read. Pressure leads because it is the app's own promise and the only signal that looks forward on its own.
  static const int pressureWeight = 40;
  static const int cycleWeight = 25;
  static const int sleepWeight = 20;
  static const int frequencyWeight = 15;

  /// Days the forecast covers, today counted as the first.
  static const int forecastDays = 7;

  /// A drop this far past the user's own threshold scores the full weight. Twice their threshold, so their setting stays the thing the score is measured against.
  static const double fullDropMultiple = 2;

  /// Two hours short of the personal baseline scores the full sleep weight.
  static const int fullSleepDebtMinutes = 120;

  /// Nights behind the sleep baseline.
  static const int sleepBaselineNights = 30;

  /// The frequency baseline's window, and the history the whole score waits for.
  static const int frequencyWindowDays = 7;
  static const int requiredHistoryDays = 14;

  final CycleWindowCalculator cycles;

  RiskForecast forecast({
    required DateTime now,
    required WeatherReport? weather,
    required double thresholdHpa,
    required List<CycleDay> cycleDays,
    required List<SleepNight> nights,
    required List<Attack> attacks,
  }) {
    final DateTime today = _dayOf(now.toLocal());
    final int? baselineMinutes = _sleepBaseline(nights);
    final RiskContribution frequency = _frequency(attacks, now);

    return RiskForecast(
      days: <DailyRisk>[
        for (int ahead = 0; ahead < forecastDays; ahead++)
          _dayAhead(
            day: DateTime(today.year, today.month, today.day + ahead),
            isToday: ahead == 0,
            weather: weather,
            thresholdHpa: thresholdHpa,
            cycleDays: cycleDays,
            nights: nights,
            baselineMinutes: baselineMinutes,
            frequency: frequency,
          ),
      ],
      historyDays: _historyDays(attacks, now),
      requiredHistoryDays: requiredHistoryDays,
    );
  }

  DailyRisk _dayAhead({
    required DateTime day,
    required bool isToday,
    required WeatherReport? weather,
    required double thresholdHpa,
    required List<CycleDay> cycleDays,
    required List<SleepNight> nights,
    required int? baselineMinutes,
    required RiskContribution frequency,
  }) {
    return DailyRisk(
      day: day,
      contributions: <RiskContribution>[
        _pressure(weather, day, thresholdHpa),
        _cycle(cycleDays, day),
        // Last night is a fact about today alone. Carrying it forward would score Friday on how Monday slept.
        isToday
            ? _sleep(nights, baselineMinutes)
            : const RiskContribution.unavailable(
                RiskSignal.sleepDebt,
                sleepWeight,
              ),
        frequency,
      ],
    );
  }

  /// The steepest fall across any 24 hours that touch [day], measured against the user's own alert threshold.
  RiskContribution _pressure(
    WeatherReport? weather,
    DateTime day,
    double thresholdHpa,
  ) {
    final List<WeatherHourly> hours = <WeatherHourly>[
      for (final WeatherHourly hour
          in weather?.hours ?? const <WeatherHourly>[])
        if (_dayOf(hour.time.toLocal()) == day) hour,
    ];

    if (hours.length < 2 || thresholdHpa <= 0) {
      return const RiskContribution.unavailable(
        RiskSignal.pressureDrop,
        pressureWeight,
      );
    }
    double highest = hours.first.pressureHpa;
    double drop = 0;

    for (final WeatherHourly hour in hours) {
      if (hour.pressureHpa > highest) highest = hour.pressureHpa;
      final double fall = highest - hour.pressureHpa;

      if (fall > drop) drop = fall;
    }
    final double share = _clamp01(drop / (thresholdHpa * fullDropMultiple));

    return RiskContribution(
      signal: RiskSignal.pressureDrop,
      points: share * pressureWeight,
      maxPoints: pressureWeight,
      isAvailable: true,
      dropHpa: drop,
    );
  }

  /// Full weight inside the perimenstrual window, nothing outside it — the window is already the narrow one, so there is no gradient to spend here.
  RiskContribution _cycle(List<CycleDay> cycleDays, DateTime day) {
    if (cycleDays.isEmpty) {
      return const RiskContribution.unavailable(
        RiskSignal.cycleWindow,
        cycleWeight,
      );
    }
    final int? dayInCycle = cycles.dayInCycle(cycleDays, day);

    return RiskContribution(
      signal: RiskSignal.cycleWindow,
      points: dayInCycle == null ? 0 : cycleWeight.toDouble(),
      maxPoints: cycleWeight,
      isAvailable: true,
      dayInCycle: dayInCycle,
    );
  }

  /// Last night against the user's own median, never against eight hours: a short night is only short for the person who usually sleeps longer.
  RiskContribution _sleep(List<SleepNight> nights, int? baselineMinutes) {
    if (nights.isEmpty || baselineMinutes == null) {
      return const RiskContribution.unavailable(
        RiskSignal.sleepDebt,
        sleepWeight,
      );
    }
    final SleepNight last = nights.last;
    final int debt = baselineMinutes - last.duration.inMinutes;
    final double share = _clamp01(debt / fullSleepDebtMinutes);

    return RiskContribution(
      signal: RiskSignal.sleepDebt,
      points: share * sleepWeight,
      maxPoints: sleepWeight,
      isAvailable: true,
      sleepDebtMinutes: debt,
    );
  }

  /// A week that is already busier than this user's ordinary week. The same number for all seven days, because it is a fact about now rather than about a day.
  RiskContribution _frequency(List<Attack> attacks, DateTime now) {
    if (attacks.isEmpty) {
      return const RiskContribution.unavailable(
        RiskSignal.recentFrequency,
        frequencyWeight,
      );
    }
    final DateTime since = now.toUtc().subtract(
      const Duration(days: frequencyWindowDays),
    );
    final int recent = attacks
        .where((Attack a) => a.startedAt.isAfter(since))
        .length;
    final double weekly = _weeklyMedian(attacks, now);
    // Above the ordinary week, scaled by that week: two against a median of one is the full weight, two against a median of four is nothing.
    final double excess = recent - weekly;
    final double share = _clamp01(excess / (weekly < 1 ? 1 : weekly));

    return RiskContribution(
      signal: RiskSignal.recentFrequency,
      points: share * frequencyWeight,
      maxPoints: frequencyWeight,
      isAvailable: true,
      recentAttacks: recent,
    );
  }

  /// The user's ordinary week, taken as the median of the last twelve.
  double _weeklyMedian(List<Attack> attacks, DateTime now) {
    final DateTime end = now.toUtc();
    final List<int> weeks = <int>[
      for (int week = 0; week < 12; week++)
        attacks.where((Attack a) {
          final DateTime from = end.subtract(Duration(days: 7 * (week + 1)));
          final DateTime to = end.subtract(Duration(days: 7 * week));

          return a.startedAt.isAfter(from) && !a.startedAt.isAfter(to);
        }).length,
    ]..sort();
    final int middle = weeks.length ~/ 2;

    return weeks.length.isOdd
        ? weeks[middle].toDouble()
        : (weeks[middle - 1] + weeks[middle]) / 2;
  }

  /// Days between the oldest attack and now — what the frequency baseline has to work with.
  int _historyDays(List<Attack> attacks, DateTime now) {
    if (attacks.isEmpty) return 0;

    DateTime oldest = attacks.first.startedAt;

    for (final Attack attack in attacks) {
      if (attack.startedAt.isBefore(oldest)) oldest = attack.startedAt;
    }
    return now.toUtc().difference(oldest).inDays;
  }

  /// The median of the nights behind the baseline window. Median, not mean: one all-nighter must not move what "ordinary" means.
  int? _sleepBaseline(List<SleepNight> nights) {
    if (nights.isEmpty) return null;

    final List<int> minutes = <int>[
      for (final SleepNight night
          in nights.length > sleepBaselineNights
              ? nights.sublist(nights.length - sleepBaselineNights)
              : nights)
        night.duration.inMinutes,
    ]..sort();
    final int middle = minutes.length ~/ 2;

    return minutes.length.isOdd
        ? minutes[middle]
        : ((minutes[middle - 1] + minutes[middle]) / 2).round();
  }

  double _clamp01(double value) => value < 0
      ? 0
      : value > 1
      ? 1
      : value;

  DateTime _dayOf(DateTime date) => DateTime(date.year, date.month, date.day);
}
