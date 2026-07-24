import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../attacks/providers.dart';

/// The dashboard's hero call-to-action: a soft-gradient card with an icon
/// badge, title and subtitle that opens the sacred 3-tap log flow (a pushed
/// route). Calm by design (hard rule 3) — a static glow and a gentle press
/// scale, no motion. Resets any stale flow state before pushing so it always
/// starts fresh at intensity.
class DashboardLogButton extends ConsumerWidget {
  const DashboardLogButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return PressableScale(
      pressedScale: 0.97,
      onTap: () {
        ref.read(logControllerProvider.notifier).reset();
        context.pushNamed(AppRoutes.log.name);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacingConstant.w20,
          vertical: AppSpacingConstant.h20,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.chartSeries],
          ),
          borderRadius: BorderRadius.circular(AppSpacingConstant.r24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: AppSpacingConstant.r24,
              offset: Offset(0, AppSpacingConstant.h8),
            ),
          ],
        ),
        child: Row(
          children: [
            // A lavender "+" in a dark disc — reads as a crisp badge on the
            // lavender gradient.
            Container(
              width: AppSpacingConstant.r44,
              height: AppSpacingConstant.r44,
              decoration: const BoxDecoration(
                color: AppColors.onPrimary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: AppSpacingConstant.r24,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: AppSpacingConstant.w16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dashboardLogButton,
                    style: AppTextStyle.titleLarge.w600.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacingConstant.h2),
                  Text(
                    l10n.dashboardLogButtonSubtitle,
                    style: AppTextStyle.bodySmall.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacingConstant.w8),
            Icon(
              Icons.arrow_forward_rounded,
              size: AppSpacingConstant.r22,
              color: AppColors.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
