import 'package:meta/meta.dart';

/// One month's migraine days.
@immutable
class MonthlyMigraineDays {
  const MonthlyMigraineDays({
    required this.month,
    required this.days,
    required this.attacks,
  });

  /// The first of the month, in local time — the month a person lived, not
  /// the one UTC was in.
  final DateTime month;

  /// Distinct local days with at least one attack. Days, not attacks: three
  /// attacks in one day is one migraine day, and it is the count every
  /// headache clinic asks for and every preventive is judged on.
  final int days;

  /// Attacks logged that month, which [days] deliberately collapses. Kept
  /// because "8 days, 20 attacks" and "8 days, 8 attacks" are different
  /// months to the person who lived them.
  final int attacks;
}

/// Migraine days over the recent months, newest last.
///
/// Not a sealed result like the correlation engines, and deliberately: those
/// state a relationship, which a thin sample can make a false claim about.
/// This is a count. One month of logging gives a true count of one month, so
/// there is no minimum to grade against and nothing to withhold.
@immutable
class MigraineDaysSummary {
  const MigraineDaysSummary({required this.months});

  const MigraineDaysSummary.empty() : months = const <MonthlyMigraineDays>[];

  /// Oldest first, one entry per month in the window, including the months
  /// with no attacks at all.
  final List<MonthlyMigraineDays> months;

  /// The month in progress — the figure the dashboard leads with.
  MonthlyMigraineDays? get currentMonth => months.isEmpty ? null : months.last;

  /// The month before it, or null when the window holds only one.
  MonthlyMigraineDays? get previousMonth =>
      months.length < 2 ? null : months[months.length - 2];

  /// Days more (positive) or fewer (negative) than last month, or null while
  /// there is no last month to compare against.
  ///
  /// **The current month is still running**, so this compares a partial month
  /// against a whole one and will read low early on. Whatever states it has
  /// to say so.
  int? get changeFromPreviousMonth {
    final MonthlyMigraineDays? current = currentMonth;
    final MonthlyMigraineDays? previous = previousMonth;

    if (current == null || previous == null) return null;

    return current.days - previous.days;
  }

  /// The busiest month in the window — what a y-axis has to reach.
  int get peakDays => months.fold(0, (max, m) => m.days > max ? m.days : max);
}
