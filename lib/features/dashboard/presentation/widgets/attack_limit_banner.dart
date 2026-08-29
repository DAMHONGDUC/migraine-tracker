import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../attacks/providers.dart';

/// How many free logs are left, once there are few enough to say.
class AttackLimitBanner extends ConsumerWidget {
  const AttackLimitBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int? left = ref.watch(attacksLeftProvider);

    if (left == null) return const SizedBox.shrink();

    return SdBannerV2(
      icon: AppIconConstant.runningOut,
      color: AppColors.primary,
      title: context.l10n.attackLimitBannerTitle(left),
      subtitle: context.l10n.attackLimitBannerBody,
      onTap: () => NavigationUtils.toPaywall(context, ref),
    );
  }
}
