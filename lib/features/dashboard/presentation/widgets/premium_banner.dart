import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/dashboard_chevron.dart';

/// One short row at the top of the dashboard offering premium, for free users only.
class PremiumBanner extends ConsumerWidget {
  const PremiumBanner({super.key});

  /// Smaller than a banner's `SdIconBadgeV2` default (44), which is what buys most of the height back.
  static double get badgeSize => SdSpacingConstant.r36;

  /// Eight above and below the badge — the row is already 36 tall, so the card clears the 44 touch minimum without a banner's 16.
  static double get _verticalPadding => SdSpacingConstant.h8;

  /// The tint and the outline, at the strengths `PremiumCountdownBanner` wore before it was removed (owner's call: highlight it the way that one did).
  static const double _fillAlpha = 0.12;
  static const double _borderAlpha = 0.35;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SdCardV2(
      onTap: () => NavigationUtils.toPaywall(context, ref),
      fillColor: AppColors.primary.withValues(alpha: _fillAlpha),
      borderColor: AppColors.primary.withValues(alpha: _borderAlpha),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SdContentPaddingV2.horizontal,
          vertical: _verticalPadding,
        ),
        child: Row(
          children: <Widget>[
            SdIconBadgeV2(
              icon: AppIconConstant.premium,
              color: AppColors.primary,
              size: badgeSize,
              iconSize: SdSpacingConstant.r20,
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: Text(
                context.l10n.dashboardPremiumBannerTitle,
                style: AppTextStyle.bodyLarge.w600,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: SdSpacingConstant.w8),
            const DashboardChevron(),
          ],
        ),
      ),
    );
  }
}
