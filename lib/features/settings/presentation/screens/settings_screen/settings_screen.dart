import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/extensions/head_location_label.dart';
import '../../../../../core/l10n/locale_provider.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_dialog.dart';
import '../../../../../core/widgets/app_filter_sheet.dart';
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
import '../../../domain/enums/app_language.dart';
import '../../../domain/enums/export_format.dart';
import '../../../providers.dart';
import '../../widgets/export_format_sheet.dart';

part 'settings_screen_alerts_section.dart';
part 'settings_screen_data_section.dart';
part 'settings_screen_delete_all_tile.dart';
part 'settings_screen_general_section.dart';

/// Settings, in two labelled groups.
///
/// "General" is how the app behaves for you — the account, pressure alerts,
/// language. "Your data" is what the app holds — getting it out, and
/// deleting it. Deleting closes out that second group rather than standing
/// alone: same subject as the exports, last because it is the irreversible
/// end of it.
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
            AppSectionHeader(l10n.settingsSectionGeneral),
            const _GeneralSection(),
            AppSectionHeader(l10n.settingsSectionData),
            const _DataSection(),
          ],
        ),
      ),
    );
  }
}
