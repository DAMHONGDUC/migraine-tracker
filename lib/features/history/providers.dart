import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../attacks/domain/entities/attack.dart';
import '../attacks/providers.dart';
import 'domain/entities/attack_filter_options.dart';
import 'domain/enums/attack_filters.dart';
import 'domain/enums/history_view_mode.dart';
import 'domain/services/attack_filterer.dart';
import 'presentation/controllers/attack_filters_controller.dart';
import 'presentation/controllers/history_controller.dart';

/// Every axis the History screen is filtered by, period included. See [AttackFiltersController].
final attackFiltersProvider =
    NotifierProvider<AttackFiltersController, AttackFilters>(
      AttackFiltersController.new,
    );

/// List ↔ calendar ↔ chart toggle on the History app bar. See [HistoryViewModeController].
final historyViewModeProvider =
    NotifierProvider<HistoryViewModeController, HistoryViewMode>(
      HistoryViewModeController.new,
    );

/// Attacks after applying every filter, newest first.
final filteredAttacksProvider = Provider<AsyncValue<List<Attack>>>((Ref ref) {
  ref.watch(attackFiltersProvider);
  final AsyncValue<List<Attack>> attacks = ref.watch(attacksStreamProvider);
  final AttackFiltersController controller = ref.read(
    attackFiltersProvider.notifier,
  );

  return attacks.whenData(controller.filter);
});

/// What the sheet's free-text sections offer, taken from every attack on record — NOT from the filtered list, or picking one value would hide the rest.
final attackFilterOptionsProvider = Provider<AttackFilterOptions>((Ref ref) {
  const AttackFilterer filterer = AttackFilterer();
  final List<Attack> attacks =
      ref.watch(attacksStreamProvider).value ?? const <Attack>[];

  if (attacks.isEmpty) return AttackFilterOptions.empty;

  return AttackFilterOptions(
    medicationNames: filterer.textOptions(
      attacks,
      (Attack attack) => <String>[attack.medicationName ?? ''],
    ),
    symptoms: filterer.textOptions(attacks, (Attack attack) => attack.symptoms),
    triggers: filterer.textOptions(attacks, (Attack attack) => attack.triggers),
  );
});
