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
        // No section heading: it said "Pressure-drop alerts" directly above a
        // row whose title said the same thing.
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
          child: _AlertRow(
            icon: Icons.notifications_active_outlined,
            title: l10n.alertsToggleTitle,
            trailing: Switch(
              value: settings.enabled,
              onChanged: ref.read(alertsControllerProvider.notifier).setEnabled,
            ),
          ),
        ),
        const SdDividerV2(),
        _AlertRow(
          icon: Icons.compress,
          title: l10n.alertsThresholdTitle,
          onTap: () => _pickThreshold(context, ref, threshold),
          // The value, then the chevron that says it can be changed. Without
          // the glyph the row reads as a readout, and nothing else on it
          // suggests a sheet is one tap away.
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                l10n.onboardingThresholdValue(threshold.round()),
                style: AppTextStyle.bodyMedium.secondary,
              ),
              SizedBox(width: SdSpacingConstant.w4),
              SdIconV2(
                icon: Icons.chevron_right,
                size: SdSpacingConstant.r20,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        SizedBox(height: SdSpacingConstant.h12),
        Text(
          l10n.weatherAlertActiveBody(
            l10n.onboardingThresholdValue(threshold.round()),
          ),
          style: AppTextStyle.bodySmall.secondary,
        ),
      ],
    );
  }
}

/// One alert setting: glyph and name on the left, whatever changes it on the
/// right.
///
/// Both rows share it so the switch and the threshold line up on the same two
/// edges — a `SwitchListTile` beside a `ListTile` put their titles at
/// different insets and their controls at different heights.
class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;

  /// Already localized.
  final String title;
  final Widget trailing;

  /// Null for a row whose control is the whole interaction — tapping the
  /// label of a switch row would be a second, invisible way to toggle it.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SdSpacingConstant.w8,
        vertical: SdSpacingConstant.h8,
      ),
      child: Row(
        children: <Widget>[
          SdIconV2(
            icon: icon,
            size: SdSpacingConstant.r20,
            color: context.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: SdSpacingConstant.w12),
          Expanded(
            child: Text(
              title,
              style: AppTextStyle.bodyLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: SdSpacingConstant.w8),
          trailing,
        ],
      ),
    );

    if (onTap == null) return row;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SdSpacingConstant.r12),
      child: row,
    );
  }
}
