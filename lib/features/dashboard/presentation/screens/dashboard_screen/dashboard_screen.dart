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
import '../../../providers.dart';
import '../../widgets/attack_limit_banner.dart';
import '../../widgets/dashboard_explore_section.dart';
import '../../widgets/dashboard_log_button.dart';
import '../../widgets/dashboard_summary_group.dart';
import '../../widgets/dashboard_today_section.dart';
import '../../widgets/next_reminder_banner.dart';
import '../../widgets/quick_access_section.dart';

/// The app's home tab (replaces the old Log tab). A calm, scrollable overview,
/// top to bottom: the log call-to-action, the next medication reminder (when
/// one is scheduled), this-week stats, quick-access shortcuts, and the feature
/// banners. Logging itself opens as a pushed route from [DashboardLogButton] —
/// the 3-tap flow is unchanged.
///
/// The premium promo used to sit here and now leads Settings instead (owner's
/// call). [AttackLimitBanner] stays: the log wall lands mid-attack, so it has
/// to be announced somewhere calm first.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final nextReminder = ref.watch(nextReminderProvider);
    // Null unless the free plan's log limit is close (see attacksLeftProvider).
    final int? logsLeft = ref.watch(attacksLeftProvider);

    // Only sections that should show; gaps inserted below avoid a double gap.
    final sections = <Widget>[
      const DashboardLogButton(),
      // Directly under the button it warns about, and only in the last few
      // logs — the wall itself lands mid-attack, so it must not be news.
      if (logsLeft != null) const AttackLimitBanner(),
      const QuickAccessSection(),
      // Asked here rather than left to the widget: a section that hid itself
      // would leave the gap the list inserts before it (see the loop below).
      if (ref.watch(hasTodayReadingsProvider)) const DashboardTodaySection(),
      if (nextReminder != null) const NextReminderBanner(),
      // Unconditional, owner's call: hidden until the first attack it left a
      // new install with a log button and a grid of links and nothing in
      // between. Both cards inside carry their own empty state, so what shows
      // on day one is the shape of what is coming, not a pile of zeroes.
      const DashboardSummaryGroup(),
      const DashboardExploreSection(),
    ];

    return SdScaffoldV2(
      title: Text(l10n.dashboardGreeting, style: AppTextStyle.titleLarge),
      actions: <Widget>[
        // The number, not a dot: how many are waiting is what decides
        // whether the user opens the list now or later.
        SdBadgeV2(
          // Red, not the app's lavender accent: a notification count is the
          // one badge people already read as "unattended", and the accent
          // is what every non-urgent highlight in the app wears.
          color: context.colorScheme.error,
          count: ref.watch(unreadNotificationCountProvider).value ?? 0,
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
