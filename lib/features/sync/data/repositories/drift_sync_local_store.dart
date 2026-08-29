import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import '../../../../core/db/app_database.dart';
import '../../domain/entities/sync_collection.dart';
import '../../domain/entities/sync_record.dart';
import '../../domain/repositories/sync_local_store.dart';

/// Everything the three local stores do the same way: tombstone bookkeeping, last-write-wins, and doing the compare-then-write in one transaction.
abstract class DriftSyncLocalStore<T> implements SyncLocalStore<T> {
  const DriftSyncLocalStore(this.db);

  @protected
  final AppDatabase db;

  /// Dirty rows of this table, as records ready to push.
  @protected
  Future<List<SyncRecord<T>>> loadDirty();

  /// The row's last-modified instant, or null when there is no such row.
  @protected
  Future<DateTime?> localUpdatedAt(String id);

  @protected
  Future<int> nextRevision(String id);

  /// Writes a record that came down from the server, already in step.
  @protected
  Future<bool> writeFromRemote(T value, DateTime updatedAt, int revision);

  @protected
  Future<void> deleteRow(String id);

  @protected
  Future<void> writeSyncedRevision(String id, int revision);

  @override
  Future<List<SyncRecord<T>>> pendingChanges() async {
    final List<SyncRecord<T>> records = <SyncRecord<T>>[
      ...await loadDirty(),
      ...await _tombstones(),
    ];

    // Id breaks the tie: dates are stored to the second, so two changes made in the same one would otherwise come out in an arbitrary order.
    records.sort((a, b) {
      final int byTime = a.updatedAt.compareTo(b.updatedAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    return records;
  }

  @override
  Future<void> markSynced(String id, int revision) =>
      writeSyncedRevision(id, revision);

  @override
  Future<void> clearTombstone(String id) => (db.delete(
    db.syncTombstones,
  )..where((t) => t.collection.equals(collection.name) & t.id.equals(id))).go();

  @override
  Future<bool> applyRemote(T value, DateTime updatedAt) {
    return db.transaction(() async {
      final String id = idOf(value);

      if (await _localIsNewer(id, updatedAt)) return false;
      return writeFromRemote(value, updatedAt, await nextRevision(id));
    });
  }

  @override
  Future<bool> applyRemoteDeletion(String id, DateTime deletedAt) {
    return db.transaction(() async {
      if (await _localIsNewer(id, deletedAt)) return false;

      await deleteRow(id);
      // No tombstone: the server is the one telling us, so it already knows.
      await clearTombstone(id);
      return true;
    });
  }

  /// The record's own id — the one thing the base needs from [T].
  @protected
  String idOf(T value);

  /// Ties go to the server so two devices converge on the same answer instead of each preferring its own.
  Future<bool> _localIsNewer(String id, DateTime remote) async {
    final DateTime? local = await localUpdatedAt(id);

    if (local == null) return false;
    return local.isAfter(remote);
  }

  Future<List<SyncRecord<T>>> _tombstones() async {
    final List<SyncTombstoneRow> rows = await (db.select(
      db.syncTombstones,
    )..where((t) => t.collection.equals(collection.name))).get();

    return rows
        .map(
          (row) => SyncRecord<T>(
            id: row.id,
            updatedAt: row.deletedAt.toUtc(),
            revision: 0,
          ),
        )
        .toList();
  }
}

/// Writes a tombstone for a deleted row. Used by the feature repositories, which are the ones that do the deleting.
final class SyncTombstoneWriter {
  const SyncTombstoneWriter._();

  static Future<void> write(
    AppDatabase db,
    SyncCollection collection,
    Iterable<String> ids,
  ) async {
    final DateTime now = DateTime.now().toUtc();

    for (final String id in ids) {
      await db
          .into(db.syncTombstones)
          .insertOnConflictUpdate(
            SyncTombstonesCompanion.insert(
              collection: collection.name,
              id: id,
              deletedAt: now,
            ),
          );
    }
  }

  /// Drops any tombstone for [ids] — a re-used id would otherwise be deleted again by its own stale tombstone.
  static Future<void> clear(
    AppDatabase db,
    SyncCollection collection,
    Iterable<String> ids,
  ) async {
    for (final String id in ids) {
      await (db.delete(db.syncTombstones)..where(
            (t) => t.collection.equals(collection.name) & t.id.equals(id),
          ))
          .go();
    }
  }

  /// Clears every tombstone of one kind (GDPR wipe).
  static Future<void> clearAll(AppDatabase db, SyncCollection collection) =>
      (db.delete(
        db.syncTombstones,
      )..where((t) => t.collection.equals(collection.name))).go();
}
