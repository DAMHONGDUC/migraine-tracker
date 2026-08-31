part of 'pressure_card.dart';

/// The pressure alert, set from the pressure card itself.
class _AlertControls extends ConsumerStatefulWidget {
  const _AlertControls();

  /// How long the row stays lit after being scrolled to. Long enough to find with the eye, short enough not to become part of the design.
  static const Duration highlightHold = Duration(milliseconds: 1800);

  @override
  ConsumerState<_AlertControls> createState() => _AlertControlsState();
}

class _AlertControlsState extends ConsumerState<_AlertControls> {
  /// Anchors `Scrollable.ensureVisible` on the switch row itself, not on the section — the section's top is already on screen when the card is.
  final GlobalKey _rowKey = GlobalKey();
  Timer? _fade;
  bool _lit = false;

  @override
  void dispose() {
    _fade?.cancel();
    super.dispose();
  }

  /// Consumes the pending request, scrolls the row up and lights it.
  void _reveal() {
    if (!mounted) return;

    ref.read(pressureAlertHighlightProvider.notifier).consume();

    final BuildContext? row = _rowKey.currentContext;

    if (row != null) {
      Scrollable.ensureVisible(
        row,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        // Centred rather than merely on-screen: the row is the last thing on a tall card, so "just visible" leaves it against the bottom edge.
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

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    AlertsSettings current,
  ) async {
    final AlertsSettings? picked = await AlertThresholdSheet(
      initial: current,
      l10n: context.l10n,
    ).show(context);

    if (picked == null) return;

    await ref.read(alertsControllerProvider.notifier).apply(picked);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    // Watched, not listened to: the request is usually set before this card is built at all, so a listener would be subscribing to something that has.
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
        // No section heading: it said "Pressure-drop alerts" directly above a row whose title said the same thing.
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
          // One row for both answers: the switch and the threshold row said the same thing twice, and the sheet behind this one now owns them together.
          child: _AlertRow(
            icon: AppIconConstant.reminderActive,
            title: l10n.alertsToggleTitle,
            onTap: () => _edit(context, ref, settings),
            // The state and its number as a tag — coloured by the threshold, so the row says how sensitive the alert is before it is read.
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AlertSummaryTag(settings: settings),
                SizedBox(width: SdSpacingConstant.w4),
                SdIconV2(
                  icon: AppIconConstant.disclosure,
                  size: AppIconSize.small,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: SdSpacingConstant.h12),
        Text(
          // Only while it is actually on: read under an off switch it describes something that is not happening.
          settings.enabled
              ? l10n.weatherAlertActiveBody(
                  l10n.onboardingThresholdValue(threshold.round()),
                )
              : l10n.weatherAlertLockedBody,
          style: AppTextStyle.bodySmall.secondary,
        ),
      ],
    );
  }
}

/// The alert setting: glyph and name on the left, where it stands on the right.
class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;

  /// Already localized.
  final String title;
  final Widget trailing;

  /// The whole row opens the sheet — there is no control inside it to fight over the tap.
  final VoidCallback onTap;

  /// Fixed, so the highlight the doors ask for lands on a row of a known height whatever it holds.
  static double get height => SdSpacingConstant.h44;

  @override
  Widget build(BuildContext context) {
    // ConstrainedBox, not a Container with an `alignment`: that one sizes through Align, whose height under an unbounded parent depends on its child.
    final Widget row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: SdSpacingConstant.w8),
        child: Row(
          children: <Widget>[
            SdIconV2(
              icon: icon,
              size: AppIconSize.medium,
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
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SdSpacingConstant.r12),
      child: row,
    );
  }
}
