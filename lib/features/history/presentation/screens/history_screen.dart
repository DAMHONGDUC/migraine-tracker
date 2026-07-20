import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/glass/liquid_glass_theme.dart';
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

    return AppScaffold(
      title: Text(l10n.historyTitle),
      actions: [
        HistoryViewToggle(
          mode: mode,
          onChanged: ref.read(historyViewModeProvider.notifier).select,
        ),
        SizedBox(width: AppSpacingConstant.w12),
      ],
      // No outer top padding: each view pads INSIDE its own scrollable, so
      // the content scrolls behind the translucent app bar and blurs out.
      body: switch (allAttacks) {
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
            // Insets computed HERE — a context inside the Scaffold body,
            // where extendBodyBehindAppBar/extendBody make MediaQuery
            // report the real bar heights — and passed down, so the inner
            // views don't depend on where they read MediaQuery from.
            final topInset = kLiquidGlassEnabled
                ? MediaQuery.paddingOf(context).top + AppSpacingConstant.h16
                : 0.0;
            final bottomInset = kLiquidGlassEnabled
                ? MediaQuery.paddingOf(context).bottom + AppSpacingConstant.h8
                : 0.0;
            // IndexedStack keeps ALL views alive so switching modes
            // preserves state (scroll position, selected day, layout).
            return IndexedStack(
              index: HistoryViewMode.values.indexOf(mode),
              children: [
                _AttackList(
                  attacks: list,
                  topInset: topInset,
                  bottomInset: bottomInset,
                ),
                // Calendar ignores the period filter by design.
                HistoryCalendarView(
                  attacks: all,
                  topInset: topInset,
                  bottomInset: bottomInset,
                ),
                _ChartView(
                  attacks: list,
                  topInset: topInset,
                  bottomInset: bottomInset,
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
    );
  }
}

/// The period filter pill row, first thing in each scrollable — below the
/// app bar (not in it), trailing-aligned, and it stays visible when the
/// filter matches nothing so the user can always switch back.
class _FilterRow extends ConsumerWidget {
  const _FilterRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacingConstant.h12),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: HistoryFilterChip(
          selected: ref.watch(historyPeriodProvider),
          count: count,
          onSelected: ref.read(historyPeriodProvider.notifier).select,
        ),
      ),
    );
  }
}

/// Chart mode — same filtered data as the list.
class _ChartView extends StatelessWidget {
  const _ChartView({
    required this.attacks,
    required this.topInset,
    required this.bottomInset,
  });

  final List<Attack> attacks;
  final double topInset;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Flush under the app bar — no gap between the bar and the content.
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacingConstant.w16,
            topInset,
            AppSpacingConstant.w16,
            0,
          ),
          sliver: SliverToBoxAdapter(child: _FilterRow(count: attacks.length)),
        ),
        if (attacks.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.filter_alt_outlined,
              message: context.l10n.historyEmptyFiltered,
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacingConstant.w16,
              0,
              AppSpacingConstant.w16,
              bottomInset + AppSpacingConstant.h16,
            ),
            sliver: SliverToBoxAdapter(
              child: WeeklyFrequencyChart(
                buckets: weeklyBuckets(attacks, now: DateTime.now()),
              ),
            ),
          ),
      ],
    );
  }
}

class _AttackList extends StatelessWidget {
  const _AttackList({
    required this.attacks,
    required this.topInset,
    required this.bottomInset,
  });

  final List<Attack> attacks;
  final double topInset;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Flush under the app bar — no gap between the bar and the content.
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacingConstant.w16,
            topInset,
            AppSpacingConstant.w16,
            0,
          ),
          sliver: SliverToBoxAdapter(child: _FilterRow(count: attacks.length)),
        ),
        if (attacks.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.filter_alt_outlined,
              message: context.l10n.historyEmptyFiltered,
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacingConstant.w16,
              0,
              AppSpacingConstant.w16,
              bottomInset + AppSpacingConstant.h16,
            ),
            sliver: SliverList.separated(
              itemCount: attacks.length,
              separatorBuilder: (_, _) =>
                  SizedBox(height: AppSpacingConstant.h8),
              itemBuilder: (context, index) =>
                  AttackTile(attack: attacks[index]),
            ),
          ),
      ],
    );
  }
}
