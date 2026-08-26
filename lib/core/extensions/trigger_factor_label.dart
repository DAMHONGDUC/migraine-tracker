import '../../features/insights/domain/entities/trigger_verdict.dart';
import '../../l10n/gen/app_localizations.dart';

/// Names a [TriggerFactor] with the word its own card already uses.
///
/// Reusing the card titles rather than minting three new keys is the point:
/// the verdict points the user at a card, and a verdict calling it "Activity"
/// while the tab says something else sends them looking for a screen that is
/// not there.
extension TriggerFactorLabel on TriggerFactor {
  String label(AppLocalizations l10n) => switch (this) {
    TriggerFactor.pressure => l10n.insightsPressureTitle,
    TriggerFactor.sleep => l10n.sleepCardTitle,
    TriggerFactor.steps => l10n.activityCardTitle,
  };
}
