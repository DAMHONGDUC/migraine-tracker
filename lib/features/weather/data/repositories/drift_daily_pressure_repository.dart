import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../domain/entities/daily_pressure.dart';
import '../../domain/repositories/daily_pressure_repository.dart';

/// Drift-backed [DailyPressureRepository].
class DriftDailyPressureRepository implements DailyPressureRepository {
  const DriftDailyPressureRepository(this._db);

  final AppDatabase _db;

  static DailyPressure _toDomain(DailyWeatherRow row) => DailyPressure(
    day: row.day,
    pressureHpa: row.pressureHpa,
    pressureDelta24hHpa: row.pressureDelta24hHpa,
  );

  @override
  Future<List<DailyPressure>> since(DateTime from) async {
    final DateTime start = DateTime(from.year, from.month, from.day);
    final List<DailyWeatherRow> rows =
        await (_db.select(_db.dailyWeather)
              ..where((t) => t.day.isBiggerOrEqualValue(start))
              ..orderBy([(t) => OrderingTerm.asc(t.day)]))
            .get();

    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<bool> hasDay(DateTime day) async {
    final DateTime midnight = DateTime(day.year, day.month, day.day);

    return await (_db.select(
          _db.dailyWeather,
        )..where((t) => t.day.equals(midnight))).getSingleOrNull() !=
        null;
  }

  @override
  Future<DailyPressure?> latest() async {
    final DailyWeatherRow? row =
        await (_db.select(_db.dailyWeather)
              ..orderBy([(t) => OrderingTerm.desc(t.day)])
              ..limit(1))
            .getSingleOrNull();

    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> upsert(DailyPressure reading) =>
      _db.into(_db.dailyWeather).insertOnConflictUpdate(
        DailyWeatherCompanion.insert(
          day: reading.day,
          capturedAt: DateTime.now().toUtc(),
          pressureHpa: reading.pressureHpa,
          pressureDelta24hHpa: reading.pressureDelta24hHpa,
        ),
      );

  @override
  Future<void> deleteAll() => _db.delete(_db.dailyWeather).go();
}
