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
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/premium_gate.dart';
import '../../../../../core/widgets/sections/account_section.dart';
import '../../../../../core/widgets/sections/alerts_settings_tile.dart';
import '../../../../../core/widgets/sections/health_connection_tile.dart';
import '../../../../../core/widgets/sections/home_widget_settings_tile.dart';
import '../../../../../core/widgets/sections/insight_settings_tiles.dart';
import '../../../../../core/widgets/sections/notifications_settings_tile.dart';
import '../../../../../core/widgets/sections/premium_settings_tile.dart';
import '../../../../../core/widgets/sections/sync_settings_tile.dart';
import '../../../../../core/widgets/settings_row_progress.dart';
import '../../../../../core/widgets/settings_tile.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../alerts/providers.dart';
import '../../../../app_update/domain/entities/installed_app_version.dart';
import '../../../../app_update/providers.dart';
import '../../../../auth/providers.dart';
import '../../../../health/domain/enums/health_data_kind.dart';
import '../../../../health/providers.dart';
import '../../../../medications/providers.dart';
import '../../../../premium/providers.dart';
import '../../../../weather/domain/enums/dev_location.dart';
import '../../../../weather/providers.dart';
import '../../../domain/entities/wipe_status.dart';
import '../../../domain/enums/app_language.dart';
import '../../../domain/services/app_version_label.dart';
import '../../../providers.dart';

part 'settings_screen_about_section.dart';
part 'settings_screen_data_section.dart';
part 'settings_screen_delete_all_tile.dart';
part 'settings_screen_dev_local_notification_tile.dart';
part 'settings_screen_dev_location_tile.dart';
part 'settings_screen_dev_premium_tile.dart';
part 'settings_screen_dev_push_tile.dart';
part 'settings_screen_dev_reset_tile.dart';
part 'settings_screen_dev_seed_tile.dart';
part 'settings_screen_general_section.dart';
part 'settings_screen_health_section.dart';
part 'settings_screen_monitoring_section.dart';

/// Five groups: "General" is the app itself, "Monitoring" is what it watches
/// on your behalf, "Apple Health" is what it reads from elsewhere, "Your
/// data" is what it holds, "About" is the app's own details. Deleting closes
/// "Your data" — same subject as the exports, and the irreversible end of it.
/// Apple Health is iOS-only, so off iOS the count is back to four.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

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
            // Fixture tooling — only off prod, and always at the top of the
            // screen (owner's rule): it is the group a developer opens
            // Settings for, and below the real sections it meant scrolling.
            if (!AppEnv.isProd) ...[
              SdSectionHeaderV2(l10n.settingsSectionDev, first: true),
              // Both need a real account: premium binds to one
              // (`PurchaseIdentity`), so an anonymous session would simulate a
              // state production cannot reach, and sendTestPush refuses one.
              if (ref.watch(isSignedInProvider)) ...<Widget>[
                const _DevPremiumTile(),
                const _DevPushTile(),
              ],
              // Beside the push row but outside the account gate: a local
              // notification needs no account, and the pair is what says which
              // half of the delivery path failed when a reminder never lands.
              const _DevLocalNotificationTile(),
              // First of the fixtures: it is the one that decides whether the
              // weather card has anything to draw on a Simulator, so it is
              // what a dev reaches for before the seed.
              const _DevLocationTile(),
              const _DevSeedTile(),
              const _DevResetTile(),
            ],
            // `first` follows the section above: the dev group takes the
            // screen's top gap whenever it is there.
            SdSectionHeaderV2(
              l10n.settingsSectionGeneral,
              first: AppEnv.isProd,
            ),
            const _GeneralSection(),
            SdSectionHeaderV2(l10n.settingsSectionMonitoring),
            const _MonitoringSection(),
            // Its own group, right under Monitoring: the sources it reads feed
            // two of the rows above, and naming Apple Health at the top level
            // is what App Store 2.5.1 asks for (see [_HealthSection]).
            if (ref.watch(healthAvailableProvider)) ...<Widget>[
              SdSectionHeaderV2(l10n.settingsSectionHealth),
              const _HealthSection(),
            ],
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
