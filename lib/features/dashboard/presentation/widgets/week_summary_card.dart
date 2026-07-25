import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';
import 'package:migraine_tracker/features/history/domain/enums/history_view_mode.dart';
import 'package:migraine_tracker/features/history/providers.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/week_summary.dart';
import '../../providers.dart';

/// "This week" glance card: attack count, trend vs last week, and average
/// intensity. Tapping it jumps to the History tab for the full picture.
class WeekSummaryCard extends ConsumerWidget {
  const WeekSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(weekSummaryProvider);
    final hasData = summary.thisWeekCount > 0 || summary.lastWeekCount > 0;

    void openHistory(HistoryViewMode mode) {
      ref.read(historyViewModeProvider.notifier).select(mode);
      context.goNamed(AppRoutes.history.name);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openHistory(HistoryViewMode.calendar),
        child: Padding(
          padding: EdgeInsets.all(AppSpacingConstant.w20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.dashboardThisWeek,
                      style: AppTextStyle.titleMedium,
                    ),
                  ),
                  AppIcon(
                    Icons.chevron_right,
                    size: AppSpacingConstant.r20,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              SizedBox(height: AppSpacingConstant.h12),
              Text(
                l10n.dashboardAttacksCount(summary.thisWeekCount),
                style: AppTextStyle.headlineSmall.w600,
              ),
              if (hasData) ...[
                SizedBox(height: AppSpacingConstant.h4),
                Text(
                  _trendText(l10n, summary),
                  style: AppTextStyle.bodySmall.secondary,
                ),
              ],
              if (summary.averageIntensity != null) ...[
                SizedBox(height: AppSpacingConstant.h16),
                _AvgIntensityChip(value: summary.averageIntensity!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _trendText(AppLocalizations l10n, WeekSummary summary) {
    final trend = summary.trend;
    if (trend > 0) return l10n.dashboardTrendUp(trend);
    if (trend < 0) return l10n.dashboardTrendDown(-trend);
    return l10n.dashboardTrendSame;
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
        horizontal: AppSpacingConstant.w12,
        vertical: AppSpacingConstant.h6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppSpacingConstant.r999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSpacingConstant.r12,
            height: AppSpacingConstant.r12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: AppSpacingConstant.w8),
          Text(
            context.l10n.dashboardAvgIntensity(value.toStringAsFixed(1)),
            style: AppTextStyle.labelLarge,
          ),
        ],
      ),
    );
  }
}
