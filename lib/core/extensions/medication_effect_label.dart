import '../../features/attacks/domain/enums/medication_effect.dart';
import '../../l10n/gen/app_localizations.dart';

/// Shared user-facing labels for [MedicationEffect], so the attack detail screen, the picker and the medications tab cannot word the same answer three.
extension MedicationEffectLabel on MedicationEffect {
  String label(AppLocalizations l10n) => switch (this) {
    MedicationEffect.helped => l10n.medicationEffectHelped,
    MedicationEffect.partly => l10n.medicationEffectPartly,
    MedicationEffect.didNotHelp => l10n.medicationEffectDidNotHelp,
  };
}
