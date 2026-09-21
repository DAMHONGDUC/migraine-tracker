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

/// Attacks after applying every filter, newest first — **the readable ones
/// only**, which is what the charts average.
final filteredAttacksProvider = Provider<AsyncValue<List<Attack>>>((Ref ref) {
  ref.watch(attackFiltersProvider);
  // Windowed already: a free user filters the ninety days they can read.
  final AsyncValue<List<Attack>> attacks = ref.watch(visibleAttacksProvider);
  final AttackFiltersController controller = ref.read(
    attackFiltersProvider.notifier,
  );

  return attacks.whenData(controller.filter);
});

/// The same filters over the WHOLE record, which is what the list draws.
///
/// **The list shows every attack and blurs the ones behind the free window**
/// (owner's rule, 2026-09-21); `AttackTile` decides which, so the list and the
/// calendar cannot disagree about one row. This exists beside
/// [filteredAttacksProvider] rather than replacing it because the two answer
/// different questions: a row is a row whether or not it can be read, and a
/// chart averaging numbers the user cannot see is a number they cannot check.
///
/// **A locked row is filtered like any other** — it is still a row — but its
/// medication names, symptoms and triggers stay out of
/// [attackFilterOptionsProvider]: a chip naming a value off a blurred row
/// would print the very text the blur is hiding.
final historyRowsProvider = Provider<AsyncValue<List<Attack>>>((Ref ref) {
  ref.watch(attackFiltersProvider);

  final AsyncValue<List<Attack>> attacks = ref.watch(attacksStreamProvider);
  final AttackFiltersController controller = ref.read(
    attackFiltersProvider.notifier,
  );

  return attacks.whenData(controller.filter);
});

/// What the sheet's free-text sections offer, taken from every READABLE attack — NOT from the filtered list, or picking one value would hide the rest, and not from behind the window either, or a chip would name a value with nothing under it.
final attackFilterOptionsProvider = Provider<AttackFilterOptions>((Ref ref) {
  const AttackFilterer filterer = AttackFilterer();
  final List<Attack> attacks =
      ref.watch(visibleAttacksProvider).value ?? const <Attack>[];

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
