import '../../../attacks/domain/entities/attack.dart';
import '../entities/migraine_days_summary.dart';

/// Monthly migraine days — the figure a headache clinic opens with and every
/// preventive is judged on.
///
/// Pure Dart and deterministic. It counts *days*, not attacks: three attacks
/// in one day is one day someone lost, and a drug that halves the attacks
/// without touching the days has not worked.
class MigraineDaysEngine {
  const MigraineDaysEngine({this.months = defaultMonths})
    : assert(months > 0, 'months must be positive');

  /// Six months of history. Long enough to show a preventive taking hold —
  /// they are judged at three — and short enough that the bars stay readable
  /// on a card.
  static const int defaultMonths = 6;

  final int months;

  /// [now] is the caller's clock, so the window ends on the month the user is
  /// actually in. Local throughout: an attack belongs to the local day it
  /// started, and taking the UTC date files whole evenings under the wrong
  /// month for anyone east of Greenwich.
  MigraineDaysSummary analyze(List<Attack> attacks, {required DateTime now}) {
    final DateTime firstMonth = _monthOf(
      DateTime(now.year, now.month - (months - 1), now.day),
    );
    final Map<DateTime, Set<DateTime>> daysByMonth =
        <DateTime, Set<DateTime>>{};
    final Map<DateTime, int> attacksByMonth = <DateTime, int>{};

    for (final Attack attack in attacks) {
      final DateTime local = attack.startedAt.toLocal();
      final DateTime month = _monthOf(local);

      if (month.isBefore(firstMonth)) continue;

      daysByMonth
          .putIfAbsent(month, () => <DateTime>{})
          .add(DateTime(local.year, local.month, local.day));
      attacksByMonth[month] = (attacksByMonth[month] ?? 0) + 1;
    }

    // Every month in the window gets a row, including the empty ones. A month
    // with no attacks is not missing data — it is the best month the user had,
    // and dropping it would hide exactly the result a preventive is meant to
    // produce.
    final List<MonthlyMigraineDays> rows = <MonthlyMigraineDays>[
      for (int i = 0; i < months; i++)
        if (DateTime(firstMonth.year, firstMonth.month + i) case final DateTime
            month)
          MonthlyMigraineDays(
            month: month,
            days: daysByMonth[month]?.length ?? 0,
            attacks: attacksByMonth[month] ?? 0,
          ),
    ];

    return MigraineDaysSummary(months: rows);
  }

  DateTime _monthOf(DateTime value) => DateTime(value.year, value.month);
}
