import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_style.dart';

/// Row of shortcuts to the other tabs (History, the insights chart, and
/// Medications). Each card switches the shell's active branch via go_router
/// rather than pushing a new route, so the bottom nav stays in sync.
class QuickAccessSection extends StatelessWidget {
  const QuickAccessSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                // Distinct from the bottom nav's calendar/insights/medication
                // icons on purpose — a shared icon would read as the same
                // control twice (and makes byIcon finders ambiguous in tests).
                icon: Icons.history,
                label: l10n.navHistory,
                onTap: () => context.goNamed(AppRoutes.history.name),
              ),
            ),
            SizedBox(width: AppSpacingConstant.w12),
            Expanded(
              child: _QuickAccessCard(
                icon: Icons.show_chart,
                label: l10n.navInsights,
                onTap: () => context.goNamed(AppRoutes.insights.name),
              ),
            ),
            SizedBox(width: AppSpacingConstant.w12),
            Expanded(
              child: _QuickAccessCard(
                icon: Icons.medical_services_outlined,
                label: l10n.navMedications,
                onTap: () => context.goNamed(AppRoutes.medications.name),
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
