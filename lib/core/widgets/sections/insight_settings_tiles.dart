import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/health/providers.dart';
import '../../extensions/context_extensions.dart';
import '../../router/app_router.dart';
import '../premium_gate.dart';
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
      icon: Icons.directions_walk,
      title: context.l10n.insightsActivityTitle,
      onTap: () => context.pushNamed(AppRoutes.activity.name),
    );
  }
}

/// Settings row for sleep: opens the screen holding the sleep insight and its
/// connect switch. Premium as a whole — the insight it leads to is premium,
/// so connecting first would be a permission prompt for nothing.
class SleepSettingsTile extends ConsumerWidget {
  const SleepSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(healthAvailableProvider)) return const SizedBox.shrink();

    return PremiumTileGate(
      icon: Icons.bedtime_outlined,
      title: context.l10n.sleepScreenTitle,
      child: SettingsTile(
        icon: Icons.bedtime_outlined,
        title: context.l10n.sleepScreenTitle,
        onTap: () => context.pushNamed(AppRoutes.sleep.name),
      ),
    );
  }
}
