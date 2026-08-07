import '../entities/sync_collection.dart';
import '../entities/sync_record.dart';

/// The local side of sync for one kind of record: what still has to go up,
/// and how a change coming down is applied.
///
/// Separate from the feature's own repository on purpose — history, insights
/// and export have no business seeing any of this, and the sync feature has
/// no business reaching into Drift itself.
abstract interface class SyncLocalStore<T> {
  SyncCollection get collection;

  /// Everything changed since the server last confirmed it: edited records
  /// and pending deletions together, oldest change first. Each one stands
  /// alone, so a push that stops halfway simply leaves the rest pending.
  Future<List<SyncRecord<T>>> pendingChanges();

  /// Records that the server accepted [revision] of [id].
  ///
  /// Only ever called after the write is acknowledged: a kill between the
  /// write and this costs a harmless re-push, never a lost record. A local
  /// edit that landed in between is left dirty rather than marked clean.
  Future<void> markSynced(String id, int revision);

  /// Drops the tombstone for [id] once the server has been told.
  Future<void> clearTombstone(String id);

  /// Applies a record pulled from the server, and marks it already in step.
  ///
  /// Skips the write when the local copy is strictly newer, so a pull can
  /// never clobber an edit made while it was in flight. Ties go to the
  /// server, so two devices converge instead of ping-ponging.
  /// Returns whether it wrote.
  Future<bool> applyRemote(T value, DateTime updatedAt);

  /// Applies a deletion pulled from the server, under the same
  /// last-write-wins rule as [applyRemote]. Returns whether it deleted.
  Future<bool> applyRemoteDeletion(String id, DateTime deletedAt);
}
