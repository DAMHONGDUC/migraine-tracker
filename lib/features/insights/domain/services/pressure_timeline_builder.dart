import '../../../attacks/domain/entities/attack.dart';
import '../../../weather/domain/entities/daily_pressure.dart';
import '../entities/pressure_timeline.dart';

/// Joins the daily pressure readings to the attacks that fell on them.
///
/// Pure Dart and deterministic. It invents nothing: a day with no reading is
/// left out of the line rather than interpolated, and the attacks stranded on
/// such days are counted so the chart can say why it is showing fewer dots
/// than the user remembers.
class PressureTimelineBuilder {
  const PressureTimelineBuilder({this.windowDays = defaultWindowDays})
    : assert(windowDays > 0, 'windowDays must be positive');

  /// A month. Long enough to hold several weather systems — the thing the
  /// chart is for — and short enough that a day is still a distinguishable
  /// step on a card-width axis.
  static const int defaultWindowDays = 30;

  final int windowDays;

  PressureTimeline build({
    required List<Attack> attacks,
    required List<DailyPressure> readings,
    required DateTime now,
  }) {
    final DateTime firstDay = DateTime(
      now.year,
      now.month,
      now.day - (windowDays - 1),
    );
    final Map<DateTime, List<Attack>> attacksByDay = <DateTime, List<Attack>>{};

    for (final Attack attack in attacks) {
      // Local, like every day count in this feature: an attack at 23:30 is
      // stored as the next UTC day and would land on the wrong reading.
      final DateTime local = attack.startedAt.toLocal();
      final DateTime day = DateTime(local.year, local.month, local.day);

      if (day.isBefore(firstDay)) continue;

      attacksByDay.putIfAbsent(day, () => <Attack>[]).add(attack);
    }

    final List<PressureTimelineDay> days = <PressureTimelineDay>[];
    final Set<DateTime> plotted = <DateTime>{};

    for (final DailyPressure reading in readings) {
      if (reading.day.isBefore(firstDay)) continue;

      final List<Attack> onDay = attacksByDay[reading.day] ?? const <Attack>[];

      plotted.add(reading.day);
      days.add(
        PressureTimelineDay(
          day: reading.day,
          pressureHpa: reading.pressureHpa,
          delta24hHpa: reading.pressureDelta24hHpa,
          attacks: onDay.length,
          peakIntensity: onDay.isEmpty
              ? null
              : onDay
                    .map((Attack a) => a.intensity)
                    .reduce((a, b) => a > b ? a : b),
        ),
      );
    }

    days.sort(
      (PressureTimelineDay a, PressureTimelineDay b) => a.day.compareTo(b.day),
    );

    int stranded = 0;

    for (final MapEntry<DateTime, List<Attack>> entry in attacksByDay.entries) {
      if (!plotted.contains(entry.key)) stranded += entry.value.length;
    }

    return PressureTimeline(days: days, attacksWithoutReading: stranded);
  }
}
