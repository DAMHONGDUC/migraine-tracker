import '../entities/encrypted_attack.dart';

/// The server side of attack sync. Deals only in already-encrypted payloads —
/// it moves bytes and never holds a key.
abstract interface class RemoteAttackRepository {
  /// Writes one record, creating or overwriting it.
  Future<void> put(String uid, EncryptedAttack record);

  /// Everything touched after [since], or all of it when that is null (a
  /// device pulling an account's history for the first time).
  Future<List<EncryptedAttack>> changesSince(String uid, DateTime? since);

  /// Removes every synced attack for the account (GDPR wipe, hard rule 8).
  Future<void> deleteAll(String uid);
}
