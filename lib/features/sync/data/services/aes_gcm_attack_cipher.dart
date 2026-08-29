import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/encrypted_payload.dart';
import '../../domain/services/attack_cipher.dart';

/// AES-256-GCM, chosen for being authenticated: a payload altered on the server fails to decrypt instead of quietly decoding to something else.
class AesGcmAttackCipher implements AttackCipher {
  const AesGcmAttackCipher();

  /// 96 bits, the nonce size AES-GCM is defined against.
  static const int nonceBytes = 12;

  /// How many records a pull has to carry before [decryptAll] pays for an isolate instead of doing the work where it stands.
  static const int isolateThreshold = 50;

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

  @override
  Future<List<String?>> decryptAll({
    required List<EncryptedPayload?> payloads,
    required String base64Key,
  }) async {
    final int openable = payloads.whereType<EncryptedPayload>().length;

    if (openable < isolateThreshold) {
      return _decryptEach(payloads, base64Key);
    }
    // Records and plain objects both travel the port; nothing here holds a closure or a native handle.
    return compute(_decryptBatch, (payloads, base64Key));
  }

  /// The isolate's entry point. A static rather than a top-level function: `compute` needs one of the two, and this project does not have top-level functions.
  static Future<List<String?>> _decryptBatch(
    (List<EncryptedPayload?>, String) job,
  ) {
    final (List<EncryptedPayload?> payloads, String key) = job;

    return const AesGcmAttackCipher()._decryptEach(payloads, key);
  }

  /// Shared by both paths, so the isolate and the inline route cannot answer differently.
  Future<List<String?>> _decryptEach(
    List<EncryptedPayload?> payloads,
    String base64Key,
  ) async {
    final List<String?> results = <String?>[];

    for (final EncryptedPayload? payload in payloads) {
      if (payload == null) {
        results.add(null);
        continue;
      }
      try {
        results.add(await decrypt(payload: payload, base64Key: base64Key));
      } catch (error, stackTrace) {
        // Counted by the caller, never rethrown: the ciphertext will not change, so retrying it forever would wedge the pull.
        SdLogger.error(
          LogTagConstant.syncCrypto,
          'Decrypting a synced record failed',
          error: error,
          stackTrace: stackTrace,
        );
        results.add(null);
      }
    }
    return results;
  }

  SecretKey _key(String base64Key) => SecretKey(base64Decode(base64Key));
}
