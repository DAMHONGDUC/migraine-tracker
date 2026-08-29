import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/health/providers.dart';
import '../../extensions/context_extensions.dart';
import '../../router/app_router.dart';
import '../../theme/app_icon_constant.dart';
import '../settings_tile.dart';

/// Settings row for activity: opens the screen holding the exertion report, the step insight and the step connect switch.
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

/// Settings row for sleep: opens the screen holding the sleep insight and its connect switch.
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
