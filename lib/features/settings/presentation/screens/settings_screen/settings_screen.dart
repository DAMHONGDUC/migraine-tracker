import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/extensions/head_location_label.dart';
import '../../../../../core/l10n/locale_provider.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_dialog.dart';
import '../../../../../core/widgets/app_icon.dart';
import '../../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_section_header.dart';
import '../../../../alerts/presentation/widgets/alerts_section.dart';
import '../../../../attacks/domain/enums/head_location.dart';
import '../../../../auth/presentation/widgets/account_section.dart';
import '../../../../insights/domain/services/doctor_report_builder.dart';
import '../../../../premium/presentation/widgets/premium_gate.dart';
import '../../../../premium/providers.dart';
import '../../../domain/enums/export_format.dart';
import '../../../providers.dart';

part 'settings_screen_alerts_section.dart';
part 'settings_screen_danger_section.dart';
part 'settings_screen_data_section.dart';
part 'settings_screen_general_section.dart';

/// Settings, grouped into labelled sections so a long flat list does not
/// bury the destructive row next to the harmless ones.
///
/// Order is by how often a row is touched, with the irreversible one last:
/// account → alerts → general → data → delete.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return AppScaffold(
      title: Text(l10n.settingsTitle),
      body: AppRefreshIndicator(
        onRefresh: () =>
            AppRefreshIndicator.run(() => ref.invalidate(isPremiumProvider)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: AppScaffold.bodyTopInset(context),
            bottom: AppScaffold.bottomNavInset(context),
          ),
          children: [
            AppSectionHeader(l10n.settingsSectionAccount),
            const AccountSection(),
            AppSectionHeader(l10n.settingsSectionAlerts),
            const _AlertsSection(),
            AppSectionHeader(l10n.settingsSectionGeneral),
            const _GeneralSection(),
            AppSectionHeader(l10n.settingsSectionData),
            const _DataSection(),
            AppSectionHeader(l10n.settingsSectionDanger),
            const _DangerSection(),
          ],
        ),
      ),
    );
  }
}
