import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';

/// The dashboard's hero call-to-action: a tall lavender block, centred glyph and label, that opens the sacred 3-tap log flow (a pushed route).
class DashboardLogButton extends ConsumerWidget {
  const DashboardLogButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return SdPressableScaleV2(
      pressedScale: 0.97,
      onTap: () => unawaited(NavigationUtils.toLog(context, ref)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: SdSpacingConstant.w20,
          vertical: SdSpacingConstant.h32,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SdIconV2(
              icon: AppIconConstant.add,
              size: AppIconSize.tile,
              color: AppColors.onPrimary,
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Flexible(
              child: Text(
                l10n.dashboardLogButton,
                textAlign: TextAlign.center,
                style: AppTextStyle.headlineSmall.w600.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
