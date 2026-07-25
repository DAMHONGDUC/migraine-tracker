import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/charts/chart_card.dart';
import '../../../../core/widgets/charts/severity_breakdown_chart.dart';
import '../../../../core/widgets/pressable_scale.dart';
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
    final attacks =
        ref.watch(attacksStreamProvider).value ?? const [];
    final counts = const SeverityBreakdownCalculator().compute(attacks);

    void openChart() {
      ref.read(historyViewModeProvider.notifier).select(HistoryViewMode.chart);
      context.goNamed(AppRoutes.history.name);
    }

    return PressableScale(
      onTap: openChart,
      child: ChartCard(
        child: Stack(
          children: [
            IgnorePointer(child: SeverityBreakdownChart(counts: counts)),
            PositionedDirectional(
              top: 0,
              end: 0,
              child: AppIcon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: AppSpacingConstant.r24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
