import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../../sync/data/repositories/drift_sync_local_store.dart';
import '../../../sync/domain/entities/sync_collection.dart';
import '../../../weather/domain/entities/weather_snapshot.dart';
import '../../domain/entities/attack.dart';
import '../../domain/enums/aura_type.dart';
import '../../domain/enums/exertion_level.dart';
import '../../domain/enums/head_region.dart';
import '../../domain/enums/medication_effect.dart';
import '../../domain/repositories/attack_repository.dart';
import 'attack_mapper.dart';

/// Drift-backed [AttackRepository].
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
      (rows) => rows.map(_rowToDomain).toList(),
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
    return rows.map(_rowToDomain).toList();
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
      (row) => row == null ? null : _rowToDomain(row),
    );
  }

  /// Inserts the attack and, if already available, its weather snapshot. Works fully offline: [Attack.weather] may simply be null.
  @override
  Future<void> insert(Attack attack) {
    return _db.transaction(() async {
      await _db
          .into(_db.attacks)
          .insert(
            AttackMapper.toRow(
              attack,
              updatedAt: DateTime.now().toUtc(),
              revision: 1,
            ),
          );
      // A re-used id would otherwise be deleted again by its stale tombstone.
      await SyncTombstoneWriter.clear(_db, SyncCollection.attacks, [attack.id]);
      final weather = attack.weather;
      if (weather != null) {
        await _db
            .into(_db.weatherSnapshots)
            .insert(AttackMapper.toWeatherRow(attack.id, weather));
      }
    });
  }

  /// Backfills the weather snapshot for an attack logged offline.
  @override
  Future<void> attachWeather(String attackId, WeatherSnapshot weather) {
    return _db.transaction(() async {
      await _db
          .into(_db.weatherSnapshots)
          .insertOnConflictUpdate(AttackMapper.toWeatherRow(attackId, weather));
      await _touch(attackId);
    });
  }

  @override
  Future<void> attachSteps(String attackId, int steps) {
    return _db.transaction(() async {
      await (_db.update(_db.attacks)..where((t) => t.id.equals(attackId)))
          .write(AttacksCompanion(steps: Value(steps)));
      await _touch(attackId);
    });
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
        .map((row) => AttackMapper.toDomain(row.readTable(_db.attacks), null))
        .toList();
  }

  @override
  Future<void> updateDetails(
    String id, {
    required List<String> symptoms,
    required List<String> triggers,
    String? notes,
  }) {
    return _db.transaction(() async {
      await (_db.update(_db.attacks)..where((t) => t.id.equals(id))).write(
        AttacksCompanion(
          symptoms: Value(symptoms),
          triggers: Value(triggers),
          notes: Value(notes),
          updatedAt: Value(DateTime.now().toUtc()),
          revision: Value(await _nextRevision(id)),
        ),
      );
    });
  }

  @override
  Future<void> updateExertion(String id, ExertionLevel? exertionLevel) {
    return _db.transaction(() async {
      await (_db.update(_db.attacks)..where((t) => t.id.equals(id))).write(
        AttacksCompanion(
          exertionLevel: Value(exertionLevel),
          updatedAt: Value(DateTime.now().toUtc()),
          revision: Value(await _nextRevision(id)),
        ),
      );
    });
  }

  @override
  Future<void> updateEndedAt(String id, DateTime? endedAt) {
    return _db.transaction(() async {
      await (_db.update(_db.attacks)..where((t) => t.id.equals(id))).write(
        AttacksCompanion(
          endedAt: Value(endedAt?.toUtc()),
          updatedAt: Value(DateTime.now().toUtc()),
          revision: Value(await _nextRevision(id)),
        ),
      );
    });
  }

  @override
  Future<void> updateMedicationEffect(String id, MedicationEffect? effect) {
    return _db.transaction(() async {
      await (_db.update(_db.attacks)..where((t) => t.id.equals(id))).write(
        AttacksCompanion(
          medicationEffect: Value(effect),
          updatedAt: Value(DateTime.now().toUtc()),
          revision: Value(await _nextRevision(id)),
        ),
      );
    });
  }

  @override
  Future<void> updateAura(String id, List<AuraType>? aura) {
    return _db.transaction(() async {
      await (_db.update(_db.attacks)..where((t) => t.id.equals(id))).write(
        AttacksCompanion(
          aura: Value(aura),
          updatedAt: Value(DateTime.now().toUtc()),
          revision: Value(await _nextRevision(id)),
        ),
      );
    });
  }

  @override
  Future<void> updateMedicationTiming(
    String id, {
    required DateTime? takenAt,
    required DateTime? reliefAt,
  }) {
    return _db.transaction(() async {
      await (_db.update(_db.attacks)..where((t) => t.id.equals(id))).write(
        AttacksCompanion(
          medicationTakenAt: Value(takenAt?.toUtc()),
          reliefAt: Value(reliefAt?.toUtc()),
          updatedAt: Value(DateTime.now().toUtc()),
          revision: Value(await _nextRevision(id)),
        ),
      );
    });
  }

  @override
  Future<void> updateCore(
    String id, {
    required int intensity,
    required List<HeadRegion> regions,
    String? medicationName,
  }) {
    return _db.transaction(() async {
      await (_db.update(_db.attacks)..where((t) => t.id.equals(id))).write(
        AttacksCompanion(
          intensity: Value(intensity),
          regions: Value(regions),
          medicationName: Value(medicationName),
          updatedAt: Value(DateTime.now().toUtc()),
          revision: Value(await _nextRevision(id)),
        ),
      );
    });
  }

  /// Deletes the attack outright — no soft-delete, so nothing about it outlives the tap — and leaves a tombstone holding only its id, so the deletion.
  @override
  Future<void> deleteById(String id) {
    return _db.transaction(() async {
      await (_db.delete(_db.attacks)..where((t) => t.id.equals(id))).go();
      await SyncTombstoneWriter.write(_db, SyncCollection.attacks, [id]);
    });
  }

  /// GDPR wipe.
  @override
  Future<void> deleteAll() {
    return _db.transaction(() async {
      await _db.delete(_db.attacks).go();
      await SyncTombstoneWriter.clearAll(_db, SyncCollection.attacks);
    });
  }

  Future<void> _touch(String id) async =>
      (_db.update(_db.attacks)..where((t) => t.id.equals(id))).write(
        AttacksCompanion(
          updatedAt: Value(DateTime.now().toUtc()),
          revision: Value(await _nextRevision(id)),
        ),
      );

  /// Read-modify-write, so callers must already be in a transaction.
  Future<int> _nextRevision(String id) async {
    final AttackRow? row = await (_db.select(
      _db.attacks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    return (row?.revision ?? 0) + 1;
  }

  Attack _rowToDomain(TypedResult row) => AttackMapper.toDomain(
    row.readTable(_db.attacks),
    row.readTableOrNull(_db.weatherSnapshots),
  );
}
