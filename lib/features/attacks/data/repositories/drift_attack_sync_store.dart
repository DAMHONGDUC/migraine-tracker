import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../../sync/data/repositories/drift_sync_local_store.dart';
import '../../../sync/domain/entities/sync_collection.dart';
import '../../../sync/domain/entities/sync_record.dart';
import '../../domain/entities/attack.dart';
import 'attack_mapper.dart';

/// The attacks side of sync. Everything shared lives in the base class.
class DriftAttackSyncStore extends DriftSyncLocalStore<Attack> {
  const DriftAttackSyncStore(super.db);

  @override
  SyncCollection get collection => SyncCollection.attacks;

  @override
  String idOf(Attack value) => value.id;

  @override
  Future<List<SyncRecord<Attack>>> loadDirty() async {
    final query = db.select(db.attacks).join([
      leftOuterJoin(
        db.weatherSnapshots,
        db.weatherSnapshots.attackId.equalsExp(db.attacks.id),
      ),
    ])..where(
      db.attacks.syncedRevision.isNull() |
          db.attacks.syncedRevision.isNotExp(db.attacks.revision),
    );

    final rows = await query.get();
    return rows.map((row) {
      final AttackRow attack = row.readTable(db.attacks);

      return SyncRecord<Attack>(
        id: attack.id,
        updatedAt: _effectiveUpdatedAt(attack),
        revision: attack.revision,
        value: AttackMapper.toDomain(
          attack,
          row.readTableOrNull(db.weatherSnapshots),
        ),
      );
    }).toList();
  }

  @override
  Future<DateTime?> localUpdatedAt(String id) async {
    final AttackRow? row = await _row(id);

    return row == null ? null : _effectiveUpdatedAt(row);
  }

  @override
  Future<int> nextRevision(String id) async => ((await _row(id))?.revision ?? 0) + 1;

  @override
  Future<bool> writeFromRemote(
    Attack value,
    DateTime updatedAt,
    int revision,
  ) async {
    // Same revision both sides: it arrived from the server, so it is in step
    // the moment it lands and must not push straight back.
    await db
        .into(db.attacks)
        .insertOnConflictUpdate(
          AttackMapper.toRow(
            value,
            updatedAt: updatedAt,
            revision: revision,
            syncedRevision: revision,
          ),
        );
    final weather = value.weather;
    if (weather != null) {
      await db
          .into(db.weatherSnapshots)
          .insertOnConflictUpdate(AttackMapper.toWeatherRow(value.id, weather));
    }
    return true;
  }

  @override
  Future<void> deleteRow(String id) =>
      (db.delete(db.attacks)..where((t) => t.id.equals(id))).go();

  @override
  Future<void> writeSyncedRevision(String id, int revision) async {
    // Guarded on the revision that was actually sent: an edit landing
    // mid-push has already bumped it, so that row stays dirty rather than
    // being marked clean and never uploaded.
    await (db.update(db.attacks)
          ..where((t) => t.id.equals(id) & t.revision.equals(revision)))
        .write(AttacksCompanion(syncedRevision: Value(revision)));
  }

  Future<AttackRow?> _row(String id) =>
      (db.select(db.attacks)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Rows logged before v6 have no `updatedAt`; their own start time is the
  /// best "last modified" available, and beats inventing the upgrade's clock.
  DateTime _effectiveUpdatedAt(AttackRow row) =>
      (row.updatedAt ?? row.startedAt).toUtc();
}
