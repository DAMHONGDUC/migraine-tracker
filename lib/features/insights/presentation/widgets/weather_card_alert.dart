part of 'weather_card.dart';

/// The pressure alert, set from the card itself.
///
/// **The one premium thing on this card.** With premium the switch and the
/// threshold are both live here — that is the whole point of moving them onto
/// the card, so the number and the alert it drives are read in one place.
/// Without it the same two rows are shown inert, under a pitch: a locked
/// control that still says what it would do sells better than a blank space,
/// and it is the surface announcing itself as premium, so the tap goes
/// straight to the paywall with no [RecordLimitDialog] in front.
class _AlertControls extends ConsumerWidget {
  const _AlertControls();

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

    if (picked == null) return;

    await ref.read(alertsControllerProvider.notifier).setThreshold(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    ref.listen(alertsControllerProvider, (_, AsyncValue<AlertsSettings> next) {
      if (next.hasError && !next.isLoading) {
        SdSnackBarUtilsV2.error(context, _errorMessage(l10n, next.error));
      }
    });

    final AlertsSettings? settings = switch (ref.watch(
      alertsControllerProvider,
    )) {
      AsyncData(value: final AlertsSettings value) => value,
      AsyncError(value: final AlertsSettings? value) => value,
      _ => null,
    };

    if (settings == null) return const SizedBox.shrink();

    final bool hasPremium = ref.watch(hasPremiumProvider);
    final double threshold = settings.thresholdHpa;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.alertsToggleTitle,
                style: AppTextStyle.titleMedium,
              ),
            ),
            if (!hasPremium) const PremiumBadge(),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h4),
        Text(
          hasPremium
              ? l10n.weatherAlertActiveBody(
                  l10n.onboardingThresholdValue(threshold.round()),
                )
              : l10n.weatherAlertLockedBody,
          style: AppTextStyle.bodySmall.secondary,
        ),
        SizedBox(height: SdSpacingConstant.h12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: SdIconV2(
            icon: hasPremium
                ? Icons.notifications_active_outlined
                : Icons.lock_outline,
          ),
          title: Text(l10n.alertsToggleTitle, style: AppTextStyle.bodyLarge),
          // Never on without premium, whatever a stale setting says.
          value: hasPremium && settings.enabled == true,
          // The chain, enforced where the user meets it: alerts need premium,
          // premium needs an account, and the paywall asks for the account
          // itself — so a free user goes there, not to a login screen for
          // something they have not been offered yet.
          onChanged: (bool value) => hasPremium
              ? ref.read(alertsControllerProvider.notifier).setEnabled(value)
              : NavigationUtils.toPaywall(context, ref),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: SdIconV2(
            icon: hasPremium ? Icons.compress : Icons.lock_outline,
          ),
          title: Text(
            l10n.alertsThresholdTitle,
            style: AppTextStyle.bodyLarge,
          ),
          trailing: Text(
            l10n.onboardingThresholdValue(threshold.round()),
            style: AppTextStyle.bodyMedium.secondary,
          ),
          onTap: () => hasPremium
              ? _pickThreshold(context, ref, threshold)
              : NavigationUtils.toPaywall(context, ref),
        ),
      ],
    );
  }
}
