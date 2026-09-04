import '../../features/insights/domain/entities/midas_score.dart';
import '../../l10n/gen/app_localizations.dart';

/// Shared user-facing labels for [MidasGrade]; the questionnaire screen and the export row both name a grade.
extension MidasGradeLabel on MidasGrade {
  String label(AppLocalizations l10n) => switch (this) {
    MidasGrade.littleOrNone => l10n.midasGradeLittleOrNone,
    MidasGrade.mild => l10n.midasGradeMild,
    MidasGrade.moderate => l10n.midasGradeModerate,
    MidasGrade.severe => l10n.midasGradeSevere,
  };
}
