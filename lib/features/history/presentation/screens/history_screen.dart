import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/charts/chart_card.dart';
import '../../../../core/widgets/charts/severity_breakdown_chart.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/glass/liquid_glass_theme.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/providers.dart';
import '../../domain/enums/history_view_mode.dart';
import '../../domain/services/chart_analytics.dart';
import '../../domain/services/weekly_buckets.dart';
import '../../providers.dart';
import '../widgets/attack_tile.dart';
import '../widgets/history_calendar_view.dart';
import '../widgets/history_filter_sheet.dart';
import '../widgets/history_view_toggle.dart';
import '../widgets/intensity_trend_chart.dart';
import '../widgets/location_breakdown_chart.dart';
import '../widgets/time_of_day_chart.dart';
import '../widgets/weekly_frequency_chart.dart';

class HistoryScreen extends HookConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final allAttacks = ref.watch(attacksStreamProvider);
    final filtered = ref.watch(filteredAttacksProvider);
    final mode = ref.watch(historyViewModeProvider);

    // Whether each scrollable has scrolled past its in-list filter pill —
    // tracked per view because IndexedStack keeps both alive with their own
    // scroll offsets.
    final listPastFilter = useState(false);
    final chartPastFilter = useState(false);
    final pastFilter = switch (mode) {
      HistoryViewMode.list => listPastFilter.value,
      HistoryViewMode.chart => chartPastFilter.value,
      HistoryViewMode.calendar => false,
    };

    return AppScaffold(
      // At rest the pill lives in the scroll content; once it scrolls away
      // it takes over the title slot and the "History" heading hides.
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: pastFilter
            ? Align(
                alignment: AlignmentDirectional.centerStart,
                child: HistoryFilterChip(
                  selected: ref.watch(historyPeriodProvider),
                  count: filtered.value?.length,
                  onSelected: ref.read(historyPeriodProvider.notifier).select,
                ),
              )
            : Text(l10n.historyTitle),
      ),
      actions: [
        HistoryViewToggle(
          mode: mode,
          onChanged: ref.read(historyViewModeProvider.notifier).select,
        ),
        SizedBox(width: AppSpacingConstant.w12),
      ],
      // No outer top padding: each view pads INSIDE its own scrollable, so
      // the content scrolls behind the translucent app bar and blurs out.
      body: AppRefreshIndicator(
        onRefresh: () =>
            pullRefresh(() => ref.invalidate(attacksStreamProvider)),
        child: switch (allAttacks) {
        AsyncData(value: final all) when all.isEmpty => ScrollFill(
          topInset: AppScaffold.bodyTopInset(context),
          child: EmptyState(
            icon: Icons.event_note_outlined,
            message: l10n.historyEmpty,
          ),
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
                  onPastFilterChanged: (past) => listPastFilter.value = past,
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
                  onPastFilterChanged: (past) => chartPastFilter.value = past,
                ),
              ],
            );
          },
        ),
        AsyncError() => ScrollFill(
          topInset: AppScaffold.bodyTopInset(context),
          child: EmptyState(
            icon: Icons.event_note_outlined,
            message: l10n.historyEmpty,
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

/// The period filter pill row, first thing in each scrollable — below the
/// app bar (not in it), leading-aligned, and it stays visible when the
/// filter matches nothing so the user can always switch back. Once it
/// scrolls away, [HistoryScreen] shows the same pill in the app bar.
class _FilterRow extends ConsumerWidget {
  const _FilterRow({required this.count});

  final int count;

  /// Scroll offset past which the pill row is gone behind the app bar —
  /// the pill height plus its bottom padding.
  static double get scrolledPastExtent =>
      AppSpacingConstant.h34 + AppSpacingConstant.h12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacingConstant.h12),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
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
    required this.onPastFilterChanged,
  });

  final List<Attack> attacks;
  final double topInset;
  final double bottomInset;

  /// Reports whether the filter pill has scrolled out behind the app bar.
  final ValueChanged<bool> onPastFilterChanged;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        onPastFilterChanged(
          notification.metrics.pixels > _FilterRow.scrolledPastExtent,
        );
        return false;
      },
      child: CustomScrollView(
        slivers: [
          // Flush under the app bar — no gap between the bar and the content.
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacingConstant.w16,
              topInset,
              AppSpacingConstant.w16,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _FilterRow(count: attacks.length),
            ),
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
              sliver: SliverToBoxAdapter(child: _Charts(attacks: attacks)),
            ),
        ],
      ),
    );
  }
}

/// The stacked chart deck shown once the filtered period has attacks: weekly
/// frequency, average-intensity trend, severity mix, pain-by-location and
/// time-of-day — each in its own [ChartCard]. All read the same filtered
/// [attacks] and are computed once here (pure calculators).
class _Charts extends StatelessWidget {
  const _Charts({required this.attacks});

  final List<Attack> attacks;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cards = <Widget>[
      WeeklyFrequencyChart(
        buckets: const WeeklyBucketsCalculator().compute(attacks, now: now),
      ),
      IntensityTrendChart(
        points: const IntensityTrendCalculator().compute(attacks, now: now),
      ),
      SeverityBreakdownChart(
        counts: const SeverityBreakdownCalculator().compute(attacks),
      ),
      LocationBreakdownChart(
        counts: const LocationBreakdownCalculator().compute(attacks),
      ),
      TimeOfDayChart(
        counts: const TimeOfDayCalculator().compute(attacks),
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) SizedBox(height: AppSpacingConstant.h16),
          ChartCard(child: cards[i]),
        ],
      ],
    );
  }
}

class _AttackList extends StatelessWidget {
  const _AttackList({
    required this.attacks,
    required this.topInset,
    required this.bottomInset,
    required this.onPastFilterChanged,
  });

  final List<Attack> attacks;
  final double topInset;
  final double bottomInset;

  /// Reports whether the filter pill has scrolled out behind the app bar.
  final ValueChanged<bool> onPastFilterChanged;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        onPastFilterChanged(
          notification.metrics.pixels > _FilterRow.scrolledPastExtent,
        );
        return false;
      },
      child: CustomScrollView(
        slivers: [
          // Flush under the app bar — no gap between the bar and the content.
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacingConstant.w16,
              topInset,
              AppSpacingConstant.w16,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _FilterRow(count: attacks.length),
            ),
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
      ),
    );
  }
}
