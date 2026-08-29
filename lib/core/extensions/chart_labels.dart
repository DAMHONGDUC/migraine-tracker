import '../../features/history/domain/services/chart_analytics.dart';
import '../../l10n/gen/app_localizations.dart';

/// User-facing labels for the History chart enums, kept out of the pure-Dart calculators (which stay Flutter/l10n free).
extension SeverityBandLabel on SeverityBand {
  String label(AppLocalizations l10n) => switch (this) {
    SeverityBand.mild => l10n.historySeverityMild,
    SeverityBand.moderate => l10n.historySeverityModerate,
    SeverityBand.severe => l10n.historySeveritySevere,
    SeverityBand.extreme => l10n.historySeverityExtreme,
  };
}

extension DayPartLabel on DayPart {
  String label(AppLocalizations l10n) => switch (this) {
    DayPart.night => l10n.historyDayNight,
    DayPart.morning => l10n.historyDayMorning,
    DayPart.afternoon => l10n.historyDayAfternoon,
    DayPart.evening => l10n.historyDayEvening,
  };
}
