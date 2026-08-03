import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/chart_labels.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/services/chart_analytics.dart';

/// Bar chart of attacks by quarter of the day (night / morning / afternoon /
/// evening). Teal series to set it apart from the lavender frequency bars.
class TimeOfDayChart extends StatelessWidget {
  const TimeOfDayChart({required this.counts, super.key});

  final List<DayPartCount> counts;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SdChartFrameV2(
      title: l10n.historyChartTimeTitle,
      semanticsLabel: l10n.a11yChart(l10n.historyChartTimeTitle),
      height: SdChartStyleV2.plotHeight,
      child: SdBarChartV2(
        bars: <SdBarV2>[
          for (final DayPartCount entry in counts)
            SdBarV2(
              value: entry.count.toDouble(),
              label: entry.part.label(l10n),
            ),
        ],
        color: AppColors.secondary,
        barWidth: SdSpacingConstant.w20,
        tooltip: (num value) => l10n.historyChartTooltip(value.toInt()),
      ),
    );
  }
}
