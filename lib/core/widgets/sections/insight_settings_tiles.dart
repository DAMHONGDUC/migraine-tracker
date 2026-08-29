import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/health/providers.dart';
import '../../extensions/context_extensions.dart';
import '../../router/app_router.dart';
import '../../theme/app_icon_constant.dart';
import '../settings_tile.dart';

/// Settings row for activity: opens the screen holding the exertion report,
/// the step insight and the step connect switch.
///
/// Not premium-gated, unlike [SleepSettingsTile]: the exertion half of that
/// screen is free, so a locked row would hide something the user already has.
class ActivitySettingsTile extends StatelessWidget {
  const ActivitySettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: AppIconConstant.steps,
      title: context.l10n.insightsActivityTitle,
      onTap: () => context.pushNamed(AppRoutes.activity.name),
    );
  }
}

/// Settings row for sleep: opens the screen holding the sleep insight and its
/// connect switch.
///
/// **Not premium-gated any more, and this reversed the original.** It used to
/// wrap itself in `PremiumTileGate` on the argument that connecting first
/// would be a permission prompt for nothing — but the screen behind it also
/// holds the Apple Health switch and `SleepSummaryCard`, both free, and the
/// gate made the app's only HealthKit surfaces unreachable for a free user.
/// Submission 1.0(11) was rejected under App Store 2.5.1 for exactly that.
/// Only [SleepCorrelationCard] on the screen itself stays premium.
class SleepSettingsTile extends ConsumerWidget {
  const SleepSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(healthAvailableProvider)) return const SizedBox.shrink();

    return SettingsTile(
      icon: AppIconConstant.sleep,
      title: context.l10n.sleepScreenTitle,
      onTap: () => context.pushNamed(AppRoutes.sleep.name),
    );
  }
}
