import '../entities/daily_log.dart';
import '../enums/daily_factor.dart';

/// Reads and writes the one row a day the check-in keeps.
abstract interface class DailyLogRepository {
  /// The day's row, or null when nothing has been written for it yet.
  Future<DailyLog?> forDay(DateTime day);

  /// Every row from [from] to [to] inclusive, oldest first. Both bounds are local days.
  Future<List<DailyLog>> range(DateTime from, DateTime to);

  /// Emits the day's row on every write to the table, so the dashboard's prompt disappears the moment the check-in is saved.
  Stream<DailyLog?> watchDay(DateTime day);

  /// Writes the day's row, replacing whatever was there.
  Future<void> save(DailyLog log);

  /// Adds [factors] to [day]'s row, keeping every answer already on it.
  ///
  /// The attack's trigger chips call this: a trigger named on an attack is only
  /// gradeable once the same day-level factor exists, since `FactorMapEngine`
  /// compares a factor's attack rate against its own absence. Duplicates are
  /// dropped — a factor is on the day or it is not.
  Future<void> addFactorsToDay(DateTime day, List<DailyFactor> factors);

  /// How many days have an answered row. What the trigger map counts before it will render.
  Future<int> answeredCount();

  /// Drops every row (GDPR wipe).
  Future<void> deleteAll();
}
