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

/// The dashboard's hero call-to-action, opening the sacred 3-tap log flow (a pushed route).
///
/// **A row, not a centred label**: glyph, the action over the promise that
/// makes it cheap to tap ("3 taps · works offline"), then a chevron. The promise
/// is the one thing a first-time user does not know about this button, and a
/// centred single line had no room for it.
class DashboardLogButton extends ConsumerWidget {
  const DashboardLogButton({super.key});

  /// How strongly the glyph's disc darkens the lavender — enough to read as a
  /// well, not so much that it becomes a second button.
  static const double _discAlpha = 0.12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Semantics(
      button: true,
      label: l10n.dashboardLogButton,
      excludeSemantics: true,
      child: SdPressableScaleV2(
        pressedScale: 0.97,
        onTap: () => unawaited(NavigationUtils.toLog(context, ref)),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: SdSpacingConstant.w20,
            vertical: SdSpacingConstant.h16,
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
            children: [
              Container(
                width: SdSpacingConstant.r48,
                height: SdSpacingConstant.r48,
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: _discAlpha),
                  shape: BoxShape.circle,
                ),
                child: SdIconV2(
                  icon: AppIconConstant.add,
                  size: AppIconSize.large,
                  color: AppColors.onPrimary,
                ),
              ),
              SizedBox(width: SdSpacingConstant.w16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.dashboardLogButton,
                      style: AppTextStyle.titleLarge.w600.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                    SizedBox(height: SdSpacingConstant.h2),
                    Text(
                      l10n.dashboardLogButtonHint,
                      style: AppTextStyle.bodySmall.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: SdSpacingConstant.w8),
              SdIconV2(
                icon: AppIconConstant.disclosure,
                size: AppIconSize.small,
                color: AppColors.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
