import '../entities/cycle_day.dart';

/// Whether a day falls in the stretch around a period start when attacks cluster.
///
/// The window is day -2 to +3 around the day HealthKit itself marks as the
/// cycle start — the perimenstrual window menstrual migraine is defined by
/// (ICHD-3 A1.1.1). It is deliberately narrow: widening it until most of the
/// month qualifies would make every attack look hormonal.
class CycleWindowCalculator {
  const CycleWindowCalculator();

  /// Days before the period start that count as inside the window.
  static const int daysBefore = 2;

  /// Days after it, the start day itself being day 0.
  static const int daysAfter = 3;

  bool isInWindow(List<CycleDay> days, DateTime day) =>
      dayInCycle(days, day) != null;

  /// Where [day] sits relative to the nearest period start: -2 through +3, or null when it is outside every window.
  int? dayInCycle(List<CycleDay> days, DateTime day) {
    final DateTime target = DateTime(day.year, day.month, day.day);

    for (final CycleDay start in days) {
      if (!start.isPeriodStart) continue;

      final int offset = target.difference(start.day).inDays;

      if (offset >= -daysBefore && offset <= daysAfter) return offset;
    }
    return null;
  }
}
