import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/log_tag_constant.dart';
import '../../../../../core/env/app_env.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/l10n/locale_provider.dart';
import '../../../../../core/permissions/app_permission.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/router/navigation_utils.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icon_constant.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/premium_gate.dart';
import '../../../../../core/widgets/sections/account_section.dart';
import '../../../../../core/widgets/sections/alerts_settings_tile.dart';
import '../../../../../core/widgets/sections/check_in_reminder_tile.dart';
import '../../../../../core/widgets/sections/home_widget_settings_tile.dart';
import '../../../../../core/widgets/sections/insight_settings_tiles.dart';
import '../../../../../core/widgets/sections/notifications_settings_tile.dart';
import '../../../../../core/widgets/sections/premium_settings_tile.dart';
import '../../../../../core/widgets/settings_tile.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../alerts/providers.dart';
import '../../../../app_config/providers.dart';
import '../../../../auth/providers.dart';
import '../../../../medications/providers.dart';
import '../../../../premium/providers.dart';
import '../../../../weather/domain/enums/dev_location.dart';
import '../../../../weather/providers.dart';
import '../../../domain/enums/app_language.dart';
import '../../../providers.dart';

part 'settings_screen_about_section.dart';
part 'settings_screen_data_section.dart';
part 'settings_screen_dev_alert_tile.dart';
part 'settings_screen_dev_delete_data_tile.dart';
part 'settings_screen_dev_local_notification_tile.dart';
part 'settings_screen_dev_location_tile.dart';
part 'settings_screen_dev_premium_tile.dart';
part 'settings_screen_dev_push_tile.dart';
part 'settings_screen_dev_reset_tile.dart';
part 'settings_screen_dev_seed_tile.dart';
part 'settings_screen_general_section.dart';
part 'settings_screen_monitoring_section.dart';

/// Five groups: "General" is the app itself, "Monitoring" is what it watches on your behalf, "Apple Health" is what it reads from elsewhere, "Your.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Watched once here, not read at each row: it is a Firestore document now, so the group has to appear the moment the read lands rather than only on the next rebuild.
    final bool showDev = ref.watch(showDevSettingsProvider);

    return SdScaffoldV2(
      title: Text(l10n.settingsTitle, style: AppTextStyle.titleLarge),
      body: SdRefreshIndicatorV2(
        onRefresh: () =>
            SdRefreshIndicatorV2.run(() => ref.invalidate(isPremiumProvider)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          // Full-bleed: every row is a ListTile, which insets itself.
          padding: SdContentPaddingV2.fullBleed(context, floatingNav: true),
          children: [
            // Keep non-production fixture tools at the top for quick access.
            if (showDev) ...[
              SdSectionHeaderV2(l10n.settingsSectionDev, first: true),
              // Forced premium needs no account, exactly like the real thing (App Store 5.1.1(v) — see `hasPremiumProvider`).
              // On the flavour, not on the grant: `hasPremiumProvider` ignores the override in prod, so a prod build the allow-list opened the group on would draw a switch that does nothing.
              if (!AppEnv.isProd) const _DevPremiumTile(),
              // The push fixture still does: sendTestPush refuses an anonymous session, so the row would only ever fail.
              if (ref.watch(isSignedInProvider)) const _DevPushTile(),
              // Beside the push row but outside the account gate.
              const _DevLocalNotificationTile(),
              // The in-app half of the same idea: no permission, no backend, just the card the app raises itself.
              const _DevAlertTile(),
              // Location comes first because Simulator weather depends on it.
              // Same reason as the premium row: `DevLocationController` returns `off` in prod.
              if (!AppEnv.isProd) const _DevLocationTile(),
              const _DevSeedTile(),
              // The two teardowns, gentlest first: this one empties the app and leaves you on it, the next one sends you back to onboarding.
              const _DevDeleteDataTile(),
              const _DevResetTile(),
            ],
            // `first` follows the section above: the dev group takes the screen's top gap whenever it is there.
            SdSectionHeaderV2(l10n.settingsSectionGeneral, first: !showDev),
            const _GeneralSection(),
            SdSectionHeaderV2(l10n.settingsSectionMonitoring),
            const _MonitoringSection(),
            SdSectionHeaderV2(l10n.settingsSectionData),
            const _DataSection(),
            // Diagnostic info — always last, so a bug report always names its build.
            SdSectionHeaderV2(l10n.settingsSectionAbout),
            const _AboutSection(),
          ],
        ),
      ),
    );
  }
}
