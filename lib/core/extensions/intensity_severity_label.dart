import '../../l10n/gen/app_localizations.dart';

/// Severity word for a 1–10 pain intensity, used in accessibility labels so the severity is never conveyed by colour alone (the visual ramp lives in.
extension IntensitySeverityLabel on int {
  String severityLabel(AppLocalizations l10n) {
    if (this <= 3) return l10n.severityMild;
    if (this <= 6) return l10n.severityModerate;
    if (this <= 8) return l10n.severitySevere;
    return l10n.severityExtreme;
  }
}
