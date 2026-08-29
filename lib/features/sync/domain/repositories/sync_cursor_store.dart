import '../entities/sync_collection.dart';

/// Remembers how far the last pull got, per account and per kind of record.
abstract interface class SyncCursorStore {
  Future<DateTime?> lastPulledAt(String uid, SyncCollection collection);

  Future<void> save(String uid, SyncCollection collection, DateTime at);

  /// When a whole pass last finished for [uid], or null if none has.
  Future<DateTime?> lastSyncedAt(String uid);

  Future<void> saveSyncedAt(String uid, DateTime at);

  /// Forgets every account's position AND its cooldown (sign-out, GDPR wipe).
  Future<void> clear();
}
