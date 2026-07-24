import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../features/history/domain/services/chart_analytics.dart';
import '../../constants/app_spacing_constant.dart';
import '../../extensions/chart_labels.dart';
import '../../extensions/context_extensions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';

/// Donut chart splitting attacks across the four severity bands, coloured with
/// the same green → yellow → orange → red scale as `AppColors.intensity`. A
/// wrap-legend names each band and its count (a donut's slices are unlabelled).
///
/// Shared by the History → Chart deck and the dashboard's severity card; the
/// counts come from the pure [SeverityBreakdownCalculator].
class SeverityBreakdownChart extends StatelessWidget {
  const SeverityBreakdownChart({required this.counts, super.key});

  final List<SeverityCount> counts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final present = counts.where((c) => c.count > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.historyChartSeverityTitle, style: AppTextStyle.titleMedium),
        SizedBox(height: AppSpacingConstant.h12),
        Semantics(
          label: l10n.a11yChart(l10n.historyChartSeverityTitle),
          child: ExcludeSemantics(
            child: SizedBox(
              height: AppSpacingConstant.h160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: AppSpacingConstant.w2,
                  centerSpaceRadius: AppSpacingConstant.r44,
                  sections: [
                    for (final entry in present)
                      PieChartSectionData(
                        value: entry.count.toDouble(),
                        color: AppColors.intensity(entry.band.sampleIntensity),
                        radius: AppSpacingConstant.r28,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacingConstant.h12),
        Wrap(
          spacing: AppSpacingConstant.w16,
          runSpacing: AppSpacingConstant.h8,
          children: [
            for (final entry in present)
              _LegendItem(
                color: AppColors.intensity(entry.band.sampleIntensity),
                label: entry.band.label(l10n),
                count: entry.count,
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppSpacingConstant.r12,
          height: AppSpacingConstant.r12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppSpacingConstant.r3),
          ),
        ),
        SizedBox(width: AppSpacingConstant.w6),
        Text('$label · $count', style: AppTextStyle.bodySmall.secondary),
      ],
    );
  }
}
