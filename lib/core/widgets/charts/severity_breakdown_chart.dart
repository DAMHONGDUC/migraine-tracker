import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../features/history/domain/services/chart_analytics.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../extensions/chart_labels.dart';
import '../../extensions/context_extensions.dart';
import '../../theme/app_colors.dart';

/// Attacks split across the four severity bands, coloured with the same
/// green → yellow → orange → red scale as `AppColors.intensity`.
///
/// Shared by the History → Chart deck and the dashboard's severity card; the
/// counts come from the pure [SeverityBreakdownCalculator]. The slices and
/// legend are `SdDonutChartV2`; what stays here is the app's own vocabulary —
/// which bands exist, what they are called, and what colour each one is.
class SeverityBreakdownChart extends StatelessWidget {
  const SeverityBreakdownChart({required this.counts, super.key});

  final List<SeverityCount> counts;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<SdDonutSliceV2> slices = <SdDonutSliceV2>[
      for (final SeverityCount entry in counts)
        SdDonutSliceV2(
          value: entry.count.toDouble(),
          color: AppColors.intensity(entry.band.sampleIntensity),
          label: '${entry.band.label(l10n)} · ${entry.count}',
        ),
    ];

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
