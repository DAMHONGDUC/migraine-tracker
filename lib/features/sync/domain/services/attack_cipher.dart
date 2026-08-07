import '../entities/encrypted_payload.dart';

/// Encrypts and decrypts attack payloads with the account's key.
abstract interface class AttackCipher {
  /// Fresh nonce per call, so encrypting the same attack twice never produces
  /// the same ciphertext.
  Future<EncryptedPayload> encrypt({
    required String plaintext,
    required String base64Key,
  });

  /// Throws if the payload was tampered with or the key is wrong — a wrong
  /// key fails loudly here rather than yielding plausible nonsense.
  Future<String> decrypt({
    required EncryptedPayload payload,
    required String base64Key,
  });

  /// A whole pull's worth at once, **index for index** with [payloads].
  ///
  /// Null at a position means that one could not be opened — a null
  /// payload, a wrong key, a ciphertext that was tampered with. It never
  /// throws for one bad row, because one unreadable record must not wedge
  /// every later one behind it (hard rule 12), and the caller counts the
  /// nulls.
  ///
  /// Batched rather than looped by the caller so an implementation is free
  /// to move the work off the UI isolate — which is the whole reason this
  /// exists next to [decrypt].
  Future<List<String?>> decryptAll({
    required List<EncryptedPayload?> payloads,
    required String base64Key,
  });
}
