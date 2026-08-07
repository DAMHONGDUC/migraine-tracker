import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../../domain/entities/encrypted_payload.dart';
import '../../domain/services/attack_cipher.dart';

/// AES-256-GCM, chosen for being authenticated: a payload altered on the
/// server fails to decrypt instead of quietly decoding to something else.
class AesGcmAttackCipher implements AttackCipher {
  const AesGcmAttackCipher();

  /// 96 bits, the nonce size AES-GCM is defined against.
  static const int nonceBytes = 12;

  static final AesGcm _algorithm = AesGcm.with256bits();

  @override
  Future<EncryptedPayload> encrypt({
    required String plaintext,
    required String base64Key,
  }) async {
    final SecretBox box = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: _key(base64Key),
      nonce: _algorithm.newNonce(),
    );

    return EncryptedPayload(
      ciphertext: base64Encode(box.cipherText),
      nonce: base64Encode(box.nonce),
      mac: base64Encode(box.mac.bytes),
    );
  }

  @override
  Future<String> decrypt({
    required EncryptedPayload payload,
    required String base64Key,
  }) async {
    final SecretBox box = SecretBox(
      base64Decode(payload.ciphertext),
      nonce: base64Decode(payload.nonce),
      mac: Mac(base64Decode(payload.mac)),
    );

    return utf8.decode(
      await _algorithm.decrypt(box, secretKey: _key(base64Key)),
    );
  }

  SecretKey _key(String base64Key) => SecretKey(base64Decode(base64Key));
}
