import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../domain/enums/history_period.dart';
import '../../domain/enums/history_view_mode.dart';
import '../../domain/services/attack_period_filter.dart';

/// The period the History screen is filtered to (shared by list AND chart).
class HistoryController extends Notifier<HistoryPeriod> {
  static const _filterer = AttackPeriodFilterer();

  @override
  HistoryPeriod build() => HistoryPeriod.all;

  void select(HistoryPeriod period) {
    AppLogger.action('History period', period.name);
    state = period;
  }

  /// Attacks whose local start time falls within the selected period.
  List<Attack> filter(List<Attack> attacks) =>
      _filterer.filterByPeriod(attacks, state, DateTime.now());
}

/// List ↔ chart toggle on the History app bar.
class HistoryViewModeController extends Notifier<HistoryViewMode> {
  @override
  HistoryViewMode build() => HistoryViewMode.list;

  void select(HistoryViewMode mode) {
    AppLogger.action('History view', mode.name);
    state = mode;
  }
}
