import '../entities/daily_log.dart';

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

  /// How many days have an answered row. What the trigger map counts before it will render.
  Future<int> answeredCount();

  /// Drops every row (GDPR wipe).
  Future<void> deleteAll();
}
