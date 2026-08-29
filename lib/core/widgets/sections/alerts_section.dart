import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../core/theme/app_text_style.dart';
import '../../../features/alerts/domain/enums/alert_registration_error.dart';
import '../../../features/alerts/providers.dart';
import '../../../features/premium/providers.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../extensions/context_extensions.dart';
import '../../theme/app_icon_constant.dart';
import '../alert_threshold_dialog.dart';
import '../premium_gate.dart';
import '../settings_tile.dart';

/// The alerts detail screen's body: enable switch + threshold.
class AlertsSection extends ConsumerWidget {
  const AlertsSection({super.key});

  String _errorMessage(AppLocalizations l10n, Object? error) => switch (error) {
    AlertRegistrationException(:final error) => switch (error) {
      AlertRegistrationError.accountRequired => l10n.alertsErrorAccount,
      AlertRegistrationError.notificationsDenied =>
        l10n.alertsErrorNotifications,
      AlertRegistrationError.locationUnavailable => l10n.alertsErrorLocation,
      AlertRegistrationError.pushUnavailable => l10n.alertsErrorPush,
      AlertRegistrationError.unknown => l10n.alertsErrorGeneric,
    },
    _ => l10n.alertsErrorGeneric,
  };

  Future<void> _pickThreshold(
    BuildContext context,
    WidgetRef ref,
    double current,
  ) async {
    final double? picked = await AlertThresholdDialog(
      initial: current,
      l10n: context.l10n,
    ).show(context);

    if (picked != null) {
      await ref.read(alertsControllerProvider.notifier).setThreshold(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    // Ahead of the settings read: without premium there is no control to fill in, so the alert state is none of this branch's business.
    if (!ref.watch(hasPremiumProvider)) {
      return PremiumTileGate(
        icon: AppIconConstant.reminderActive,
        title: l10n.alertsToggleTitle,
        // Never built for a free user — that is the gate, not the styling.
        child: const SizedBox.shrink(),
      );
    }

    ref.listen(alertsControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        SdSnackBarUtilsV2.error(context, _errorMessage(l10n, next.error));
      }
    });

    final settings = switch (ref.watch(alertsControllerProvider)) {
      AsyncData(value: final value) => value,
      AsyncError(:final value) => value,
      _ => null,
    };
    if (settings == null) return const SizedBox.shrink();

    return Column(
      children: [
        SwitchListTile(
          secondary: const SdIconV2(
            icon: AppIconConstant.reminderActive,
          ),
          title: Text(l10n.alertsToggleTitle, style: AppTextStyle.bodyLarge),
          value: settings.enabled,
          onChanged: ref.read(alertsControllerProvider.notifier).setEnabled,
        ),
        SettingsTile(
          icon: AppIconConstant.pressure,
          title: l10n.alertsThresholdTitle,
          value: l10n.onboardingThresholdValue(settings.thresholdHpa.round()),
          onTap: () => _pickThreshold(context, ref, settings.thresholdHpa),
        ),
      ],
    );
  }
}
