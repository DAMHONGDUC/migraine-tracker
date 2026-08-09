import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../attacks/providers.dart';

/// How many free logs are left, once there are few enough to say.
///
/// The attack wall lands on the log button, which is tapped mid-attack — the
/// worst possible moment to learn a limit exists. So the last few logs are
/// counted down here instead, where the user is calm and can decide in their
/// own time.
///
/// Absent while premium, and while the end is still far off — a banner that
/// is always there stops being read (see [attacksLeftProvider]).
class AttackLimitBanner extends ConsumerWidget {
  const AttackLimitBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int? left = ref.watch(attacksLeftProvider);

    if (left == null) return const SizedBox.shrink();

    return SdBannerV2(
      icon: Icons.hourglass_bottom_outlined,
      color: AppColors.primary,
      title: context.l10n.attackLimitBannerTitle(left),
      subtitle: context.l10n.attackLimitBannerBody,
      onTap: () => NavigationUtils.toPaywall(context, ref),
    );
  }
}
