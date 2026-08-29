import '../../../attacks/domain/entities/attack.dart';
import '../entities/week_summary.dart';

/// Computes the dashboard's [WeekSummary] from the full attack list.
class WeekSummaryCalculator {
  const WeekSummaryCalculator();

  WeekSummary compute(List<Attack> attacks, {required DateTime now}) {
    final thisWeekStart = _mondayOf(now.toLocal());
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    int thisWeek = 0;
    int lastWeek = 0;
    int intensitySum = 0;

    for (final attack in attacks) {
      final week = _mondayOf(attack.startedAt.toLocal());
      if (week == thisWeekStart) {
        thisWeek++;
        intensitySum += attack.intensity;
      } else if (week == lastWeekStart) {
        lastWeek++;
      }
    }

    return WeekSummary(
      thisWeekCount: thisWeek,
      lastWeekCount: lastWeek,
      averageIntensity: thisWeek == 0 ? null : intensitySum / thisWeek,
    );
  }

  /// Local midnight on the Monday of the week containing [d].
  DateTime _mondayOf(DateTime d) {
    final midnight = DateTime(d.year, d.month, d.day);
    return midnight.subtract(Duration(days: midnight.weekday - 1));
  }
}
