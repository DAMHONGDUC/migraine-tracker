import '../../../attacks/domain/entities/attack.dart';
import '../enums/history_period.dart';

/// Filters attacks by the History screen's selected [HistoryPeriod].
class AttackPeriodFilterer {
  const AttackPeriodFilterer();

  /// Inclusive lower bound (local time) of [period] relative to [now], or
  /// null for [HistoryPeriod.all]. Weeks start on Monday to match the
  /// frequency chart.
  DateTime? periodStart(HistoryPeriod period, DateTime now) {
    final local = now.toLocal();
    final midnight = DateTime(local.year, local.month, local.day);

    return switch (period) {
      HistoryPeriod.today => midnight,
      HistoryPeriod.week => midnight.subtract(
        Duration(days: midnight.weekday - 1),
      ),
      HistoryPeriod.month => DateTime(local.year, local.month),
      HistoryPeriod.year => DateTime(local.year),
      HistoryPeriod.all => null,
    };
  }

  /// Attacks whose local start time falls within [period]. Pure Dart.
  List<Attack> filterByPeriod(
    List<Attack> attacks,
    HistoryPeriod period,
    DateTime now,
  ) {
    final start = periodStart(period, now);
    if (start == null) return attacks;
    return attacks
        .where((a) => !a.startedAt.toLocal().isBefore(start))
        .toList();
  }
}
