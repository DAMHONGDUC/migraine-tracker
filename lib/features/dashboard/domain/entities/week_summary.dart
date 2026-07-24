import 'package:meta/meta.dart';

/// At-a-glance stats for the dashboard's weekly summary card. Pure value
/// object computed by [WeekSummaryCalculator] from the attack list — the
/// dashboard widget only renders it.
@immutable
class WeekSummary {
  const WeekSummary({
    required this.thisWeekCount,
    required this.lastWeekCount,
    required this.averageIntensity,
  });

  /// Attacks whose local start falls in the current Monday-start week.
  final int thisWeekCount;

  /// Attacks in the previous Monday-start week — the trend comparison.
  final int lastWeekCount;

  /// Mean pain intensity of this week's attacks, or null when there were
  /// none (nothing to average).
  final double? averageIntensity;

  /// Signed change vs last week: positive = more attacks this week.
  int get trend => thisWeekCount - lastWeekCount;
}
