import '../entities/step_hour.dart';
import '../entities/step_sample.dart';

/// Turns raw HealthKit step samples into one count per hour.
class StepHourAggregator {
  const StepHourAggregator();

  /// [samples] in any order; the result is one entry per hour that has data, oldest first.
  List<StepHour> aggregate(List<StepSample> samples) {
    final Map<DateTime, int> totals = <DateTime, int>{};

    for (final StepSample sample in samples) {
      final DateTime hour = _hourOnly(sample.start);

      totals[hour] = (totals[hour] ?? 0) + sample.count;
    }

    final List<DateTime> hours = totals.keys.toList()..sort();

    return <StepHour>[
      for (final DateTime hour in hours)
        StepHour(hour: hour, count: totals[hour]!),
    ];
  }

  DateTime _hourOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day, value.hour);
}
