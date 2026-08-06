import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../../weather/domain/entities/weather_snapshot.dart';
import '../../domain/entities/attack.dart';
import '../../domain/enums/exertion_level.dart';
import '../../domain/enums/head_location.dart';
import '../../domain/repositories/attack_repository.dart';

/// Drift-backed [AttackRepository]. Returns domain models, never Drift rows.
class DriftAttackRepository implements AttackRepository {
  const DriftAttackRepository(this._db);

  final AppDatabase _db;

  /// All attacks, newest first, with their weather snapshot when present.
  @override
  Stream<List<Attack>> watchAll() {
    final query = _db.select(_db.attacks).join([
      leftOuterJoin(
        _db.weatherSnapshots,
        _db.weatherSnapshots.attackId.equalsExp(_db.attacks.id),
      ),
    ])..orderBy([OrderingTerm.desc(_db.attacks.startedAt)]);

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

  @override
  Future<List<Attack>> getAll() async {
    final query = _db.select(_db.attacks).join([
      leftOuterJoin(
        _db.weatherSnapshots,
        _db.weatherSnapshots.attackId.equalsExp(_db.attacks.id),
      ),
    ])..orderBy([OrderingTerm.desc(_db.attacks.startedAt)]);

    final rows = await query.get();
    return rows
        .map(
          (row) => _toDomain(
            row.readTable(_db.attacks),
            row.readTableOrNull(_db.weatherSnapshots),
          ),
        )
        .toList();
  }

  @override
  Stream<Attack?> watchById(String id) {
    final query = _db.select(_db.attacks).join([
      leftOuterJoin(
        _db.weatherSnapshots,
        _db.weatherSnapshots.attackId.equalsExp(_db.attacks.id),
      ),
    ])..where(_db.attacks.id.equals(id));

    return query.watchSingleOrNull().map(
      (row) => row == null
          ? null
          : _toDomain(
              row.readTable(_db.attacks),
              row.readTableOrNull(_db.weatherSnapshots),
            ),
    );
  }

  /// Inserts the attack and, if already available, its weather snapshot.
  /// Works fully offline: [Attack.weather] may simply be null.
  @override
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
  @override
  Future<void> attachWeather(String attackId, WeatherSnapshot weather) {
    return _db
        .into(_db.weatherSnapshots)
        .insertOnConflictUpdate(_toWeatherRow(attackId, weather));
  }

  /// Attacks still waiting for a weather snapshot (offline backfill queue).
  @override
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

  @override
  Future<void> updateDetails(
    String id, {
    required List<String> symptoms,
    required List<String> triggers,
    String? notes,
    ExertionLevel? exertionLevel,
  }) async {
    await (_db.update(_db.attacks)..where((t) => t.id.equals(id))).write(
      AttacksCompanion(
        symptoms: Value(symptoms),
        triggers: Value(triggers),
        notes: Value(notes),
        exertionLevel: Value(exertionLevel),
      ),
    );
  }

  @override
  Future<void> updateCore(
    String id, {
    required int intensity,
    required HeadLocation location,
    String? medicationName,
  }) async {
    await (_db.update(_db.attacks)..where((t) => t.id.equals(id))).write(
      AttacksCompanion(
        intensity: Value(intensity),
        location: Value(location),
        medicationName: Value(medicationName),
      ),
    );
  }

  /// Weather snapshot goes with it via the FK cascade.
  @override
  Future<void> deleteById(String id) =>
      (_db.delete(_db.attacks)..where((t) => t.id.equals(id))).go();

  /// GDPR wipe. Weather snapshots go with their attacks via cascade.
  @override
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
    exertionLevel: row.exertionLevel,
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
    exertionLevel: Value(attack.exertionLevel),
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
