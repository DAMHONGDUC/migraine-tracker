import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../attacks/providers.dart';
import '../../../../medications/providers.dart';
import '../../../../notifications/providers.dart';
import '../../../../premium/providers.dart';
import '../../widgets/dashboard_explore_section.dart';
import '../../widgets/dashboard_log_button.dart';
import '../../widgets/dashboard_severity_card.dart';
import '../../widgets/next_reminder_banner.dart';
import '../../widgets/premium_countdown_banner.dart';
import '../../widgets/quick_access_section.dart';
import '../../widgets/week_summary_card.dart';

/// The app's home tab (replaces the old Log tab). A calm, scrollable overview,
/// top to bottom: premium nudge (free users), the log call-to-action, the next
/// medication reminder (when one is scheduled), this-week stats, quick-access
/// shortcuts, and the feature banners. Logging itself opens as a pushed route
/// from [DashboardLogButton] — the 3-tap flow is unchanged.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final showPremium = !ref.watch(hasPremiumProvider);
    final nextReminder = ref.watch(nextReminderProvider);
    // Data-driven sections only show once there's something to show.
    final hasAttacks =
        ref.watch(attacksStreamProvider).value?.isNotEmpty ?? false;

    // Only sections that should show; gaps inserted below avoid a double gap.
    final sections = <Widget>[
      // A limited-time discount promo pinned right under the app bar.
      const DashboardLogButton(),
      const QuickAccessSection(),
      if (showPremium) const PremiumCountdownBanner(),
      if (nextReminder != null) const NextReminderBanner(),
      if (hasAttacks) const WeekSummaryCard(),
      if (hasAttacks) const DashboardSeverityCard(),
      const DashboardExploreSection(),
    ];

    return SdScaffoldV2(
      title: Text(l10n.dashboardGreeting, style: AppTextStyle.titleLarge),
      actions: <Widget>[
        // The dot is the whole state: a count on a notification badge is
        // a demand, and this app is used mid-migraine.
        SdBadgeDotV2(
          showing: (ref.watch(unreadNotificationCountProvider).value ?? 0) > 0,
          child: SdAppBarButtonV2(
            icon: Icons.notifications_none,
            tooltip: l10n.notificationsA11yOpen,
            onPressed: () =>
                context.pushNamed<void>(AppRoutes.notifications.name),
          ),
        ),
        SizedBox(width: SdSpacingConstant.w12),
      ],
      body: SdRefreshIndicatorV2(
        onRefresh: () => SdRefreshIndicatorV2.run(() {
          ref
            ..invalidate(attacksStreamProvider)
            ..invalidate(medicationRemindersStreamProvider)
            ..invalidate(isPremiumProvider);
        }),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: SdContentPaddingV2.screen(context, floatingNav: true),
          children: [
            for (int i = 0; i < sections.length; i++) ...[
              if (i > 0) SizedBox(height: SdContentPaddingV2.sectionGap),
              sections[i],
            ],
          ],
        ),
      ),
    );
  }
}
