import '../entities/encrypted_record.dart';
import '../entities/sync_collection.dart';

/// The server side of sync. Deals only in already-encrypted payloads — it
/// moves bytes and never holds a key.
abstract interface class RemoteSyncRepository {
  /// Writes one record, creating or overwriting it.
  Future<void> put(
    String uid,
    SyncCollection collection,
    EncryptedRecord record,
  );

  /// Everything in [collection] touched after [since], or all of it when that
  /// is null (a device pulling an account's history for the first time).
  Future<List<EncryptedRecord>> changesSince(
    String uid,
    SyncCollection collection,
    DateTime? since,
  );

  /// Removes every synced record of every kind for the account (GDPR wipe,
  /// hard rule 8).
  Future<void> deleteAll(String uid);
}
