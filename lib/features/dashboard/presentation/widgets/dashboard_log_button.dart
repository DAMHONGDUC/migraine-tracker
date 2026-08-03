import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
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

    return SdPressableScaleV2(
      pressedScale: 0.97,
      onTap: () {
        ref.read(logControllerProvider.notifier).reset();
        context.pushNamed(AppRoutes.log.name);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SdSpacingConstant.w20,
          vertical: SdSpacingConstant.h20,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.chartSeries],
          ),
          borderRadius: BorderRadius.circular(SdSpacingConstant.r24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: SdSpacingConstant.r24,
              offset: Offset(0, SdSpacingConstant.h8),
            ),
          ],
        ),
        child: Row(
          children: [
            // A lavender "+" in a dark disc — reads as a crisp badge on the
            // lavender gradient, so the fill is opaque rather than a tint.
            SdIconBadgeV2(
              icon: Icons.add,
              color: AppColors.primary,
              background: AppColors.onPrimary,
              iconSize: SdSpacingConstant.r24,
            ),
            SizedBox(width: SdSpacingConstant.w16),
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
                  SizedBox(height: SdSpacingConstant.h2),
                  Text(
                    l10n.dashboardLogButtonSubtitle,
                    style: AppTextStyle.bodySmall.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: SdSpacingConstant.w8),
            SdIconV2(
              icon: Icons.arrow_forward_rounded,
              size: SdSpacingConstant.r22,
              color: AppColors.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
