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
import '../../../../core/widgets/dashboard_chevron.dart';
import '../../domain/entities/week_summary.dart';
import '../../providers.dart';

/// "This week" glance card: attack count, trend vs last week, and average intensity.
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
                // Demoted to a caption so the count below it is unmistakably the thing being read.
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
            // Two weeks with nothing in them have no trend to state, and a bare "0" on its own reads as a card that failed to load.
            if (hasData)
              _TrendRow(summary: summary)
            else
              SdEmptyStateV2(
                icon: AppIconConstant.history,
                message: l10n.dashboardWeekEmpty,
                size: SdEmptyStateSizeV2.compact,
              ),
            if (summary.averageIntensity != null) ...[
              SizedBox(height: SdSpacingConstant.h8),
              _AvgIntensityRow(value: summary.averageIntensity!),
            ],
          ],
        ),
      ),
    );
  }
}

/// The number at display size with its unit under it, so half a screen of width never squeezes the number.
class _CountRow extends StatelessWidget {
  const _CountRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$count', style: AppTextStyle.displaySmall.w600),
        // Under the number rather than beside it: the card is half the screen wide, and a unit beside the number would wrap in most locales.
        Text(
          context.l10n.dashboardAttacksLabel(count),
          style: AppTextStyle.bodyMedium.secondary,
        ),
      ],
    );
  }
}

/// The week-over-week trend, with an arrow so the direction never rests on colour alone.
class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.summary});

  final WeekSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final int trend = summary.trend;
    // - Teal marks the good direction; up and flat stay muted.
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
        SdIconV2(icon: icon, size: AppIconSize.xSmall, color: color),
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

/// The week's average intensity, as a line shaped like [_TrendRow] above it: the band's dot, then the words.
///
/// It was a tinted pill. In a half-width card the label wraps, and a pill
/// rounded for one line reads as broken on two; a line wraps the way the
/// trend line beside it already does. The dot keeps the band's colour, and the
/// number says the same thing in words (hard rule 3).
class _AvgIntensityRow extends StatelessWidget {
  const _AvgIntensityRow({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // In a box the trend glyph's width, so both lines' words start at one edge.
        SizedBox(
          width: AppIconSize.xSmall,
          child: Center(
            child: SdColorDotV2(color: AppColors.intensity(value.round())),
          ),
        ),
        SizedBox(width: SdSpacingConstant.w6),
        Flexible(
          child: Text(
            context.l10n.dashboardAvgIntensity(value.toStringAsFixed(1)),
            style: AppTextStyle.bodySmall,
          ),
        ),
      ],
    );
  }
}
