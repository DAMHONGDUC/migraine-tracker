import '../../../health/domain/entities/sleep_night.dart';
import '../../../health/domain/entities/step_day.dart';
import '../enums/health_range.dart';

/// One bar of a ranged health chart: a value and the label under it.
class HealthBucket {
  const HealthBucket({required this.start, required this.value});

  /// Local time the bucket covers from.
  final DateTime start;
  final double value;
}

/// Groups days into the bars a [HealthRange] draws.
final class HealthRangeBuckets {
  /// Steps per bar.
  static List<HealthBucket> steps(List<StepDay> days, HealthRange range) {
    final List<HealthBucket> daily = <HealthBucket>[
      for (final StepDay day in days)
        HealthBucket(start: day.date, value: day.count.toDouble()),
    ];

    return range.isWeekly ? _weekly(daily, average: false) : daily;
  }

  /// Sleep hours per bar.
  static List<HealthBucket> sleep(List<SleepNight> nights, HealthRange range) {
    final List<HealthBucket> daily = <HealthBucket>[
      for (final SleepNight night in nights)
        HealthBucket(start: night.date, value: night.hours),
    ];

    return range.isWeekly ? _weekly(daily, average: true) : daily;
  }

  /// Collapses daily buckets into weeks starting on Monday.
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
