import '../../../../core/db/app_database.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../domain/entities/daily_log.dart';

/// The one place a daily-log row becomes the domain model — the repository and the sync store both read rows.
final class DailyLogMapper {
  const DailyLogMapper._();

  static DailyLog toDomain(DailyLogRow row) => DailyLog(
    day: DateTimeUtils.dayFromKey(row.id),
    sleepQuality: row.sleepQuality,
    stressLevel: row.stressLevel,
    factors: row.factors,
    steps: row.steps,
  );
}
