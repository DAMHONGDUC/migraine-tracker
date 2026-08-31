import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../health/domain/enums/health_data_kind.dart';
import '../../../health/providers.dart';

/// One Apple Health source's connect switch, at the top of the card that draws
/// what it reads — sleep on the sleep tab, steps on the activity one.
///
/// **It used to be a Settings row** (owner's call to move it). A switch two
/// screens away from the empty chart it fills is a switch nobody connects: the
/// user is looking at the reading, so the control that turns it on belongs
/// where they are looking. Settings keeps only the row that leads here.
class HealthConnectionTile extends ConsumerWidget {
  const HealthConnectionTile({
    required this.kind,
    required this.icon,
    required this.title,
    super.key,
  });

  final HealthDataKind kind;
  final IconData icon;
  final String title;

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    try {
      final bool connected = await ref
          .read(healthControllerProvider.notifier)
          .setConnected(kind, value);

      if (!context.mounted || connected) return;

      SdSnackBarUtilsV2.error(context, context.l10n.healthConnectFailed);
    } catch (_) {
      // The controller already logged it; the user needs the outcome.
      if (context.mounted) {
        SdSnackBarUtilsV2.error(context, context.l10n.healthConnectFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(healthAvailableProvider)) return const SizedBox.shrink();

    final bool connected = ref.watch(healthControllerProvider).of(kind);

    return SwitchListTile(
      // The card already holds the gutter; the tile's own would inset this row past the chart under it.
      contentPadding: EdgeInsets.zero,
      secondary: SdIconV2(icon: icon, size: AppIconSize.medium),
      title: Text(title, style: AppTextStyle.bodyLarge),
      value: connected,
      onChanged: (bool value) => _toggle(context, ref, value),
    );
  }
}
