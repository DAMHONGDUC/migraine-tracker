import '../../features/insights/domain/entities/trigger_verdict.dart';
import '../../l10n/gen/app_localizations.dart';

/// Names a [TriggerFactor] with the word its own card already uses.
extension TriggerFactorLabel on TriggerFactor {
  String label(AppLocalizations l10n) => switch (this) {
    TriggerFactor.pressure => l10n.insightsPressureTitle,
    TriggerFactor.sleep => l10n.sleepCardTitle,
    TriggerFactor.steps => l10n.activityCardTitle,
  };
}
