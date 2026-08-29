import 'package:meta/meta.dart';

/// One month's migraine days.
@immutable
class MonthlyMigraineDays {
  const MonthlyMigraineDays({
    required this.month,
    required this.days,
    required this.attacks,
  });

  /// The first of the month, in local time — the month a person lived, not the one UTC was in.
  final DateTime month;

  /// Distinct local days with at least one attack.
  final int days;

  /// Attacks logged that month, which [days] deliberately collapses.
  final int attacks;
}

/// Migraine days over the recent months, newest last.
@immutable
class MigraineDaysSummary {
  const MigraineDaysSummary({required this.months});

  const MigraineDaysSummary.empty() : months = const <MonthlyMigraineDays>[];

  /// Oldest first, one entry per month in the window, including the months with no attacks at all.
  final List<MonthlyMigraineDays> months;

  /// The month in progress — the figure the dashboard leads with.
  MonthlyMigraineDays? get currentMonth => months.isEmpty ? null : months.last;

  /// The month before it, or null when the window holds only one.
  MonthlyMigraineDays? get previousMonth =>
      months.length < 2 ? null : months[months.length - 2];

  /// Days more (positive) or fewer (negative) than last month, or null while there is no last month to compare against.
  int? get changeFromPreviousMonth {
    final MonthlyMigraineDays? current = currentMonth;
    final MonthlyMigraineDays? previous = previousMonth;

    if (current == null || previous == null) return null;

    return current.days - previous.days;
  }

  /// The busiest month in the window — what a y-axis has to reach.
  int get peakDays => months.fold(0, (max, m) => m.days > max ? m.days : max);
}
