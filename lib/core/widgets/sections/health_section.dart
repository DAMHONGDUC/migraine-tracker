import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../core/theme/app_text_style.dart';
import '../../../features/health/providers.dart';
import '../../extensions/context_extensions.dart';
import '../premium_gate.dart';

/// The Apple Health row in Settings: one switch that connects the sleep
/// source. Absent off iOS, and locked for free users — the sleep insight it
/// feeds is premium, so connecting before there is anywhere to see the
/// result would just be a permission prompt for nothing.
class HealthSection extends ConsumerWidget {
  const HealthSection({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    try {
      final bool connected = await ref
          .read(healthControllerProvider.notifier)
          .setConnected(value);

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

    final bool connected = ref.watch(healthControllerProvider);

    return PremiumTileGate(
      icon: Icons.bedtime_outlined,
      title: context.l10n.healthSleepTitle,
      child: SwitchListTile(
        secondary: const SdIconV2(icon: Icons.bedtime_outlined),
        title: Text(
          context.l10n.healthSleepTitle,
          style: AppTextStyle.bodyLarge,
        ),
        value: connected,
        onChanged: (bool value) => _toggle(context, ref, value),
      ),
    );
  }
}
