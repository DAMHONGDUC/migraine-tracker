import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/providers.dart';
import '../../domain/enums/history_view_mode.dart';
import '../../domain/services/weekly_buckets.dart';
import '../controllers/history_controller.dart';
import '../widgets/attack_tile.dart';
import '../widgets/history_calendar_view.dart';
import '../widgets/history_filter_sheet.dart';
import '../widgets/history_view_toggle.dart';
import '../widgets/weekly_frequency_chart.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final allAttacks = ref.watch(attacksStreamProvider);
    final filtered = ref.watch(filteredAttacksProvider);
    final mode = ref.watch(historyViewModeProvider);
    final period = ref.watch(historyPeriodProvider);

    return AppScaffold(
      title: Text(l10n.historyTitle),
      actions: [
        HistoryViewToggle(
          mode: mode,
          onChanged: ref.read(historyViewModeProvider.notifier).select,
        ),
        SizedBox(width: AppSpacingConstant.w12),
      ],
      body: Padding(
        padding: EdgeInsets.only(top: AppScaffold.bodyTopInset(context)),
        child: switch (allAttacks) {
        AsyncData(value: final all) when all.isEmpty => EmptyState(
          icon: Icons.event_note_outlined,
          message: l10n.historyEmpty,
        ),
        AsyncData(value: final all) => Builder(
          builder: (context) {
            final list = switch (filtered) {
              AsyncData(value: final value) => value,
              _ => const <Attack>[],
            };
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shared filter, right below the app bar: closed = current
                // value at a glance, tap = bottom sheet picker. Hidden in
                // calendar mode — that view navigates by month itself.
                if (mode != HistoryViewMode.calendar)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacingConstant.w16,
                      AppSpacingConstant.h8,
                      AppSpacingConstant.w16,
                      AppSpacingConstant.h12,
                    ),
                    child: HistoryFilterChip(
                      selected: period,
                      onSelected:
                          ref.read(historyPeriodProvider.notifier).select,
                    ),
                  ),
                Expanded(
                  // IndexedStack keeps ALL views alive so switching modes
                  // preserves state (scroll position, selected day, layout).
                  child: IndexedStack(
                    index: HistoryViewMode.values.indexOf(mode),
                    children: [
                      _AttackList(attacks: list),
                      // Calendar ignores the period filter by design.
                      HistoryCalendarView(attacks: all),
                      _ChartView(attacks: list),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        AsyncError() => EmptyState(
          icon: Icons.event_note_outlined,
          message: l10n.historyEmpty,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      ),
    );
  }
}

/// Chart mode — same filtered data as the list.
class _ChartView extends StatelessWidget {
  const _ChartView({required this.attacks});

  final List<Attack> attacks;

  @override
  Widget build(BuildContext context) {
    if (attacks.isEmpty) {
      return EmptyState(
        icon: Icons.filter_alt_outlined,
        message: context.l10n.historyEmptyFiltered,
      );
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacingConstant.w16,
        AppSpacingConstant.w16,
        AppSpacingConstant.w16,
        AppScaffold.bottomNavInset(context) + AppSpacingConstant.h16,
      ),
      children: [
        WeeklyFrequencyChart(
          buckets: weeklyBuckets(attacks, now: DateTime.now()),
        ),
        SizedBox(height: AppSpacingConstant.h12),
        Text(
          context.l10n.historyAttackCount(attacks.length),
          style: context.textTheme.titleSmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AttackList extends StatelessWidget {
  const _AttackList({required this.attacks});

  final List<Attack> attacks;

  @override
  Widget build(BuildContext context) {
    if (attacks.isEmpty) {
      return EmptyState(
        icon: Icons.filter_alt_outlined,
        message: context.l10n.historyEmptyFiltered,
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppSpacingConstant.w16,
        AppSpacingConstant.w16,
        AppSpacingConstant.w16,
        AppScaffold.bottomNavInset(context) + AppSpacingConstant.h16,
      ),
      itemCount: attacks.length + 1,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacingConstant.h8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacingConstant.h4),
            child: Text(
              context.l10n.historyAttackCount(attacks.length),
              style: context.textTheme.titleSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return AttackTile(attack: attacks[index - 1]);
      },
    );
  }
}
