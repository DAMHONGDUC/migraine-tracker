import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../insights/domain/entities/migraine_days_summary.dart';
import '../../../insights/providers.dart';

/// Migraine days this month — the figure a headache clinic opens with, and the one every preventive is judged on.
class MonthDaysCard extends ConsumerWidget {
  const MonthDaysCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MigraineDaysSummary summary = ref.watch(migraineDaysProvider);
    final MonthlyMigraineDays? current = summary.currentMonth;

    if (current == null) return const SizedBox.shrink();

    final int? change = summary.changeFromPreviousMonth;

    return SdCardV2(
      surface: SdCardSurfaceV2.elevated,
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.dashboardThisMonth,
              style: AppTextStyle.labelSmall.secondary,
            ),
            SizedBox(height: SdSpacingConstant.h8),
            _DaysRow(days: current.days),
            // Nothing to compare against on a first month, and a trend line that has to invent a baseline is worse than no line.
            if (change != null) ...<Widget>[
              SizedBox(height: SdSpacingConstant.h8),
              _MonthTrendRow(change: change),
            ],
          ],
        ),
      ),
    );
  }
}

/// The number at display size with its unit beside it, on a shared baseline — the same shape [WeekSummaryCard] uses, so the two read as one family.
class _DaysRow extends StatelessWidget {
  const _DaysRow({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Text('$days', style: AppTextStyle.displaySmall.w600),
        SizedBox(width: SdSpacingConstant.w8),
        // Flexible, not Expanded: the unit runs longer in several locales and must wrap without the number losing its baseline.
        Flexible(
          child: Text(
            context.l10n.dashboardMigraineDaysLabel(days),
            style: AppTextStyle.bodyMedium.secondary,
          ),
        ),
      ],
    );
  }
}

/// The month-on-month change, with the caveat that makes it honest.
class _MonthTrendRow extends StatelessWidget {
  const _MonthTrendRow({required this.change});

  final int change;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // - Teal marks the good direction; up and flat stay muted.
    final Color color = change < 0
        ? AppColors.secondary
        : AppColors.textSecondary;
    final IconData icon = switch (change) {
      < 0 => AppIconConstant.trendDown,
      > 0 => AppIconConstant.trendUp,
      _ => AppIconConstant.trendFlat,
    };
    final String label = switch (change) {
      < 0 => l10n.dashboardMonthTrendDown(-change),
      > 0 => l10n.dashboardMonthTrendUp(change),
      _ => l10n.dashboardMonthTrendSame,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            SdIconV2(icon: icon, size: AppIconSize.xSmall, color: color),
            SizedBox(width: SdSpacingConstant.w6),
            Flexible(
              child: Text(
                label,
                style: AppTextStyle.bodySmall.copyWith(color: color),
              ),
            ),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h4),
        Text(
          l10n.dashboardMonthPartial,
          style: AppTextStyle.labelSmall.secondary,
        ),
      ],
    );
  }
}
