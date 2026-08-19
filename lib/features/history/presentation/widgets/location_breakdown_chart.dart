import 'dart:math';

import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/head_region_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/services/chart_analytics.dart';

/// Horizontal bar chart of attacks per head area, most-frequent first. The
/// bars sum to more than the number of attacks, because an attack counts in
/// every area it names — see [LocationBreakdownCalculator].
/// Proportional tracks rather than a rotated fl_chart bar chart: a handful of
/// labelled category rows reads cleaner, and lighter, that way.
class LocationBreakdownChart extends StatelessWidget {
  const LocationBreakdownChart({required this.counts, super.key});

  final List<LocationCount> counts;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final int maxCount = counts.fold(
      0,
      (int m, LocationCount c) => max(m, c.count),
    );

    return SdChartFrameV2(
      title: l10n.historyChartLocationTitle,
      semanticsLabel: l10n.a11yChart(l10n.historyChartLocationTitle),
      child: Column(
        children: <Widget>[
          for (final LocationCount entry in counts)
            Padding(
              padding: EdgeInsets.only(bottom: SdSpacingConstant.h8),
              child: SdProgressRowV2(
                label: entry.region.label(l10n),
                value: '${entry.count}',
                fraction: maxCount == 0 ? 0 : entry.count / maxCount,
                color: AppColors.chartSeries,
              ),
            ),
        ],
      ),
    );
  }
}
