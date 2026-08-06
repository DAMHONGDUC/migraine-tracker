import '../../l10n/gen/app_localizations.dart';

/// "8,234 steps" — kept as a shared extension (see `DurationLabel`) so any
/// future step-count surface formats the same way.
extension StepCountLabel on num {
  String label(AppLocalizations l10n) => l10n.commonStepsCount(round());
}
