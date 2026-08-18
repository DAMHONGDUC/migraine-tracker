import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_colors.dart';

/// One short line at the top of the dashboard offering premium, for free
/// users only.
///
/// Owner's call, and it reverses the earlier one that moved the promo to
/// Settings: what left the dashboard was [PremiumCountdownBanner], a ticking
/// discount panel with its own button that competed with the log button
/// underneath it. This is the same offer at a banner's size — the same
/// [SdBannerV2] the rest of the screen speaks in, tapped as a whole, no
/// countdown and no second call to action.
///
/// Who sees it is decided by `DashboardScreen`, not here — free users only,
/// and never beside [AttackLimitBanner], which is the same pitch with a
/// reason attached. A widget that hid itself would leave behind the gap the
/// dashboard's list inserts above it.
class PremiumBanner extends ConsumerWidget {
  const PremiumBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SdBannerV2(
      icon: Icons.workspace_premium_outlined,
      color: AppColors.primary,
      // The one outlined card in the app (owner's call): the dashboard is a
      // stack of same-coloured panels and the offer has to be seen first.
      borderColor: AppColors.primary,
      title: context.l10n.dashboardPremiumBannerTitle,
      subtitle: context.l10n.dashboardPremiumBannerBody,
      onTap: () => NavigationUtils.toPaywall(context, ref),
    );
  }
}
