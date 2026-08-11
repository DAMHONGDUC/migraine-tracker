import '../entities/step_hour.dart';
import '../entities/step_sample.dart';

/// Turns raw HealthKit step samples into one count per hour.
///
/// The hourly twin of [StepDayAggregator], and it sums for the same reason:
/// HealthKit already dedupes steps across the phone and the watch, so adding
/// every sample in an hour is the honest total.
///
/// A sample is credited to the hour it *starts* in. Splitting one across the
/// hours it spans would need a distribution HealthKit does not report, and
/// inventing a flat one would put steps in minutes the user was sitting
/// still.
class StepHourAggregator {
  const StepHourAggregator();

  /// [samples] in any order; the result is one entry per hour that has data,
  /// oldest first. An hour with no samples is absent rather than zero — "no
  /// record" is not "no steps", the same rule the daily aggregator follows.
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
