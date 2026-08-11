part of 'pressure_card.dart';

/// The pressure alert, set from the pressure card itself.
///
/// **It lives with the forecast it acts on.** It sat on the weather card
/// first, which put the threshold next to readings it has nothing to do with;
/// pressure is its subject, so it belongs under the pressure line. There is
/// no detail screen behind it any more — this IS where alerts are set.
///
/// **Without premium neither control is built at all** (owner's call). They
/// were shown inert first, on the theory that a locked control still says
/// what it would do; a switch that will not switch and a threshold that will
/// not open read as a broken card rather than as an offer. A free user gets
/// the pitch and one Unlock button, which is the same shape `PremiumGate`
/// uses everywhere else — and the same rule holds, that the locked branch
/// never builds the premium branch.
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

    // Before the settings are even read: without premium there is no control
    // to fill in, so the alert state is none of this branch's business.
    if (!ref.watch(hasPremiumProvider)) return const _AlertPitch();

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

    final double threshold = settings.thresholdHpa;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l10n.alertsToggleTitle, style: AppTextStyle.titleMedium),
        SizedBox(height: SdSpacingConstant.h4),
        Text(
          l10n.weatherAlertActiveBody(
            l10n.onboardingThresholdValue(threshold.round()),
          ),
          style: AppTextStyle.bodySmall.secondary,
        ),
        SizedBox(height: SdSpacingConstant.h12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const SdIconV2(
            icon: Icons.notifications_active_outlined,
          ),
          title: Text(l10n.alertsToggleTitle, style: AppTextStyle.bodyLarge),
          value: settings.enabled,
          onChanged: ref.read(alertsControllerProvider.notifier).setEnabled,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const SdIconV2(icon: Icons.compress),
          title: Text(
            l10n.alertsThresholdTitle,
            style: AppTextStyle.bodyLarge,
          ),
          trailing: Text(
            l10n.onboardingThresholdValue(threshold.round()),
            style: AppTextStyle.bodyMedium.secondary,
          ),
          onTap: () => _pickThreshold(context, ref, threshold),
        ),
      ],
    );
  }
}

/// What a free user gets in place of the two controls: what the alert would
/// do, and the one way to get it.
///
/// No switch and no threshold row — see [_AlertControls]. The badge marks it
/// as premium, so this goes straight to the paywall with no
/// `RecordLimitDialog` in front: there is no record limit here to name.
class _AlertPitch extends ConsumerWidget {
  const _AlertPitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

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
            const PremiumBadge(),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h4),
        Text(
          l10n.weatherAlertLockedBody,
          style: AppTextStyle.bodySmall.secondary,
        ),
        SizedBox(height: SdSpacingConstant.h12),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SdButtonV2(
            variant: SdButtonVariantV2.secondary,
            size: SdButtonSizeV2.small,
            icon: Icons.lock_open_outlined,
            onPressed: () => NavigationUtils.toPaywall(context, ref),
            label: l10n.premiumUnlock,
          ),
        ),
      ],
    );
  }
}
