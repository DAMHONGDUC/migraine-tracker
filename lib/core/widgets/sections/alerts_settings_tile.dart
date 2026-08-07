import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/alerts/domain/entities/alerts_settings.dart';
import '../../../features/alerts/providers.dart';
import '../../extensions/context_extensions.dart';
import '../../router/app_router.dart';
import '../premium_gate.dart';
import '../settings_tile.dart';

/// Settings row for everything pressure: says whether alerts are On/Off and
/// opens `PressureScreen`, where the forecast and the correlation sit beside
/// the switch + threshold. Premium-gated as a whole — a free user gets the
/// locked tile, never the state or the way in.
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
      icon: Icons.notifications_active_outlined,
      title: context.l10n.alertsToggleTitle,
      child: SettingsTile(
        icon: Icons.notifications_active_outlined,
        title: context.l10n.alertsToggleTitle,
        value: (settings?.enabled ?? false)
            ? context.l10n.alertsStatusOn
            : context.l10n.alertsStatusOff,
        onTap: () => context.pushNamed(AppRoutes.pressure.name),
      ),
    );
  }
}
