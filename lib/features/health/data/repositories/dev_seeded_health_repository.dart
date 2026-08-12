import 'dart:math';

import '../../domain/entities/sleep_night.dart';
import '../../domain/entities/step_day.dart';
import '../../domain/entities/step_hour.dart';
import '../../domain/enums/health_data_kind.dart';
import '../../domain/repositories/health_repository.dart';

/// Dev-only stand-in for HealthKit, generating nights and steps from a seed.
///
/// **It exists because HealthKit does not on the Simulator.** Sleep and step
/// reads there come back empty, and nothing about the app can tell that from
/// a refusal — so the sleep and activity cards can never be seen populated
/// without a real device and a real Health history. This makes both cards,
/// their range selectors and both correlations reviewable on a laptop.
///
/// **Nothing is stored.** Hard rule: HealthKit is read-only and no health
/// data is persisted, so this generates on demand from [seed] rather than
/// writing rows anywhere. The same seed gives the same history across
/// restarts, and reseeding gives a different one.
///
/// Never reachable in a prod flavour — `healthRepositoryProvider` only builds
/// it behind `!AppEnv.isProd`, and only when the dev seed has run.
class DevSeededHealthRepository implements HealthRepository {
  const DevSeededHealthRepository(this.seed);

  final int seed;

  /// Nights the user slept badly, as a share. Enough of them, and correlated
  /// with nothing in particular, so the sleep engine reaches a verdict
  /// instead of sitting on an empty side.
  static const double _shortNightShare = 0.35;

  @override
  bool get isAvailable => true;

  /// Always answered, never refused: the Simulator has no sheet to show, and
  /// a false here would put the card back in its "connect" state — the one
  /// this repository exists to get past.
  @override
  Future<bool> requestAuthorization(HealthDataKind kind) async => true;

  @override
  Future<List<SleepNight>> sleepNights({
    required DateTime from,
    required DateTime to,
  }) async {
    final List<SleepNight> nights = <SleepNight>[];

    for (final DateTime day in _days(from, to)) {
      final Random random = _randomFor(day, 'sleep');
      // A gap now and then: HealthKit reports nothing for a night the phone
      // was off the user, and both the aggregator and the chart must cope.
      if (random.nextInt(12) == 0) continue;

      final bool short = random.nextDouble() < _shortNightShare;
      final double hours = short
          ? 3.5 + random.nextDouble() * 2
          : 6.5 + random.nextDouble() * 2.5;

      nights.add(
        SleepNight(
          date: day,
          duration: Duration(minutes: (hours * 60).round()),
        ),
      );
    }

    return nights;
  }

  @override
  Future<List<StepDay>> stepDays({
    required DateTime from,
    required DateTime to,
  }) async {
    final List<StepDay> days = <StepDay>[];

    for (final DateTime day in _days(from, to)) {
      final Random random = _randomFor(day, 'steps');

      if (random.nextInt(15) == 0) continue;

      // Weekends run lower, so the bars have a shape rather than noise.
      final bool weekend = day.weekday >= DateTime.saturday;
      final int base = weekend ? 3000 : 7000;

      days.add(StepDay(date: day, count: base + random.nextInt(6000)));
    }

    return days;
  }

  @override
  Future<List<StepHour>> stepHours({
    required DateTime from,
    required DateTime to,
  }) async {
    final DateTime day = DateTime(from.year, from.month, from.day);
    final Random random = _randomFor(day, 'hours');
    final List<StepHour> hours = <StepHour>[];

    for (int hour = 0; hour < 24; hour++) {
      final DateTime at = day.add(Duration(hours: hour));

      if (at.isAfter(to)) break;
      // Asleep, and the strip should show the gap rather than a flat floor.
      if (hour < 7) continue;

      // Two humps, morning and evening, like a real day's walking.
      final int peak = hour == 8 || hour == 12 || hour == 18 ? 1200 : 300;

      hours.add(StepHour(hour: at, count: random.nextInt(peak)));
    }

    return hours;
  }

  /// Every local day in the window, oldest first.
  Iterable<DateTime> _days(DateTime from, DateTime to) sync* {
    DateTime day = DateTime(from.year, from.month, from.day);
    final DateTime last = DateTime(to.year, to.month, to.day);

    while (!day.isAfter(last)) {
      yield day;
      day = day.add(const Duration(days: 1));
    }
  }

  /// Per-day generator, so a day's numbers are the same whichever window
  /// asked for it — a week and a month must not disagree about Tuesday.
  Random _randomFor(DateTime day, String salt) =>
      Random(Object.hash(seed, day.year, day.month, day.day, salt));
}
