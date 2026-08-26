import '../../features/attacks/domain/enums/aura_type.dart';
import '../../l10n/gen/app_localizations.dart';
import '../utils/comma_list_utils.dart';

extension AuraLabel on AuraType {
  String label(AppLocalizations l10n) => switch (this) {
    AuraType.visual => l10n.auraVisual,
    AuraType.sensory => l10n.auraSensory,
    AuraType.speech => l10n.auraSpeech,
    AuraType.motor => l10n.auraMotor,
  };
}

/// The whole answer as one line, including the two ways of having none.
///
/// Null and empty are different sentences and must stay that way: "not
/// recorded" is a question nobody put, "no aura" is the user's answer, and
/// migraine with aura and without it are different diagnoses.
extension AuraListLabel on List<AuraType>? {
  String label(AppLocalizations l10n) {
    final List<AuraType>? aura = this;

    if (aura == null) return l10n.auraNotRecorded;
    if (aura.isEmpty) return l10n.auraNone;

    return CommaListUtils.join(<String>[
      for (final AuraType type in aura) type.label(l10n),
    ]);
  }
}
