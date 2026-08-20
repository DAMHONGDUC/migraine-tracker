import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/weather/current_weather_card.dart';
import '../../../../attacks/providers.dart';
import '../../../../medications/providers.dart';
import '../../../../notifications/providers.dart';
import '../../../../premium/providers.dart';
import '../../../../weather/providers.dart';
import '../../../providers.dart';
import '../../widgets/attack_limit_banner.dart';
import '../../widgets/dashboard_explore_section.dart';
import '../../widgets/dashboard_log_button.dart';
import '../../widgets/dashboard_summary_group.dart';
import '../../widgets/dashboard_today_section.dart';
import '../../widgets/next_reminder_banner.dart';
import '../../widgets/premium_banner.dart';
import '../../widgets/quick_access_section.dart';

/// The app's home tab (replaces the old Log tab). A calm, scrollable overview,
/// top to bottom: the log call-to-action, quick-access shortcuts, the weather
/// right now, the next medication reminder (when one is scheduled), today's
/// other readings, this-week stats, and the feature banners. Logging itself opens as a pushed route from [DashboardLogButton] —
/// the 3-tap flow is unchanged.
///
/// [PremiumBanner] sits above all of it (owner's call). The promo that left
/// this screen for Settings was the countdown panel — a ticking discount with
/// its own button, which competed with the log button under it; one banner
/// line does not. [AttackLimitBanner] stays too: the log wall lands
/// mid-attack, so it has to be announced somewhere calm first.
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
      // Top of the screen, owner's call. Free users only, and never beside
      // AttackLimitBanner: that is this same pitch with a reason attached,
      // and two premium banners stacked is how both stop being read.
      if (!ref.watch(hasPremiumProvider) && logsLeft == null)
        const PremiumBanner(),
      const DashboardLogButton(),
      // Directly under the button it warns about, and only in the last few
      // logs — the wall itself lands mid-attack, so it must not be news.
      if (logsLeft != null) const AttackLimitBanner(),
      const QuickAccessSection(),
      // Under the shortcuts, owner's call: the top of the screen is the call
      // to action, and the readings start here. Placed unconditionally — the
      // card draws its own loading and unavailable line, so it leaves no gap.
      const CurrentWeatherCard(),
      // Directly under the weather (owner's call): both answer "what is
      // happening now", so the next dose belongs beside the sky rather than
      // below a block of readings the user may not have scrolled to.
      if (nextReminder != null) const NextReminderBanner(),
      // Asked here rather than left to the widget: a section that hid itself
      // would leave the gap the list inserts before it (see the loop below).
      if (ref.watch(hasTodayReadingsProvider)) const DashboardTodaySection(),
      // Unconditional, owner's call: hidden until the first attack, it left a
      // new install with a log button, a grid of links and nothing between.
      // Both cards carry their own empty state, so day one shows the shape.
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
            // The weather card is on this screen now, so the screen's own
            // pull-to-refresh has to refetch what it draws.
            ..invalidate(weatherReportProvider)
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
