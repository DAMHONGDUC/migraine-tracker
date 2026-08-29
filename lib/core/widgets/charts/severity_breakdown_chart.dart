import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../features/history/domain/services/chart_analytics.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../extensions/chart_labels.dart';
import '../../extensions/context_extensions.dart';
import '../../theme/app_colors.dart';

/// Attacks split across the four severity bands, coloured with the same green → yellow → orange → red scale as `AppColors.intensity`.
final class SeverityBreakdownSlices {
  /// How far the placeholder's colours are dialled back. Enough to still name each band, far enough from full strength that it cannot be taken for a reading.
  static const double _placeholderAlpha = 0.4;

  static List<SdDonutSliceV2> of(
    List<SeverityCount> counts,
    AppLocalizations l10n,
  ) => <SdDonutSliceV2>[
    for (final SeverityCount entry in counts)
      SdDonutSliceV2(
        value: entry.count.toDouble(),
        color: AppColors.intensity(entry.band.sampleIntensity),
        label: '${entry.band.label(l10n)} · ${entry.count}',
      ),
  ];

  /// The scale itself, for a surface with nothing to split yet: four equal arcs in the real band colours, dialled back, named but uncounted.
  static List<SdDonutSliceV2> placeholder(AppLocalizations l10n) =>
      <SdDonutSliceV2>[
        for (final SeverityBand band in SeverityBand.values)
          SdDonutSliceV2(
            value: 1,
            color: AppColors.intensity(
              band.sampleIntensity,
            ).withValues(alpha: _placeholderAlpha),
            label: band.label(l10n),
          ),
      ];
}

class SeverityBreakdownChart extends StatelessWidget {
  const SeverityBreakdownChart({required this.counts, super.key});

  final List<SeverityCount> counts;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<SdDonutSliceV2> slices = SeverityBreakdownSlices.of(
      counts,
      l10n,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SdChartFrameV2(
          title: l10n.historyChartSeverityTitle,
          semanticsLabel: l10n.a11yChart(l10n.historyChartSeverityTitle),
          height: SdChartStyleV2.plotHeight,
          child: SdDonutChartV2(slices: slices),
        ),
        SizedBox(height: SdSpacingConstant.h12),
        SdDonutLegendV2(slices: slices),
      ],
    );
  }
}
