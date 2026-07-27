import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/charts/chart_card.dart';
import '../../../../../core/widgets/charts/severity_breakdown_chart.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/glass/liquid_glass_theme.dart';
import '../../../../attacks/domain/entities/attack.dart';
import '../../../../attacks/providers.dart';
import '../../../domain/enums/history_view_mode.dart';
import '../../../domain/services/chart_analytics.dart';
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
      // Content scrolls behind the glass nav; bottomNavInset already covers
      // the device inset.
      withSafeArea: false,
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
            : Text(l10n.historyTitle, style: AppTextStyle.titleLarge),
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
        onRefresh: () => AppRefreshIndicator.run(
          () => ref.invalidate(attacksStreamProvider),
        ),
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
              final topInset = AppGlass.isSupported
                  ? MediaQuery.paddingOf(context).top + AppSpacingConstant.h16
                  : 0.0;
              // Unconditional: the shell's nav floats on every device, so
              // these views always scroll behind it.
              final bottomInset =
                  MediaQuery.paddingOf(context).bottom + AppSpacingConstant.h8;
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
