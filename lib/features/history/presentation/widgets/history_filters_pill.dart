import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/enums/attack_filters.dart';
import '../../providers.dart';
import 'history_filters_sheet.dart';

/// The one filter control on History: a pill saying how many axes are on, and the sheet behind it holding all of them.
///
/// **It counts axes, not results.** How many attacks matched is what the list
/// itself shows; what a pill has to say is that something is being hidden at
/// all — a user who left "no aura" on last week reads an empty list as an
/// empty history otherwise.
class HistoryFiltersPill extends ConsumerWidget {
  const HistoryFiltersPill({super.key});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    AttackFilters current,
  ) async {
    final AttackFilters? picked = await HistoryFiltersSheet(
      initial: current,
    ).show(context);

    if (picked == null) return;
    ref.read(attackFiltersProvider.notifier).apply(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AttackFilters filters = ref.watch(attackFiltersProvider);
    final int active = filters.activeCount;

    return SdFilterPillV2(
      label: active == 0
          ? context.l10n.historyFiltersTitle
          : context.l10n.historyFilterWithCount(
              context.l10n.historyFiltersTitle,
              active,
            ),
      onTap: () => _open(context, ref, filters),
    );
  }
}
