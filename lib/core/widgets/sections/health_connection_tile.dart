import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../core/theme/app_text_style.dart';
import '../../../features/health/domain/enums/health_data_kind.dart';
import '../../../features/health/providers.dart';
import '../../extensions/context_extensions.dart';
import '../../theme/app_icon_size.dart';

/// One Apple Health source's connect switch, on the detail screen for the insight it feeds — sleep on the sleep screen, steps on the activity one.
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
      secondary: SdIconV2(icon: icon, size: AppIconSize.row),
      title: Text(title, style: AppTextStyle.bodyLarge),
      value: connected,
      onChanged: (bool value) => _toggle(context, ref, value),
    );
  }
}
