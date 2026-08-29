import 'package:meta/meta.dart';

import '../../../attacks/domain/entities/attack.dart';

@immutable
class WeeklyBucket {
  const WeeklyBucket({required this.weekStart, required this.count});

  /// Local midnight on the Monday this bucket starts.
  final DateTime weekStart;
  final int count;
}

/// Buckets attacks into calendar weeks for the frequency chart.
class WeeklyBucketsCalculator {
  const WeeklyBucketsCalculator();

  /// Buckets attacks into the last [weeks] calendar weeks (Monday-start, user-local time), oldest first.
  List<WeeklyBucket> compute(
    List<Attack> attacks, {
    required DateTime now,
    int weeks = 8,
  }) {
    final currentWeek = _mondayOf(now.toLocal());
    final starts = [
      for (int i = weeks - 1; i >= 0; i--)
        currentWeek.subtract(Duration(days: 7 * i)),
    ];
    final counts = {for (final start in starts) start: 0};

    for (final attack in attacks) {
      final week = _mondayOf(attack.startedAt.toLocal());
      if (counts.containsKey(week)) {
        counts[week] = counts[week]! + 1;
      }
    }

    return [
      for (final start in starts)
        WeeklyBucket(weekStart: start, count: counts[start]!),
    ];
  }

  DateTime _mondayOf(DateTime d) {
    final midnight = DateTime(d.year, d.month, d.day);
    return midnight.subtract(Duration(days: midnight.weekday - 1));
  }
}
