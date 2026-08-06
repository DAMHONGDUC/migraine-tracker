import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../domain/entities/attack.dart';
import '../../domain/entities/attack_sync_record.dart';
import '../../domain/repositories/attack_sync_repository.dart';
import 'attack_mapper.dart';

/// Drift-backed [AttackSyncRepository].
class DriftAttackSyncRepository implements AttackSyncRepository {
  const DriftAttackSyncRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<AttackSyncRecord>> pendingChanges() async {
    final List<AttackSyncRecord> records = <AttackSyncRecord>[
      ...await _dirtyAttacks(),
      ...await _tombstones(),
    ];

    // Id breaks the tie: dates are stored to the second, so two changes made
    // in the same one would otherwise come out in an arbitrary order.
    records.sort((a, b) {
      final int byTime = a.updatedAt.compareTo(b.updatedAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    return records;
  }

  @override
  Future<void> markSynced(String id, int revision) async {
    // Guarded on the revision that was actually sent: an edit landing
    // mid-push has already bumped it, so that row stays dirty rather than
    // being marked clean and never uploaded.
    await (_db.update(_db.attacks)
          ..where((t) => t.id.equals(id) & t.revision.equals(revision)))
        .write(AttacksCompanion(syncedRevision: Value(revision)));
  }

  @override
  Future<void> clearTombstone(String id) =>
      (_db.delete(_db.attackTombstones)..where((t) => t.id.equals(id))).go();

  @override
  Future<bool> applyRemote(Attack attack, DateTime updatedAt) {
    return _db.transaction(() async {
      if (await _localIsNewer(attack.id, updatedAt)) return false;

      final int revision = await _nextRevision(attack.id);

      // Same revision both sides: it arrived from the server, so it is in
      // step the moment it lands and must not push straight back.
      await _db
          .into(_db.attacks)
          .insertOnConflictUpdate(
            AttackMapper.toRow(
              attack,
              updatedAt: updatedAt,
              revision: revision,
              syncedRevision: revision,
            ),
          );
      final weather = attack.weather;
      if (weather != null) {
        await _db
            .into(_db.weatherSnapshots)
            .insertOnConflictUpdate(
              AttackMapper.toWeatherRow(attack.id, weather),
            );
      }
      return true;
    });
  }

  @override
  Future<bool> applyRemoteDeletion(String id, DateTime deletedAt) {
    return _db.transaction(() async {
      if (await _localIsNewer(id, deletedAt)) return false;

      await (_db.delete(_db.attacks)..where((t) => t.id.equals(id))).go();
      // No tombstone: the server is the one telling us, so it already knows.
      await (_db.delete(
        _db.attackTombstones,
      )..where((t) => t.id.equals(id))).go();
      return true;
    });
  }

  /// Ties go to the server so two devices converge on the same answer instead
  /// of each preferring its own.
  Future<bool> _localIsNewer(String id, DateTime remote) async {
    final AttackRow? row = await (_db.select(
      _db.attacks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (row == null) return false;
    return _effectiveUpdatedAt(row).isAfter(remote);
  }

  Future<int> _nextRevision(String id) async {
    final AttackRow? row = await (_db.select(
      _db.attacks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    return (row?.revision ?? 0) + 1;
  }

  Future<List<AttackSyncRecord>> _dirtyAttacks() async {
    final query = _db.select(_db.attacks).join([
      leftOuterJoin(
        _db.weatherSnapshots,
        _db.weatherSnapshots.attackId.equalsExp(_db.attacks.id),
      ),
    ])..where(
      _db.attacks.syncedRevision.isNull() |
          _db.attacks.syncedRevision.isNotExp(_db.attacks.revision),
    );

    final rows = await query.get();
    return rows.map((row) {
      final AttackRow attackRow = row.readTable(_db.attacks);

      return AttackSyncRecord(
        id: attackRow.id,
        updatedAt: _effectiveUpdatedAt(attackRow),
        revision: attackRow.revision,
        attack: AttackMapper.toDomain(
          attackRow,
          row.readTableOrNull(_db.weatherSnapshots),
        ),
      );
    }).toList();
  }

  Future<List<AttackSyncRecord>> _tombstones() async {
    final List<AttackTombstoneRow> rows = await _db
        .select(_db.attackTombstones)
        .get();

    return rows
        .map(
          (row) => AttackSyncRecord(
            id: row.id,
            updatedAt: row.deletedAt.toUtc(),
            revision: 0,
          ),
        )
        .toList();
  }

  /// Rows logged before v6 have no `updatedAt`; their own start time is the
  /// best "last modified" available, and beats inventing the upgrade's clock.
  /// Drift hands dates back in local time — the instant is right, the flag is
  /// not, and comparing a local to a UTC one silently shifts by the offset.
  DateTime _effectiveUpdatedAt(AttackRow row) =>
      (row.updatedAt ?? row.startedAt).toUtc();
}
