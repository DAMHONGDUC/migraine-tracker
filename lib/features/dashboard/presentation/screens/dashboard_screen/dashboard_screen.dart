import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_icon_constant.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/weather/current_weather_card.dart';
import '../../../../attacks/presentation/widgets/attack_in_progress_card.dart';
import '../../../../attacks/providers.dart';
import '../../../../auth/providers.dart';
import '../../../../daily_log/presentation/widgets/daily_check_in_card.dart';
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
import '../../widgets/risk_score_card.dart';

/// The app's home tab (replaces the old Log tab).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Null until there is an account with a name on it, which is also every anonymous session.
    final String? firstName = ref.watch(firstNameProvider);
    final nextReminder = ref.watch(nextReminderProvider);
    // Null unless the free plan's log limit is close (see attacksLeftProvider).
    final int? logsLeft = ref.watch(attacksLeftProvider);

    // Only sections that should show; gaps inserted below avoid a double gap.
    final sections = <Widget>[
      // Above the premium banner and the log button both: while an attack is running it is the only thing on this screen that is urgent.
      if (ref.watch(attackInProgressProvider) != null)
        const AttackInProgressCard(),
      // Top of the screen, owner's call.
      if (!ref.watch(hasPremiumProvider) && logsLeft == null)
        const PremiumBanner(),
      const DashboardLogButton(),
      // Directly under the button it warns about, and only in the last few logs — the wall itself lands mid-attack, so it must not be news.
      if (logsLeft != null) const AttackLimitBanner(),
      // Under the log button and above the shortcuts: the one thing the app asks for on a day that did not hurt.
      const DailyCheckInCard(),
      const QuickAccessSection(),
      // Under the shortcuts, owner's call: the top of the screen is the call to action, and the readings start here.
      const CurrentWeatherCard(),
      // Directly under the weather it is built on. Premium only, and absent rather than locked — the banner is this screen's one premium door.
      const RiskScoreCard(),
      // Directly under the weather (owner's call).
      if (nextReminder != null) const NextReminderBanner(),
      // Asked here rather than left to the widget: a section that hid itself would leave the gap the list inserts before it (see the loop below).
      if (ref.watch(hasTodayReadingsProvider)) const DashboardTodaySection(),
      // Unconditional, owner's call: hidden until the first attack, it left a new install with a log button, a grid of links and nothing between.
      const DashboardSummaryGroup(),
      const DashboardExploreSection(),
    ];

    return SdScaffoldV2(
      title: Text(
        // The first name alone: "Hi, Dam Hong Duc" is a form field read aloud, and the app bar has one line to give it.
        firstName == null
            ? l10n.dashboardGreeting
            : l10n.dashboardGreetingNamed(firstName),
        style: AppTextStyle.titleLarge,
      ),
      actions: <Widget>[
        // The number, not a dot: how many are waiting is what decides whether the user opens the list now or later.
        SdBadgeV2(
          // Red, not the app's lavender accent.
          color: context.colorScheme.error,
          count: ref.watch(unreadNotificationCountProvider).value ?? 0,
          showing: (ref.watch(unreadNotificationCountProvider).value ?? 0) > 0,
          child: SdAppBarButtonV2(
            icon: AppIconConstant.notifications,
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
            // The weather card is on this screen now, so the screen's own pull-to-refresh has to refetch what it draws.
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
