import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../attacks/domain/entities/attack.dart';
import '../../domain/enums/history_period.dart';
import '../../domain/enums/history_view_mode.dart';
import '../../domain/services/attack_period_filter.dart';

/// The period the History screen is filtered to (shared by list AND chart).
class HistoryController extends Notifier<HistoryPeriod> {
  static const _filterer = AttackPeriodFilterer();

  @override
  HistoryPeriod build() => HistoryPeriod.all;

  void select(HistoryPeriod period) => state = period;

  /// Attacks whose local start time falls within the selected period.
  List<Attack> filter(List<Attack> attacks) =>
      _filterer.filterByPeriod(attacks, state, DateTime.now());
}

/// List ↔ chart toggle on the History app bar.
class HistoryViewModeController extends Notifier<HistoryViewMode> {
  @override
  HistoryViewMode build() => HistoryViewMode.list;

  void select(HistoryViewMode mode) => state = mode;
}
