import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../features/home_widget/providers.dart';
import '../../extensions/context_extensions.dart';
import '../../theme/app_text_style.dart';

/// Settings switch for the home-screen widget.
///
/// A switch and not a row leading somewhere: there is nothing to configure —
/// the widget shows the log button, this week's count and the latest
/// pressure, and the only question is whether it is fed at all. Turning it
/// off empties the shared container rather than freezing the last numbers on
/// the home screen.
///
/// Absent where no widget extension ships, which today is everywhere but iOS.
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
      secondary: const SdIconV2(icon: Icons.widgets_outlined),
      title: Text(
        context.l10n.homeWidgetSettingsTitle,
        style: AppTextStyle.bodyLarge,
      ),
      value: ref.watch(homeWidgetControllerProvider),
      onChanged: (bool value) => _toggle(context, ref, value),
    );
  }
}
