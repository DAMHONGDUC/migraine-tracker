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

/// Dashboard preview of the severity mix: the donut beside its legend rather
/// than above it, which is what lets the whole card sit in one glance next to
/// the week summary.
///
/// The full deck on History keeps the tall layout — only the arrangement
/// differs. Both read [SeverityBreakdownSlices] and the pure
/// [SeverityBreakdownCalculator], so the bands, their names and their colours
/// stay in lockstep. Tapping opens History already on the chart view.
class DashboardSeverityCard extends ConsumerWidget {
  const DashboardSeverityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final attacks = ref.watch(attacksStreamProvider).value ?? const [];
    final List<SeverityCount> counts = const SeverityBreakdownCalculator()
        .compute(attacks);
    final List<SdDonutSliceV2> slices = SeverityBreakdownSlices.of(
      counts,
      l10n,
    );

    void openChart() {
      ref.read(historyViewModeProvider.notifier).select(HistoryViewMode.chart);
      context.goNamed(AppRoutes.history.name);
    }

    return SdCardV2(
      surface: SdCardSurfaceV2.elevated,
      onTap: openChart,
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w16),
        child: Row(
          children: [
            // The ring is hidden from VoiceOver: the legend beside it already
            // names every band and its count.
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
                  Text(
                    l10n.historyChartSeverityTitle,
                    style: AppTextStyle.titleSmall,
                  ),
                  SizedBox(height: SdSpacingConstant.h8),
                  SdDonutLegendV2(slices: slices),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
