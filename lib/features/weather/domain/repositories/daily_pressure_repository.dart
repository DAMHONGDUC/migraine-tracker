import '../entities/daily_pressure.dart';

/// Stores one pressure reading per day, on device only.
///
/// Never synced (hard rule 1): a per-day trail of the weather where the user
/// was is a location history, and every device can rebuild its own.
abstract interface class DailyPressureRepository {
  /// Readings from [from] onwards, oldest first.
  Future<List<DailyPressure>> since(DateTime from);

  /// Whether the given local day already has a reading — what stops the
  /// recorder fetching again on every app open.
  Future<bool> hasDay(DateTime day);

  /// Writes (or overwrites) one day's reading.
  Future<void> upsert(DailyPressure reading);

  /// GDPR wipe. Derived from the user's location, so it goes with everything
  /// else (hard rule 8).
  Future<void> deleteAll();
}
