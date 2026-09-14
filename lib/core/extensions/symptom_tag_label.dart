import '../../features/attacks/domain/enums/symptom_tag.dart';
import '../../features/daily_log/domain/enums/daily_factor.dart';
import '../../l10n/gen/app_localizations.dart';
import '../utils/comma_list_utils.dart';
import 'daily_factor_label.dart';

/// Shared user-facing labels for [SymptomTag] — the details sheet picks them, the detail screen and History's filter read them back.
extension SymptomTagLabel on SymptomTag {
  String label(AppLocalizations l10n) => switch (this) {
    SymptomTag.nausea => l10n.symptomNausea,
    SymptomTag.vomiting => l10n.symptomVomiting,
    SymptomTag.lightSensitivity => l10n.symptomLightSensitivity,
    SymptomTag.soundSensitivity => l10n.symptomSoundSensitivity,
    SymptomTag.smellSensitivity => l10n.symptomSmellSensitivity,
    SymptomTag.dizziness => l10n.symptomDizziness,
    SymptomTag.neckPain => l10n.symptomNeckPain,
    SymptomTag.blurredVision => l10n.symptomBlurredVision,
  };
}

/// One owner for turning a stored symptom or trigger string into something a screen can print.
///
/// The columns hold two kinds of value since the chips arrived: a tag's id, and
/// whatever the user typed into the "other" field. A screen must print the
/// first in the reader's language and the second exactly as typed, and doing
/// that in two places is how a screen comes to show `lightSensitivity`.
extension StoredTagLabel on String {
  /// A known symptom id becomes its localized label; anything else is the user's own word, returned as it was typed.
  String symptomLabel(AppLocalizations l10n) =>
      SymptomTag.tryParse(this)?.label(l10n) ?? this;

  /// The same for a trigger, whose ids are `DailyFactor` names — that shared vocabulary is what makes a trigger gradeable.
  String triggerLabel(AppLocalizations l10n) =>
      DailyFactor.tryParse(this)?.label(l10n) ?? this;
}

/// The sentence form of a whole column, for a detail row or a history card.
extension StoredTagListLabel on List<String> {
  String symptomsLabel(AppLocalizations l10n) =>
      map((String s) => s.symptomLabel(l10n)).join(CommaListUtils.separator);

  String triggersLabel(AppLocalizations l10n) =>
      map((String s) => s.triggerLabel(l10n)).join(CommaListUtils.separator);
}
