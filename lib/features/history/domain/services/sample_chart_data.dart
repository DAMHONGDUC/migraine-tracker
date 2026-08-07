import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/domain/enums/head_location.dart';

/// Fabricated attacks that draw the shape of the History chart deck for a
/// free user, behind the unlock cover.
///
/// It exists so a locked chart can be blurred without the user's own numbers
/// ever entering the widget tree — a cover over real data still leaves it
/// there, one screenshot away. Fed through the SAME calculators as the real
/// deck, so the locked preview cannot drift from what premium unlocks.
final class SampleChartData {
  const SampleChartData._();

  /// Attacks per week, oldest first — uneven on purpose, so the frequency
  /// bars and the intensity line both have something to show.
  static const List<int> _weeklyCounts = <int>[3, 5, 2, 6, 4, 7, 3, 5];

  /// Cycled per attack, spread across all four severity bands.
  static const List<int> _intensities = <int>[3, 6, 8, 4, 9, 2, 7, 5, 10, 6];

  /// Cycled per attack, spread across all four quarters of the day.
  static const List<int> _hours = <int>[3, 9, 14, 20, 11, 16, 22, 7];

  /// The last 8 calendar weeks of made-up attacks, relative to [now].
  static List<Attack> attacks({required DateTime now}) {
    final DateTime midnight = DateTime(now.year, now.month, now.day);
    final DateTime currentWeek = midnight.subtract(
      Duration(days: midnight.weekday - 1),
    );
    final List<Attack> result = <Attack>[];
    int index = 0;

    for (final (int week, int count) in _weeklyCounts.indexed) {
      final DateTime weekStart = currentWeek.subtract(
        Duration(days: 7 * (_weeklyCounts.length - 1 - week)),
      );

      for (int day = 0; day < count; day++) {
        result.add(
          Attack(
            id: 'sample-$index',
            startedAt: weekStart.add(
              Duration(days: day, hours: _hours[index % _hours.length]),
            ),
            intensity: _intensities[index % _intensities.length],
            location: HeadLocation.values[index % HeadLocation.values.length],
          ),
        );
        index++;
      }
    }

    return result;
  }
}
