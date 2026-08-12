import '../../../health/domain/entities/sleep_night.dart';
import '../../../health/domain/entities/step_day.dart';
import '../enums/health_range.dart';

/// One bar of a ranged health chart: a value and the label under it.
///
/// Pure numbers — the label is built from a date by the caller, which is
/// where the locale is known (hard rule 6).
class HealthBucket {
  const HealthBucket({required this.start, required this.value});

  /// Local time the bucket covers from.
  final DateTime start;
  final double value;
}

/// Groups days into the bars a [HealthRange] draws.
///
/// Pure Dart and its own class rather than arithmetic inside a chart widget:
/// both cards bucket the same way, and a widget doing its own would be the
/// second copy the moment sleep and steps disagreed about what a week is.
final class HealthRangeBuckets {
  /// Steps per bar. Weekly ranges SUM, because steps are a count and half a
  /// year of daily totals is unreadable — a week's total is the honest
  /// aggregate of seven daily totals.
  static List<HealthBucket> steps(List<StepDay> days, HealthRange range) {
    final List<HealthBucket> daily = <HealthBucket>[
      for (final StepDay day in days)
        HealthBucket(start: day.date, value: day.count.toDouble()),
    ];

    return range.isWeekly ? _weekly(daily, average: false) : daily;
  }

  /// Sleep hours per bar. Weekly ranges AVERAGE, not sum: "56 hours" for a
  /// week says nothing a reader can compare against a night, and every other
  /// sleep figure in the app is per-night.
  static List<HealthBucket> sleep(List<SleepNight> nights, HealthRange range) {
    final List<HealthBucket> daily = <HealthBucket>[
      for (final SleepNight night in nights)
        HealthBucket(start: night.date, value: night.hours),
    ];

    return range.isWeekly ? _weekly(daily, average: true) : daily;
  }

  /// Collapses daily buckets into weeks starting on Monday.
  ///
  /// A week with no data at all is absent rather than zero, the same rule the
  /// aggregators follow — "no record" is not "no steps" and not "no sleep".
  static List<HealthBucket> _weekly(
    List<HealthBucket> daily, {
    required bool average,
  }) {
    final Map<DateTime, List<double>> weeks = <DateTime, List<double>>{};

    for (final HealthBucket bucket in daily) {
      weeks.putIfAbsent(_weekStart(bucket.start), () => <double>[]).add(
        bucket.value,
      );
    }

    final List<DateTime> starts = weeks.keys.toList()..sort();

    return <HealthBucket>[
      for (final DateTime start in starts)
        HealthBucket(
          start: start,
          value: average
              ? weeks[start]!.reduce((double a, double b) => a + b) /
                    weeks[start]!.length
              : weeks[start]!.reduce((double a, double b) => a + b),
        ),
    ];
  }

  /// The Monday of the week [value] falls in, at local midnight.
  static DateTime _weekStart(DateTime value) {
    final DateTime day = DateTime(value.year, value.month, value.day);

    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }
}
