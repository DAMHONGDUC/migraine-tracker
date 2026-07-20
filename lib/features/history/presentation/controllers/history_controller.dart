import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/enums/history_period.dart';
import '../../domain/enums/history_view_mode.dart';

/// The period the History screen is filtered to (shared by list AND chart).
class HistoryController extends Notifier<HistoryPeriod> {
  @override
  HistoryPeriod build() => HistoryPeriod.all;

  void select(HistoryPeriod period) => state = period;
}

/// List ↔ chart toggle on the History app bar.
class HistoryViewModeController extends Notifier<HistoryViewMode> {
  @override
  HistoryViewMode build() => HistoryViewMode.list;

  void select(HistoryViewMode mode) => state = mode;
}
