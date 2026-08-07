import '../entities/sync_collection.dart';

/// Remembers how far the last pull got, per account and per kind of record.
///
/// Scoped by uid on purpose: signing into a different account must start from
/// nothing rather than inherit the previous one's position and skip its
/// history. Scoped by collection because they move independently — a pull
/// that failed on reminders must not look finished because attacks got
/// through.
abstract interface class SyncCursorStore {
  Future<DateTime?> lastPulledAt(String uid, SyncCollection collection);

  Future<void> save(String uid, SyncCollection collection, DateTime at);

  /// When a whole pass last finished for [uid], or null if none has.
  ///
  /// Lives here rather than in memory because the automatic triggers are
  /// launch and resume: a cooldown the app forgets when it closes would
  /// let ten cold starts run ten passes, which is the case it exists for.
  Future<DateTime?> lastSyncedAt(String uid);

  Future<void> saveSyncedAt(String uid, DateTime at);

  /// Forgets every account's position AND its cooldown (sign-out, GDPR
  /// wipe). Signing into another account must sync at once rather than
  /// inherit the previous one's window.
  Future<void> clear();
}
