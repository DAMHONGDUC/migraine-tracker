import '../entities/sleep_interval.dart';
import '../entities/sleep_night.dart';

/// Turns raw HealthKit sleep samples into one duration per night.
///
/// Pure Dart, deterministic. Two things it exists to get right:
///
/// * **Overlap.** HealthKit hands out "in bed" from the phone *and* a stage
///   sample per REM/core/deep block from the watch, covering the same
///   minutes. Summing them double-counts, sometimes triple — the union of
///   the intervals is the only figure that isn't inflated.
/// * **Which night a session belongs to.** Falling asleep before midnight
///   and after it are the same night; [nightCutoffHour] decides.
class SleepNightAggregator {
  const SleepNightAggregator({
    this.nightCutoffHour = defaultNightCutoffHour,
    this.minSession = defaultMinSession,
  }) : assert(
         nightCutoffHour >= 0 && nightCutoffHour <= 23,
         'nightCutoffHour must be an hour of the day',
       );

  /// A block ending at or after this local hour counts toward the night that
  /// ends the *next* morning: someone asleep at 22:00 is sleeping for
  /// tomorrow. Below it (a 06:00 wake-up, an afternoon nap) the block belongs
  /// to the night ending that same day.
  static const int defaultNightCutoffHour = 18;

  /// Merged blocks shorter than this are sensor noise (a watch registering a
  /// still wrist), not sleep.
  static const Duration defaultMinSession = Duration(minutes: 10);

  final int nightCutoffHour;
  final Duration minSession;

  /// [samples] in any order; the result is one entry per night with data,
  /// oldest first. Nights the user has no samples for are simply absent —
  /// "no record" is not "no sleep".
  List<SleepNight> aggregate(List<SleepInterval> samples) {
    final List<SleepInterval> merged = _merge(samples);
    final Map<DateTime, Duration> totals = <DateTime, Duration>{};

    for (final SleepInterval block in merged) {
      if (block.duration < minSession) continue;

      final DateTime night = _nightOf(block.end);
      totals[night] = (totals[night] ?? Duration.zero) + block.duration;
    }

    final List<DateTime> dates = totals.keys.toList()..sort();

    return <SleepNight>[
      for (final DateTime date in dates)
        SleepNight(date: date, duration: totals[date]!),
    ];
  }

  /// The union of [samples] as non-overlapping blocks, oldest first.
  List<SleepInterval> _merge(List<SleepInterval> samples) {
    if (samples.isEmpty) return const <SleepInterval>[];

    final List<SleepInterval> sorted = <SleepInterval>[...samples]
      ..sort((SleepInterval a, SleepInterval b) => a.start.compareTo(b.start));
    final List<SleepInterval> merged = <SleepInterval>[];
    DateTime start = sorted.first.start;
    DateTime end = sorted.first.end;

    for (final SleepInterval sample in sorted.skip(1)) {
      // Touching blocks (one ends exactly where the next starts) are one
      // stretch of sleep, so only a strictly later start opens a new block.
      if (sample.start.isAfter(end)) {
        merged.add(SleepInterval(start: start, end: end));
        start = sample.start;
        end = sample.end;
      } else if (sample.end.isAfter(end)) {
        end = sample.end;
      }
    }
    merged.add(SleepInterval(start: start, end: end));

    return merged;
  }

  /// Local midnight of the night a block ending at [end] belongs to.
  DateTime _nightOf(DateTime end) {
    // Built from parts rather than `add(Duration(days: 1))`: across a DST
    // shift adding 24 hours lands on 23:00 of the same day.
    final int dayOffset = end.hour >= nightCutoffHour ? 1 : 0;

    return DateTime(end.year, end.month, end.day + dayOffset);
  }
}
