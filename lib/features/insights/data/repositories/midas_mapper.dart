import '../../../../core/db/app_database.dart';
import '../../domain/entities/midas_score.dart';

/// The one place a MIDAS row becomes the domain model — the repository and the sync store both read rows.
final class MidasMapper {
  const MidasMapper._();

  static MidasEntry toDomain(MidasRow row) => MidasEntry(
    id: row.id,
    takenAt: row.takenAt,
    missedWorkDays: row.missedWorkDays,
    reducedWorkDays: row.reducedWorkDays,
    missedHouseholdDays: row.missedHouseholdDays,
    reducedHouseholdDays: row.reducedHouseholdDays,
    missedSocialDays: row.missedSocialDays,
  );
}
