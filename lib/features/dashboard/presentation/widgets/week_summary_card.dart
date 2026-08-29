import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/features/history/domain/enums/history_view_mode.dart';
import 'package:migraine_tracker/features/history/providers.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/week_summary.dart';
import '../../providers.dart';
import 'dashboard_chevron.dart';

/// "This week" glance card: attack count, trend vs last week, and average
/// intensity. Tapping it jumps to the History tab for the full picture.
///
/// The count is the card, so it is set at [AppTextStyle.displaySmall] with its
/// unit demoted to muted body text beside it — the two used to share one
/// string and one size, which left the number reading as a sentence.
class WeekSummaryCard extends ConsumerWidget {
  const WeekSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final WeekSummary summary = ref.watch(weekSummaryProvider);
    final bool hasData = summary.thisWeekCount > 0 || summary.lastWeekCount > 0;

    void openHistory(HistoryViewMode mode) {
      ref.read(historyViewModeProvider.notifier).select(mode);
      context.goNamed(AppRoutes.history.name);
    }

    return SdCardV2(
      surface: SdCardSurfaceV2.elevated,
      onTap: () => openHistory(HistoryViewMode.calendar),
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Demoted to a caption so the count below it is unmistakably
                // the thing being read.
                Expanded(
                  child: Text(
                    l10n.dashboardThisWeek,
                    style: AppTextStyle.labelSmall.secondary,
                  ),
                ),
                const DashboardChevron(),
              ],
            ),
            SizedBox(height: SdSpacingConstant.h8),
            _CountRow(count: summary.thisWeekCount),
            SizedBox(height: SdSpacingConstant.h8),
            // Two weeks with nothing in them have no trend to state, and a
            // bare "0" on its own reads as a card that failed to load.
            if (hasData)
              _TrendRow(summary: summary)
            else
              Text(
                l10n.dashboardWeekEmpty,
                style: AppTextStyle.bodySmall.secondary,
              ),
            if (summary.averageIntensity != null) ...[
              SizedBox(height: SdSpacingConstant.h16),
              _AvgIntensityChip(value: summary.averageIntensity!),
            ],
          ],
        ),
      ),
    );
  }
}

/// The number at display size with its unit beside it, sitting on a shared
/// baseline so the two read as one phrase rather than two stacked lines.
class _CountRow extends StatelessWidget {
  const _CountRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('$count', style: AppTextStyle.displaySmall.w600),
        SizedBox(width: SdSpacingConstant.w8),
        // Flexible, not Expanded: Vietnamese runs longer and must be free to
        // wrap without the number losing its baseline.
        Flexible(
          child: Text(
            context.l10n.dashboardAttacksLabel(count),
            style: AppTextStyle.bodyMedium.secondary,
          ),
        ),
      ],
    );
  }
}

/// The week-over-week trend, with an arrow so the direction never rests on
/// colour alone.
class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.summary});

  final WeekSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final int trend = summary.trend;
    // - Teal marks the good direction; up and flat stay muted.
    // - Deliberately not the error red: telling someone in the middle of a bad
    //   week that they are in the red is an alarm, not information.
    final Color color = trend < 0
        ? AppColors.secondary
        : AppColors.textSecondary;
    final IconData icon = switch (trend) {
      < 0 => AppIconConstant.trendDown,
      > 0 => AppIconConstant.trendUp,
      _ => AppIconConstant.trendFlat,
    };
    final String label = switch (trend) {
      < 0 => l10n.dashboardTrendDown(-trend),
      > 0 => l10n.dashboardTrendUp(trend),
      _ => l10n.dashboardTrendSame,
    };

    return Row(
      children: [
        SdIconV2(icon: icon, size: AppIconSize.inline, color: color),
        SizedBox(width: SdSpacingConstant.w6),
        Flexible(
          child: Text(
            label,
            style: AppTextStyle.bodySmall.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _AvgIntensityChip extends StatelessWidget {
  const _AvgIntensityChip({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.intensity(value.round());
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SdSpacingConstant.w12,
        vertical: SdSpacingConstant.h6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(SdSpacingConstant.r999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SdColorDotV2(color: color),
          SizedBox(width: SdSpacingConstant.w8),
          Text(
            context.l10n.dashboardAvgIntensity(value.toStringAsFixed(1)),
            style: AppTextStyle.labelLarge,
          ),
        ],
      ),
    );
  }
}
