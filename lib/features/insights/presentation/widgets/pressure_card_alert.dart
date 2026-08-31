part of 'pressure_card.dart';

/// The pressure alert, set from the pressure card itself.
///
/// It used to scroll itself into view and light up when a door elsewhere asked
/// for it. Those doors open the sheet directly now, so the row is only ever a
/// row: nothing to reveal, nothing to consume, no timer to cancel.
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

    final double threshold = settings.thresholdHpa;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // No section heading: it said "Pressure-drop alerts" directly above a row whose title said the same thing.
        // One row for both answers: the switch and the threshold row said the same thing twice, and the sheet behind this one now owns them together.
        _AlertRow(
          icon: AppIconConstant.reminderActive,
          title: l10n.alertsToggleTitle,
          onTap: () => AlertThresholdEditor.open(context, ref),
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

  /// Fixed, so the row keeps its height whatever it holds.
  static double get height => SdSpacingConstant.h44;

  @override
  Widget build(BuildContext context) {
    // ConstrainedBox, not a Container with an `alignment`: that one sizes through Align, whose height under an unbounded parent depends on its child.
    final Widget row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
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
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SdSpacingConstant.r12),
      child: row,
    );
  }
}
