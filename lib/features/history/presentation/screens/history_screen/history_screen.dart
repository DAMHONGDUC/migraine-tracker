import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/premium_limit_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/charts/severity_breakdown_chart.dart';
import '../../../../../core/widgets/free_limit_progress.dart';
import '../../../../../core/widgets/premium_gate.dart';
import '../../../../attacks/domain/entities/attack.dart';
import '../../../../attacks/providers.dart';
import '../../../../premium/providers.dart';
import '../../../../sync/providers.dart';
import '../../../domain/enums/history_view_mode.dart';
import '../../../domain/services/chart_analytics.dart';
import '../../../domain/services/sample_chart_data.dart';
import '../../../domain/services/weekly_buckets.dart';
import '../../../providers.dart';
import '../../widgets/attack_tile.dart';
import '../../widgets/history_calendar_view.dart';
import '../../widgets/history_filter_sheet.dart';
import '../../widgets/history_view_toggle.dart';
import '../../widgets/intensity_trend_chart.dart';
import '../../widgets/location_breakdown_chart.dart';
import '../../widgets/time_of_day_chart.dart';
import '../../widgets/weekly_frequency_chart.dart';

part 'history_screen_filter_row.dart';
part 'history_screen_chart_view.dart';
part 'history_screen_charts.dart';
part 'history_screen_attack_list.dart';

class HistoryScreen extends HookConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final allAttacks = ref.watch(attacksStreamProvider);
    final filtered = ref.watch(filteredAttacksProvider);
    final mode = ref.watch(historyViewModeProvider);
    final syncStatus = ref.watch(syncControllerProvider);
    final isFirstSync = syncStatus.isSyncing && syncStatus.isFirstPull;

    // Tracked per view: IndexedStack keeps both alive with their own scroll offsets.
    final listPastFilter = useState(false);
    final chartPastFilter = useState(false);
    final pastFilter = switch (mode) {
      HistoryViewMode.list => listPastFilter.value,
      HistoryViewMode.chart => chartPastFilter.value,
      HistoryViewMode.calendar => false,
    };

    return SdScaffoldV2(
      // - at rest, the pill lives in the scroll content
      // - once scrolled, it takes the title slot and the "History" heading hides
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
            : Text(l10n.historyTitle, style: AppTextStyle.titleLarge),
      ),
      actions: [
        HistoryViewToggle(
          mode: mode,
          onChanged: ref.read(historyViewModeProvider.notifier).select,
        ),
        SizedBox(width: SdSpacingConstant.w12),
      ],
      // No outer top padding: each view pads INSIDE its own scrollable, so content scrolls behind the app bar.
      body: SdRefreshIndicatorV2(
        onRefresh: () => SdRefreshIndicatorV2.run(
          () => ref.invalidate(attacksStreamProvider),
        ),
        child: switch (allAttacks) {
          // Signed in on a new device: the list is empty because the history
          // is still arriving, not because there is none. Scoped to the first
          // pull only — no later sync ever gates this screen (hard rule 12).
          AsyncData(value: final all) when all.isEmpty && isFirstSync =>
            SdScrollFillV2(
              topInset: SdContentPaddingV2.appBarInset(context),
              child: SdEmptyStateV2(
                icon: Icons.cloud_download_outlined,
                message: l10n.historyFirstSyncLoading,
              ),
            ),
          AsyncData(value: final all) when all.isEmpty => SdScrollFillV2(
            topInset: SdContentPaddingV2.appBarInset(context),
            child: SdEmptyStateV2(
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
              // - computed once and passed down so the three views can't drift apart
              // - floatingNav is unconditional: the shell's nav pill floats on every device
              final topInset = SdContentPaddingV2.top(context);
              final bottomInset = SdContentPaddingV2.bottom(
                context,
                floatingNav: true,
              );
              // IndexedStack keeps ALL views alive so switching modes preserves state (scroll position, selected day, layout).
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
          AsyncError() => SdScrollFillV2(
            topInset: SdContentPaddingV2.appBarInset(context),
            child: SdEmptyStateV2(
              icon: Icons.event_note_outlined,
              message: l10n.historyEmpty,
            ),
          ),
          // The list's own shape. It clears the app bar and takes the screen
          // gutter itself, because the real list's insets come from the view
          // below it and that view does not exist yet.
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
