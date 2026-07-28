import 'dart:math';

import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/head_location_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/services/chart_analytics.dart';

/// Horizontal bar chart of attacks per head location, most-frequent first.
/// Hand-rolled bars rather than fl_chart: a handful of labelled category rows
/// reads cleaner (and lighter) as proportional tracks than a rotated bar chart.
class LocationBreakdownChart extends StatelessWidget {
  const LocationBreakdownChart({required this.counts, super.key});

  final List<LocationCount> counts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maxCount = counts.fold(0, (m, c) => max(m, c.count));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.historyChartLocationTitle, style: AppTextStyle.titleMedium),
        SizedBox(height: AppSpacingConstant.h12),
        Semantics(
          label: l10n.a11yChart(l10n.historyChartLocationTitle),
          child: ExcludeSemantics(
            child: Column(
              children: [
                for (final entry in counts)
                  Padding(
                    padding: EdgeInsets.only(bottom: AppSpacingConstant.h8),
                    child: _LocationRow(
                      label: entry.location.label(l10n),
                      count: entry.count,
                      fraction: maxCount == 0 ? 0 : entry.count / maxCount,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.label,
    required this.count,
    required this.fraction,
  });

  final String label;
  final int count;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: AppSpacingConstant.w56 + AppSpacingConstant.w28,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.bodySmall,
          ),
        ),
        SizedBox(width: AppSpacingConstant.w8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacingConstant.r4),
            child: Stack(
              children: [
                Container(
                  height: AppSpacingConstant.h16,
                  color: AppColors.chartGrid,
                ),
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: Container(
                    height: AppSpacingConstant.h16,
                    decoration: BoxDecoration(
                      color: AppColors.chartSeries,
                      borderRadius: BorderRadius.circular(
                        AppSpacingConstant.r4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: AppSpacingConstant.w8),
        SizedBox(
          width: AppSpacingConstant.w28,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: AppTextStyle.bodySmall.secondary,
          ),
        ),
      ],
    );
  }
}
