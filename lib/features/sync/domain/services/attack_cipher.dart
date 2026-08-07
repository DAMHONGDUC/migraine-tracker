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
}
