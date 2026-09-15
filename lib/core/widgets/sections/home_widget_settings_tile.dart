import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../features/home_widget/providers.dart';
import '../../extensions/context_extensions.dart';
import '../../theme/app_icon_constant.dart';
import '../../theme/app_icon_size.dart';
import '../../theme/app_text_style.dart';

/// Settings switch for the home-screen widget.
class HomeWidgetSettingsTile extends ConsumerWidget {
  const HomeWidgetSettingsTile({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    try {
      await ref.read(homeWidgetControllerProvider.notifier).setEnabled(value);
    } catch (_) {
      // The controller already logged it; the user needs the outcome.
      if (context.mounted) {
        SdSnackBarUtilsV2.error(context, context.l10n.homeWidgetFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(homeWidgetSupportedProvider)) return const SizedBox.shrink();

    return SwitchListTile(
      secondary: SdIconV2(
        icon: AppIconConstant.homeWidget,
        size: AppIconSize.medium,
      ),
      title: Text(
        context.l10n.homeWidgetSettingsTitle,
        style: AppTextStyle.bodyLarge,
      ),
      value: ref.watch(homeWidgetControllerProvider),
      onChanged: (bool value) => _toggle(context, ref, value),
    );
  }
}
