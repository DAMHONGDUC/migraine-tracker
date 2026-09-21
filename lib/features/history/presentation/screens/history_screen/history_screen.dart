import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/attack_filter_labels.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/extensions/symptom_tag_label.dart';
import '../../../../../core/theme/app_icon_constant.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/active_filter_summary.dart';
import '../../../../../core/widgets/charts/severity_breakdown_chart.dart';
import '../../../../../core/widgets/free_history_banner.dart';
import '../../../../../core/widgets/premium_gate.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../attacks/domain/entities/attack.dart';
import '../../../../attacks/domain/services/attack_window.dart';
import '../../../../attacks/providers.dart';
import '../../../../premium/providers.dart';
import '../../../../sync/providers.dart';
import '../../../domain/entities/attack_filter_options.dart';
import '../../../domain/enums/attack_filters.dart';
import '../../../domain/enums/history_period.dart';
import '../../../domain/enums/history_view_mode.dart';
import '../../../domain/services/chart_analytics.dart';
import '../../../domain/services/sample_chart_data.dart';
import '../../../domain/services/weekly_buckets.dart';
import '../../../providers.dart';
import '../../controllers/attack_filters_controller.dart';
import '../../widgets/attack_tile.dart';
import '../../widgets/history_calendar_view.dart';
import '../../widgets/history_view_toggle.dart';
import '../../widgets/intensity_trend_chart.dart';
import '../../widgets/location_breakdown_chart.dart';
import '../../widgets/time_of_day_chart.dart';
import '../../widgets/weekly_frequency_chart.dart';

part 'history_screen_filter_row.dart';
part 'history_screen_chart_view.dart';
part 'history_screen_charts.dart';
part 'history_screen_attack_list.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    // Three lists, and which one a view gets is the whole premium rule here:
    // - [allAttacks] is the WHOLE record, because the list and the calendar
    //   draw every row and `AttackTile` blurs the ones behind the window;
    // - [rows] is that record under the filters, for the list;
    // - [filtered] is the readable ninety days under the same filters, for the
    //   charts — a chart averaging numbers the user cannot see is a number
    //   they cannot check.
    final AsyncValue<List<Attack>> allAttacks = ref.watch(attacksStreamProvider);
    final AsyncValue<List<Attack>> rows = ref.watch(historyRowsProvider);
    final AsyncValue<List<Attack>> filtered = ref.watch(
      filteredAttacksProvider,
    );
    final HistoryViewMode mode = ref.watch(historyViewModeProvider);
    final syncStatus = ref.watch(syncControllerProvider);
    final bool isFirstSync = syncStatus.isSyncing && syncStatus.isFirstPull;
    // Nothing recorded yet is nothing to filter: no strip at all, and the content keeps the screen's own top gap instead of clearing one.
    final bool hasAttacks = (allAttacks.value ?? const <Attack>[]).isNotEmpty;
    // The calendar ignores the filters, so it does not carry them either: a strip that changes nothing on the screen it sits over is worse than none.
    final bool showFilter = hasAttacks && mode != HistoryViewMode.calendar;
    // Fixed regardless of the strip's collapse state, so the list never jumps mid-scroll (see SdCollapsingFilterScaffoldV2).
    final double topInset = showFilter
        ? SdContentPaddingV2.belowPinnedFilterBar(context)
        : SdContentPaddingV2.top(context);

    return SdCollapsingFilterScaffoldV2(
      title: Text(l10n.historyTitle, style: AppTextStyle.titleLarge),
      actions: <Widget>[
        HistoryViewToggle(
          mode: mode,
          onChanged: ref.read(historyViewModeProvider.notifier).select,
        ),
        SizedBox(width: SdSpacingConstant.w12),
      ],
      // - One chip per axis, like the medications tab (owner's call). - Pinned under the app bar and never lifted into it (owner's call): the strip is where the filters are, and a bar that takes them over moves them mid-scroll.
      filter: showFilter ? const _FilterRow() : null,
      collapsible: false,
      // No outer top padding: each view pads INSIDE its own scrollable, so content scrolls behind the app bar.
      body: SdRefreshIndicatorV2(
        // Drop the spinner below the filter strip, not over its chips.
        edgeOffset: showFilter ? topInset + SdSpacingConstant.h8 : 0,
        onRefresh: () => SdRefreshIndicatorV2.run(
          () => ref.invalidate(attacksStreamProvider),
        ),
        child: switch (allAttacks) {
          // Signed in on a new device: the list is empty because the history is still arriving, not because there is none.
          AsyncData(value: final List<Attack> all)
              when all.isEmpty && isFirstSync =>
            SdScrollFillV2(
              topInset: SdContentPaddingV2.appBarInset(context),
              child: SdEmptyStateV2(
                icon: AppIconConstant.cloudDownload,
                message: l10n.historyFirstSyncLoading,
              ),
            ),
          AsyncData(value: final List<Attack> all) when all.isEmpty =>
            SdScrollFillV2(
              topInset: SdContentPaddingV2.appBarInset(context),
              child: SdEmptyStateV2(
                icon: AppIconConstant.attackList,
                message: l10n.historyEmpty,
              ),
            ),
          AsyncData(value: final List<Attack> all) => Builder(
            builder: (BuildContext context) {
              final List<Attack> list = switch (rows) {
                AsyncData(value: final List<Attack> value) => value,
                _ => const <Attack>[],
              };
              // The charts stay on the readable window.
              final List<Attack> readable = switch (filtered) {
                AsyncData(value: final List<Attack> value) => value,
                _ => const <Attack>[],
              };
              // One shared inset keeps all history views above the floating navigation.
              final double bottomInset = SdContentPaddingV2.bottom(
                context,
                floatingNav: true,
              );

              // IndexedStack keeps ALL views alive so switching modes preserves state (scroll position, selected day, layout).
              return IndexedStack(
                index: HistoryViewMode.values.indexOf(mode),
                children: <Widget>[
                  _AttackList(
                    attacks: list,
                    topInset: topInset,
                    bottomInset: bottomInset,
                  ),
                  // Calendar ignores the filters by design.
                  HistoryCalendarView(
                    attacks: all,
                    topInset: topInset,
                    bottomInset: bottomInset,
                  ),
                  _ChartView(
                    attacks: readable,
                    topInset: topInset,
                    bottomInset: bottomInset,
                  ),
                ],
              );
            },
          ),
          AsyncError() => SdScrollFillV2(
            topInset: SdContentPaddingV2.appBarInset(context),
            child: SdEmptyStateV2(
              icon: AppIconConstant.attackList,
              message: l10n.historyEmpty,
            ),
          ),
          // The list's own shape.
          _ => Padding(
            padding: EdgeInsets.fromLTRB(
              SdContentPaddingV2.horizontal,
              SdContentPaddingV2.top(context),
              SdContentPaddingV2.horizontal,
              0,
            ),
            child: const SdListSkeletonV2(),
          ),
        },
      ),
    );
  }
}
