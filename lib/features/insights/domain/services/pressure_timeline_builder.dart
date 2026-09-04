import '../../../attacks/domain/entities/attack.dart';
import '../../../weather/domain/entities/daily_pressure.dart';
import '../../../weather/domain/entities/weather_snapshot.dart';
import '../entities/pressure_timeline.dart';

/// Joins the daily pressure readings to the attacks that fell on them.
class PressureTimelineBuilder {
  const PressureTimelineBuilder({this.windowDays = defaultWindowDays})
    : assert(windowDays > 0, 'windowDays must be positive');

  /// A month.
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
      // Local, like every day count in this feature: an attack at 23:30 is stored as the next UTC day and would land on the wrong reading.
      final DateTime local = attack.startedAt.toLocal();
      final DateTime day = DateTime(local.year, local.month, local.day);

      if (day.isBefore(firstDay)) continue;

      attacksByDay.putIfAbsent(day, () => <Attack>[]).add(attack);
    }

    final List<PressureTimelineDay> days = <PressureTimelineDay>[];
    final Set<DateTime> plotted = <DateTime>{};
    // Filled as the days are walked, so a moment's x is the day's own index on the line rather than a date the chart would have to look up.
    final List<PressureTimelineMoment> moments = <PressureTimelineMoment>[];

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
    // After the sort, never during it: a moment's x is a position on the drawn line, and the line is only in date order once this has run.
    for (final (int index, PressureTimelineDay day) in days.indexed) {
      for (final Attack attack in attacksByDay[day.day] ?? const <Attack>[]) {
        // Only an attack that recorded the pressure at its own hour can be placed at that hour; the rest stay the day's own dot.
        if (attack.weather case final WeatherSnapshot snapshot) {
          final DateTime local = attack.startedAt.toLocal();

          moments.add(
            PressureTimelineMoment(
              at: local,
              x: index + (local.hour + local.minute / 60) / 24,
              pressureHpa: snapshot.pressureHpa,
              intensity: attack.intensity,
            ),
          );
        }
      }
    }

    int stranded = 0;

    for (final MapEntry<DateTime, List<Attack>> entry in attacksByDay.entries) {
      if (!plotted.contains(entry.key)) stranded += entry.value.length;
    }

    return PressureTimeline(
      days: days,
      attacksWithoutReading: stranded,
      moments: moments,
    );
  }
}
