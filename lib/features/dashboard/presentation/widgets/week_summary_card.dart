import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/features/history/domain/enums/history_view_mode.dart';
import 'package:migraine_tracker/features/history/providers.dart';
import 'package:system_design/v2/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
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
          padding: EdgeInsets.all(SdSpacingV2.w20),
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
                  SdIconV2(
                    icon: Icons.chevron_right,
                    size: SdSpacingV2.r20,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              SizedBox(height: SdSpacingV2.h12),
              Text(
                l10n.dashboardAttacksCount(summary.thisWeekCount),
                style: AppTextStyle.headlineSmall.w600,
              ),
              if (hasData) ...[
                SizedBox(height: SdSpacingV2.h4),
                Text(
                  _trendText(l10n, summary),
                  style: AppTextStyle.bodySmall.secondary,
                ),
              ],
              if (summary.averageIntensity != null) ...[
                SizedBox(height: SdSpacingV2.h16),
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
        horizontal: SdSpacingV2.w12,
        vertical: SdSpacingV2.h6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(SdSpacingV2.r999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SdColorDotV2(color: color),
          SizedBox(width: SdSpacingV2.w8),
          Text(
            context.l10n.dashboardAvgIntensity(value.toStringAsFixed(1)),
            style: AppTextStyle.labelLarge,
          ),
        ],
      ),
    );
  }
}
