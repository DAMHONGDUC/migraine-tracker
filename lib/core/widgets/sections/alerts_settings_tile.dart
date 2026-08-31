import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/alerts/domain/entities/alerts_settings.dart';
import '../../../features/alerts/providers.dart';
import '../../extensions/alerts_settings_label.dart';
import '../../extensions/context_extensions.dart';
import '../../router/navigation_utils.dart';
import '../../theme/app_icon_constant.dart';
import '../premium_gate.dart';
import '../settings_tile.dart';

/// Settings row for everything pressure.
class AlertsSettingsTile extends ConsumerWidget {
  const AlertsSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AlertsSettings? settings = switch (ref.watch(
      alertsControllerProvider,
    )) {
      AsyncData(value: final AlertsSettings value) => value,
      AsyncError(:final AlertsSettings value) => value,
      _ => null,
    };

    return PremiumTileGate(
      icon: AppIconConstant.reminderActive,
      title: context.l10n.alertsToggleTitle,
      child: SettingsTile(
        icon: AppIconConstant.reminderActive,
        title: context.l10n.alertsToggleTitle,
        value: settings?.summary(context.l10n) ?? context.l10n.alertsStatusOff,
        onTap: () =>
            NavigationUtils.toPressure(context, ref, highlightAlert: true),
      ),
    );
  }
}
