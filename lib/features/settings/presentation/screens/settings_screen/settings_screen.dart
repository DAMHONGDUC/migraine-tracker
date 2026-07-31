import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_content_padding.dart';
import '../../../../../core/constants/app_spacing_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/l10n/locale_provider.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/buttons/app_button.dart';
import '../../../../../core/widgets/app_dialog.dart';
import '../../../../../core/widgets/app_filter_sheet.dart';
import '../../../../../core/widgets/app_icon.dart';
import '../../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_section_header.dart';
import '../../../../../core/widgets/app_snack_bar.dart';
import '../../../../../core/widgets/premium_gate.dart';
import '../../../../alerts/presentation/widgets/alerts_section.dart';
import '../../../../auth/presentation/widgets/account_section.dart';
import '../../../../auth/providers.dart';
import '../../../../premium/presentation/widgets/premium_settings_tile.dart';
import '../../../../premium/providers.dart';
import '../../../domain/enums/app_language.dart';
import '../../../providers.dart';

part 'settings_screen_alerts_section.dart';
part 'settings_screen_data_section.dart';
part 'settings_screen_delete_all_tile.dart';
part 'settings_screen_general_section.dart';

/// Two groups: "General" is how the app behaves for you, "Your data" is
/// what it holds. Deleting closes the second one — same subject as the
/// exports, last because it is the irreversible end of it.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return AppScaffold(
      title: Text(l10n.settingsTitle, style: AppTextStyle.titleLarge),
      body: AppRefreshIndicator(
        onRefresh: () =>
            AppRefreshIndicator.run(() => ref.invalidate(isPremiumProvider)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          // Full-bleed: every row is a ListTile, which insets itself.
          padding: AppContentPadding.fullBleed(context, floatingNav: true),
          children: [
            AppSectionHeader(l10n.settingsSectionGeneral, first: true),
            const _GeneralSection(),
            AppSectionHeader(l10n.settingsSectionData),
            const _DataSection(),
          ],
        ),
      ),
    );
  }
}
