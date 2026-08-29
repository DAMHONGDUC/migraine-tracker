import '../entities/step_day.dart';
import '../entities/step_sample.dart';

/// Turns raw HealthKit step samples into one count per day.
class StepDayAggregator {
  const StepDayAggregator();

  /// [samples] in any order; the result is one entry per day with data, oldest first.
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
