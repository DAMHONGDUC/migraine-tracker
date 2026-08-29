import '../../features/insights/domain/entities/medication_effectiveness_result.dart';
import '../../l10n/gen/app_localizations.dart';
import 'duration_label.dart';

/// Renders a [MedicationEffectiveness] row as the strings two screens show.
extension MedicationEffectivenessLabel on MedicationEffectiveness {
  /// "Helped 2 of 3 times" while the sample is thin, "Relief 80% of the time" once it can carry a percentage.
  String reliefLabel(AppLocalizations l10n) => isCountOnly
      ? l10n.medicationEffectTally(helpedCount, answeredCount)
      : l10n.medicationEffectReliefShare(anyReliefPercent.round());

  /// What the attacks it was taken for looked like, or null when nothing was recorded to say.
  String? typicalLabel(AppLocalizations l10n) {
    final double? intensity = medianIntensity;
    final Duration? duration = medianDuration;
    final List<String> parts = <String>[
      if (intensity != null)
        l10n.medicationEffectTypicalIntensity(_intensityLabel(intensity)),
      if (duration != null)
        l10n.medicationEffectTypicalDuration(duration.label(l10n)),
    ];

    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// "6", not "6.0" — a median lands on a whole number half the time, and the trailing zero reads as precision the figure does not have.
  String _intensityLabel(double intensity) =>
      intensity == intensity.roundToDouble()
      ? intensity.toStringAsFixed(0)
      : intensity.toStringAsFixed(1);
}
