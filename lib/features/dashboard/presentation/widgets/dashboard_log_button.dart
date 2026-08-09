import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/premium_limit_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../attacks/providers.dart';

/// The dashboard's hero call-to-action: a tall lavender block, centred glyph
/// and label, that opens the sacred 3-tap log flow (a pushed route).
///
/// Deliberately breaks the rhythm of the cards below it. Someone reaching for
/// this is mid-attack — squinting, maybe in the dark — so it has to be found
/// without reading, which is why it is centred, full-width and the tallest
/// thing on the screen. Calm all the same (hard rule 3): a flat fill, a static
/// glow and a gentle press scale, no motion. Resets any stale flow state
/// before pushing so it always starts fresh at intensity.
class DashboardLogButton extends ConsumerWidget {
  const DashboardLogButton({super.key});

  /// The free plan's attack limit is the one gate that lands on this button.
  /// It names itself first, like every other record limit — and the
  /// dashboard has been counting down to it for the last few logs, so it is
  /// never the first the user hears of it.
  Future<void> _open(BuildContext context, WidgetRef ref) async {
    if (!ref.read(canLogAttackProvider)) {
      await NavigationUtils.toPaywallFromLimit(
        context,
        ref,
        title: context.l10n.attackLimitTitle(PremiumLimitConstant.attacks),
        body: context.l10n.attackLimitBody(PremiumLimitConstant.attacks),
      );
      return;
    }

    ref.read(logControllerProvider.notifier).reset();
    if (context.mounted) unawaited(context.pushNamed(AppRoutes.log.name));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return SdPressableScaleV2(
      pressedScale: 0.97,
      onTap: () => unawaited(_open(context, ref)),
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
              icon: Icons.add_rounded,
              size: SdSpacingConstant.r28,
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
