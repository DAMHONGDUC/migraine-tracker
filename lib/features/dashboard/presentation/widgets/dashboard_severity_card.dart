import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/charts/severity_breakdown_chart.dart';
import '../../../attacks/providers.dart';
import '../../../history/domain/enums/history_view_mode.dart';
import '../../../history/domain/services/chart_analytics.dart';
import '../../../history/providers.dart';
import 'dashboard_chevron.dart';

/// Dashboard preview of the severity mix.
class DashboardSeverityCard extends ConsumerWidget {
  const DashboardSeverityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final attacks = ref.watch(attacksStreamProvider).value ?? const [];
    final List<SeverityCount> counts = const SeverityBreakdownCalculator()
        .compute(attacks);
    final bool hasAttacks = attacks.isNotEmpty;
    // The real mix, or the scale it will be drawn on.
    final List<SdDonutSliceV2> slices = hasAttacks
        ? SeverityBreakdownSlices.of(counts, l10n)
        : SeverityBreakdownSlices.placeholder(l10n);

    void openChart() {
      ref.read(historyViewModeProvider.notifier).select(HistoryViewMode.chart);
      context.goNamed(AppRoutes.history.name);
    }

    return SdCardV2(
      surface: SdCardSurfaceV2.elevated,
      // Nothing to open while there is nothing to chart: the History chart is as empty as this card, so tapping through would be a dead end.
      onTap: hasAttacks ? openChart : null,
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w16),
        child: Row(
          children: [
            // The ring is hidden from VoiceOver: the legend beside it already names every band and its count.
            ExcludeSemantics(
              child: SizedBox(
                width: SdSpacingConstant.r88,
                height: SdSpacingConstant.r88,
                child: SdDonutChartV2(
                  slices: slices,
                  centerRadius: SdSpacingConstant.r26,
                  thickness: SdSpacingConstant.r16,
                ),
              ),
            ),
            SizedBox(width: SdSpacingConstant.w16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          l10n.historyChartSeverityTitle,
                          style: AppTextStyle.titleSmall,
                        ),
                      ),
                      // Absent while empty, where the card opens nothing — the mark promises a screen, so it may not appear above a tap that goes nowhere.
                      if (hasAttacks) const DashboardChevron(),
                    ],
                  ),
                  SizedBox(height: SdSpacingConstant.h8),
                  // The legend carries the band names either way.
                  SdDonutLegendV2(slices: slices),
                  if (!hasAttacks) ...<Widget>[
                    SizedBox(height: SdSpacingConstant.h8),
                    Text(
                      l10n.dashboardSeverityEmpty,
                      style: AppTextStyle.bodySmall.secondary,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
