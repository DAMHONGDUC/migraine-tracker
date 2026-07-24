import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../history/domain/enums/history_view_mode.dart';
import '../../../history/providers.dart';

/// Quick access to the two History visualisations. Each card sets the History
/// view mode, then switches to that branch via go_router, so tapping "Calendar"
/// lands directly on the calendar (not the default list).
class QuickAccessSection extends ConsumerWidget {
  const QuickAccessSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    void openHistory(HistoryViewMode mode) {
      ref.read(historyViewModeProvider.notifier).select(mode);
      context.goNamed(AppRoutes.history.name);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: AppSpacingConstant.w4),
          child: Text(
            l10n.dashboardQuickAccess,
            style: AppTextStyle.titleSmall.secondary,
          ),
        ),
        SizedBox(height: AppSpacingConstant.h12),
        Row(
          children: [
            Expanded(
              child: _QuickAccessCard(
                // Distinct from the bottom nav's calendar_month_outlined so
                // byIcon finders stay unambiguous (see the byicon gotcha).
                icon: Icons.calendar_today_outlined,
                label: l10n.dashboardCalendarShortcut,
                onTap: () => openHistory(HistoryViewMode.calendar),
              ),
            ),
            SizedBox(width: AppSpacingConstant.w12),
            Expanded(
              child: _QuickAccessCard(
                icon: Icons.bar_chart,
                label: l10n.dashboardChartShortcut,
                onTap: () => openHistory(HistoryViewMode.chart),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacingConstant.h20),
          child: Column(
            children: [
              Icon(
                icon,
                size: AppSpacingConstant.r28,
                color: context.colorScheme.primary,
              ),
              SizedBox(height: AppSpacingConstant.h8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
