import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/providers.dart';
import '../../domain/enums/history_period.dart';
import '../../domain/services/attack_period_filter.dart';

/// The period the History screen is filtered to.
class HistoryController extends Notifier<HistoryPeriod> {
  @override
  HistoryPeriod build() => HistoryPeriod.all;

  void select(HistoryPeriod period) => state = period;
}

final historyPeriodProvider =
    NotifierProvider<HistoryController, HistoryPeriod>(HistoryController.new);

/// Attacks after applying the selected period filter, newest first.
final filteredAttacksProvider = Provider<AsyncValue<List<Attack>>>((ref) {
  final period = ref.watch(historyPeriodProvider);
  final attacks = ref.watch(attacksStreamProvider);
  return attacks.whenData(
    (list) => filterByPeriod(list, period, DateTime.now()),
  );
});
