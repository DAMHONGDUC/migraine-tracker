import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../premium/providers.dart';

/// Promo card nudging free users to the paywall. Renders nothing for premium
/// users — no locked surface, no leaked data path (hard rule: gating comes
/// from the entitlement, never a client flag).
class DashboardPremiumCard extends ConsumerWidget {
  const DashboardPremiumCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(hasPremiumProvider)) return const SizedBox.shrink();

    final l10n = context.l10n;
    return Card(
      color: AppColors.primary.withValues(alpha: 0.12),
      child: Padding(
        padding: EdgeInsets.all(AppSpacingConstant.w20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium_outlined,
                  size: AppSpacingConstant.r22,
                  color: context.colorScheme.primary,
                ),
                SizedBox(width: AppSpacingConstant.w8),
                Text(
                  l10n.dashboardPremiumTitle,
                  style: AppTextStyle.titleMedium,
                ),
              ],
            ),
            SizedBox(height: AppSpacingConstant.h8),
            Text(
              l10n.dashboardPremiumBody,
              style: AppTextStyle.bodyMedium.secondary,
            ),
            SizedBox(height: AppSpacingConstant.h16),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: AppButton.secondary(
                onPressed: () => context.pushNamed(AppRoutes.paywall.name),
                label: l10n.premiumUnlock,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
