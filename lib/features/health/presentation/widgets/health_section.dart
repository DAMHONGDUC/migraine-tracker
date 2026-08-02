import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/premium_gate.dart';
import '../../providers.dart';

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

      AppSnackBarUtils.error(context, context.l10n.healthConnectFailed);
    } catch (_) {
      // The controller already logged it; the user needs the outcome.
      if (context.mounted) {
        AppSnackBarUtils.error(context, context.l10n.healthConnectFailed);
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
      lockedMessage: context.l10n.premiumLockedSleep,
      child: SwitchListTile(
        secondary: const AppIcon(icon: Icons.bedtime_outlined),
        title: Text(
          context.l10n.healthSleepTitle,
          style: AppTextStyle.bodyLarge,
        ),
        subtitle: Text(
          connected
              ? context.l10n.healthSleepConnected
              : context.l10n.healthSleepSubtitle,
          style: AppTextStyle.bodyMedium.secondary,
        ),
        value: connected,
        onChanged: (bool value) => _toggle(context, ref, value),
      ),
    );
  }
}
