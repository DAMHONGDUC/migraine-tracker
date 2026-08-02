import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/v2/index.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/charts/severity_breakdown_chart.dart';
import '../../../attacks/providers.dart';
import '../../../history/domain/enums/history_view_mode.dart';
import '../../../history/domain/services/chart_analytics.dart';
import '../../../history/providers.dart';

/// Dashboard preview of the severity-mix donut. Tapping it opens the History
/// tab already switched to the chart view (the full deck). Uses the shared
/// [SeverityBreakdownChart] and the pure [SeverityBreakdownCalculator] so the
/// dashboard and the chart screen stay in lockstep; the chart is wrapped in an
/// [IgnorePointer] so the whole card is one tap target (its own slice tooltips
/// would otherwise swallow the tap).
class DashboardSeverityCard extends ConsumerWidget {
  const DashboardSeverityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attacks = ref.watch(attacksStreamProvider).value ?? const [];
    final counts = const SeverityBreakdownCalculator().compute(attacks);

    void openChart() {
      ref.read(historyViewModeProvider.notifier).select(HistoryViewMode.chart);
      context.goNamed(AppRoutes.history.name);
    }

    return SdPressableScaleV2(
      onTap: openChart,
      child: SdChartCardV2(
        child: Stack(
          children: [
            IgnorePointer(child: SeverityBreakdownChart(counts: counts)),
            PositionedDirectional(
              top: 0,
              end: 0,
              child: SdIconV2(
                icon: Icons.chevron_right,
                color: AppColors.textSecondary,
                size: SdSpacingV2.r24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
