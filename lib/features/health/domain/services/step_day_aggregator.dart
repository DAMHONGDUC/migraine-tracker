import '../entities/step_day.dart';
import '../entities/step_sample.dart';

/// Turns raw HealthKit step samples into one count per day.
///
/// Pure Dart, deterministic. Unlike [SleepNightAggregator] this does NOT
/// merge overlapping samples: HealthKit already dedupes steps across the
/// phone and the watch server-side, so summing every sample for a day is the
/// honest total — a merge step here would only discard real steps that
/// happen to fall in the same window from two sources.
class StepDayAggregator {
  const StepDayAggregator();

  /// [samples] in any order; the result is one entry per day with data,
  /// oldest first. Days the user has no samples for are simply absent — "no
  /// record" is not "no steps".
  List<StepDay> aggregate(List<StepSample> samples) {
    final Map<DateTime, int> totals = <DateTime, int>{};

    for (final StepSample sample in samples) {
      final DateTime day = _dateOnly(sample.start);
      totals[day] = (totals[day] ?? 0) + sample.count;
    }

    final List<DateTime> dates = totals.keys.toList()..sort();

    return <StepDay>[
      for (final DateTime date in dates)
        StepDay(date: date, count: totals[date]!),
    ];
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
