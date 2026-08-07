import '../../features/attacks/domain/enums/exertion_level.dart';
import '../../l10n/gen/app_localizations.dart';

/// Shared user-facing labels for [ExertionLevel]; used by the log flow's
/// exertion step and history so features don't import each other's
/// presentation layer.
extension ExertionLevelLabel on ExertionLevel {
  String label(AppLocalizations l10n) => switch (this) {
    ExertionLevel.none => l10n.exertionLevelNone,
    ExertionLevel.light => l10n.exertionLevelLight,
    ExertionLevel.moderate => l10n.exertionLevelModerate,
    ExertionLevel.severe => l10n.exertionLevelSevere,
  };
}
