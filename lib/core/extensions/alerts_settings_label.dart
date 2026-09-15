import '../../features/alerts/domain/entities/alerts_settings.dart';
import '../../l10n/gen/app_localizations.dart';

/// What the alerts row says without being opened: the state and, when there is
/// one to have, the number behind it.
///
/// Three rows used to carry this between them — a switch, a threshold tile and
/// the Settings row that led to both — so the phrasing lives here once instead
/// of being spelled out at each of them.
extension AlertsSettingsLabel on AlertsSettings {
  /// Off alone: a threshold nothing reads is not a state worth reporting.
  String summary(AppLocalizations l10n) => enabled
      ? l10n.alertsSummaryOn(
          l10n.onboardingThresholdValue(thresholdHpa.round()),
        )
      : l10n.alertsStatusOff;
}
