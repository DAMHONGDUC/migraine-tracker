import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../core/theme/app_text_style.dart';
import '../../../features/alerts/domain/enums/alert_registration_error.dart';
import '../../../features/alerts/providers.dart';
import '../../../features/premium/providers.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../extensions/context_extensions.dart';
import '../../router/navigation_utils.dart';
import '../alert_threshold_dialog.dart';
import '../settings_tile.dart';

/// The alerts detail screen's body: enable switch + threshold. Pushed from
/// the Settings row (`AlertsSettingsTile`), which only shows On/Off.
/// Registration errors surface as snackbars here.
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

    final bool hasPremium = ref.watch(hasPremiumProvider);

    return Column(
      children: [
        SwitchListTile(
          secondary: SdIconV2(
            icon: hasPremium
                ? Icons.notifications_active_outlined
                : Icons.lock_outline,
          ),
          title: Text(l10n.alertsToggleTitle, style: AppTextStyle.bodyLarge),
          // Never on without premium, whatever a stale setting says.
          value: hasPremium && settings.enabled,
          // The chain, enforced where the user meets it: alerts need premium,
          // premium needs an account. The paywall asks for the account itself,
          // so a free user goes there rather than to a login screen for
          // something they have not been offered yet.
          onChanged: (value) => hasPremium
              ? ref.read(alertsControllerProvider.notifier).setEnabled(value)
              : NavigationUtils.toPaywall(context, ref),
        ),
        SettingsTile(
          icon: Icons.compress,
          title: l10n.alertsThresholdTitle,
          value: l10n.onboardingThresholdValue(settings.thresholdHpa.round()),
          onTap: () => _pickThreshold(context, ref, settings.thresholdHpa),
        ),
      ],
    );
  }
}
