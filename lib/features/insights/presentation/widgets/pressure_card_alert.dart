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
class _AlertControls extends ConsumerStatefulWidget {
  const _AlertControls();

  /// How long the row stays lit after being scrolled to. Long enough to find
  /// with the eye, short enough not to become part of the design.
  static const Duration highlightHold = Duration(milliseconds: 1800);

  @override
  ConsumerState<_AlertControls> createState() => _AlertControlsState();
}

class _AlertControlsState extends ConsumerState<_AlertControls> {
  /// Anchors `Scrollable.ensureVisible` on the switch row itself, not on the
  /// section — the section's top is already on screen when the card is.
  final GlobalKey _rowKey = GlobalKey();
  Timer? _fade;
  bool _lit = false;

  @override
  void dispose() {
    _fade?.cancel();
    super.dispose();
  }

  /// Consumes the pending request, scrolls the row up and lights it.
  ///
  /// Runs after the frame: it is triggered from `build`, and both the scroll
  /// and the provider write are things a build must not do while it is
  /// running.
  void _reveal() {
    if (!mounted) return;

    ref.read(pressureAlertHighlightProvider.notifier).consume();

    final BuildContext? row = _rowKey.currentContext;

    if (row != null) {
      Scrollable.ensureVisible(
        row,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        // Centred rather than merely on-screen: the row is the last thing on
        // a tall card, so "just visible" leaves it against the bottom edge.
        alignment: 0.5,
      );
    }

    setState(() => _lit = true);
    _fade?.cancel();
    _fade = Timer(_AlertControls.highlightHold, () {
      if (mounted) setState(() => _lit = false);
    });
  }

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
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    // Watched, not listened to: the request is usually set before this card
    // is built at all, so a listener would be subscribing to something that
    // has already fired.
    if (ref.watch(pressureAlertHighlightProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
    }

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
        // A tint that fades in and back out — calm, no flash (hard rule 3).
        AnimatedContainer(
          key: _rowKey,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _lit
                ? context.colorScheme.primary.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(SdSpacingConstant.r12),
          ),
          child: SwitchListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: SdSpacingConstant.w8,
            ),
            secondary: const SdIconV2(
              icon: Icons.notifications_active_outlined,
            ),
            title: Text(l10n.alertsToggleTitle, style: AppTextStyle.bodyLarge),
            value: settings.enabled,
            onChanged: ref.read(alertsControllerProvider.notifier).setEnabled,
          ),
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
