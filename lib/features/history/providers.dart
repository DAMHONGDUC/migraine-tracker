import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../attacks/domain/entities/attack.dart';
import '../attacks/providers.dart';
import 'domain/enums/history_period.dart';
import 'domain/enums/history_view_mode.dart';
import 'domain/services/attack_period_filter.dart';
import 'presentation/controllers/history_controller.dart';

/// The period the History screen is filtered to (shared by list AND chart).
/// See [HistoryController].
final historyPeriodProvider =
    NotifierProvider<HistoryController, HistoryPeriod>(HistoryController.new);

/// List ↔ chart toggle on the History app bar. See [HistoryViewModeController].
final historyViewModeProvider =
    NotifierProvider<HistoryViewModeController, HistoryViewMode>(
      HistoryViewModeController.new,
    );

/// Attacks after applying the selected period filter, newest first.
final filteredAttacksProvider = Provider<AsyncValue<List<Attack>>>((ref) {
  final period = ref.watch(historyPeriodProvider);
  final attacks = ref.watch(attacksStreamProvider);
  return attacks.whenData(
    (list) =>
        const AttackPeriodFilterer().filterByPeriod(list, period, DateTime.now()),
  );
});
