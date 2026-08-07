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

  /// Forgets every account's position (sign-out, GDPR wipe).
  Future<void> clear();
}
