import '../entities/cycle_day.dart';
import '../entities/cycle_sample.dart';

/// Groups menstruation samples into one entry per local day, oldest first.
class CycleDayAggregator {
  const CycleDayAggregator();

  List<CycleDay> aggregate(List<CycleSample> samples) {
    final Map<DateTime, CycleDay> byDay = <DateTime, CycleDay>{};

    for (final CycleSample sample in samples) {
      final DateTime local = sample.start.toLocal();
      final DateTime day = DateTime(local.year, local.month, local.day);
      final CycleDay? existing = byDay[day];

      // Either flag wins for the day: a day with two samples where one says bleeding is a day with bleeding.
      byDay[day] = CycleDay(
        day: day,
        hasFlow: (existing?.hasFlow ?? false) || sample.hasFlow,
        isPeriodStart: (existing?.isPeriodStart ?? false) || sample.isPeriodStart,
      );
    }
    final List<CycleDay> days = byDay.values.toList()
      ..sort((CycleDay a, CycleDay b) => a.day.compareTo(b.day));

    return days;
  }
}
