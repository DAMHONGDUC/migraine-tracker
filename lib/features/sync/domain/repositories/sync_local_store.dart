import '../entities/sync_collection.dart';
import '../entities/sync_record.dart';

/// The local side of sync for one kind of record: what still has to go up, and how a change coming down is applied.
abstract interface class SyncLocalStore<T> {
  SyncCollection get collection;

  /// Everything changed since the server last confirmed it: edited records and pending deletions together, oldest change first.
  Future<List<SyncRecord<T>>> pendingChanges();

  /// Records that the server accepted [revision] of [id].
  Future<void> markSynced(String id, int revision);

  /// Drops the tombstone for [id] once the server has been told.
  Future<void> clearTombstone(String id);

  /// Applies a record pulled from the server, and marks it already in step.
  Future<bool> applyRemote(T value, DateTime updatedAt);

  /// Applies a deletion pulled from the server, under the same last-write-wins rule as [applyRemote]. Returns whether it deleted.
  Future<bool> applyRemoteDeletion(String id, DateTime deletedAt);
}
