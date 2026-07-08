import 'package:drift/drift.dart';

import '../../domain/models/attack.dart';
import '../../domain/models/weather_snapshot.dart';
import '../db/app_database.dart';

/// All reads/writes for attacks. Returns domain models, never Drift rows.
class AttackRepository {
  const AttackRepository(this._db);

  final AppDatabase _db;

  /// All attacks, newest first, with their weather snapshot when present.
  Stream<List<Attack>> watchAll() {
    final query =
        _db.select(_db.attacks).join([
            leftOuterJoin(
              _db.weatherSnapshots,
              _db.weatherSnapshots.attackId.equalsExp(_db.attacks.id),
            ),
          ])
          ..orderBy([OrderingTerm.desc(_db.attacks.startedAt)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => _toDomain(
              row.readTable(_db.attacks),
              row.readTableOrNull(_db.weatherSnapshots),
            ),
          )
          .toList(),
    );
  }

  /// Inserts the attack and, if already available, its weather snapshot.
  /// Works fully offline: [Attack.weather] may simply be null.
  Future<void> insert(Attack attack) {
    return _db.transaction(() async {
      await _db.into(_db.attacks).insert(_toRow(attack));
      final weather = attack.weather;
      if (weather != null) {
        await _db
            .into(_db.weatherSnapshots)
            .insert(_toWeatherRow(attack.id, weather));
      }
    });
  }

  /// Backfills the weather snapshot for an attack logged offline.
  Future<void> attachWeather(String attackId, WeatherSnapshot weather) {
    return _db
        .into(_db.weatherSnapshots)
        .insertOnConflictUpdate(_toWeatherRow(attackId, weather));
  }

  /// Attacks still waiting for a weather snapshot (offline backfill queue).
  Future<List<Attack>> attacksMissingWeather() async {
    final query = _db.select(_db.attacks).join([
      leftOuterJoin(
        _db.weatherSnapshots,
        _db.weatherSnapshots.attackId.equalsExp(_db.attacks.id),
      ),
    ])..where(_db.weatherSnapshots.attackId.isNull());

    final rows = await query.get();
    return rows
        .map((row) => _toDomain(row.readTable(_db.attacks), null))
        .toList();
  }

  /// GDPR wipe. Weather snapshots go with their attacks via cascade.
  Future<void> deleteAll() => _db.delete(_db.attacks).go();

  Attack _toDomain(AttackRow row, WeatherSnapshotRow? weather) => Attack(
    id: row.id,
    startedAt: row.startedAt,
    intensity: row.intensity,
    location: row.location,
    medicationName: row.medicationName,
    symptoms: row.symptoms,
    triggers: row.triggers,
    notes: row.notes,
    weather: weather == null
        ? null
        : WeatherSnapshot(
            capturedAt: weather.capturedAt,
            pressureHpa: weather.pressureHpa,
            pressureDelta24hHpa: weather.pressureDelta24hHpa,
            humidityPercent: weather.humidityPercent,
            temperatureCelsius: weather.temperatureCelsius,
          ),
  );

  AttacksCompanion _toRow(Attack attack) => AttacksCompanion.insert(
    id: attack.id,
    startedAt: attack.startedAt,
    intensity: attack.intensity,
    location: attack.location,
    medicationName: Value(attack.medicationName),
    symptoms: Value(attack.symptoms),
    triggers: Value(attack.triggers),
    notes: Value(attack.notes),
  );

  WeatherSnapshotsCompanion _toWeatherRow(
    String attackId,
    WeatherSnapshot weather,
  ) => WeatherSnapshotsCompanion.insert(
    attackId: attackId,
    capturedAt: weather.capturedAt,
    pressureHpa: weather.pressureHpa,
    pressureDelta24hHpa: weather.pressureDelta24hHpa,
    humidityPercent: Value(weather.humidityPercent),
    temperatureCelsius: Value(weather.temperatureCelsius),
  );
}
