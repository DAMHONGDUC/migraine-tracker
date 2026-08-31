import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/health/providers.dart';
import '../../../features/insights/domain/enums/insights_tab.dart';
import '../../extensions/context_extensions.dart';
import '../../router/navigation_utils.dart';
import '../../theme/app_icon_constant.dart';
import '../settings_tile.dart';

/// Settings row for activity: selects Insights' activity tab.
///
/// It used to push `/activity`, a screen that held the same exertion report,
/// the same step insight and the same connect switch as the tab — a second
/// copy of one subject, reachable only from Settings. The screens are gone
/// (owner's call) and both rows are doors to the tab that already existed.
class ActivitySettingsTile extends ConsumerWidget {
  const ActivitySettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsTile(
      icon: AppIconConstant.steps,
      title: context.l10n.insightsActivityTitle,
      onTap: () =>
          NavigationUtils.toInsights(context, ref, InsightsTab.activity),
    );
  }
}

/// Settings row for sleep: selects Insights' sleep tab.
class SleepSettingsTile extends ConsumerWidget {
  const SleepSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Off iOS there is no sleep tab in the strip to send anyone to.
    if (!ref.watch(healthAvailableProvider)) return const SizedBox.shrink();

    return SettingsTile(
      icon: AppIconConstant.sleep,
      title: context.l10n.sleepScreenTitle,
      onTap: () => NavigationUtils.toInsights(context, ref, InsightsTab.sleep),
    );
  }
}
