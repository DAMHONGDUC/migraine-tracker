import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/sync/data/services/aes_gcm_attack_cipher.dart';
import 'package:migraine_tracker/features/sync/domain/entities/encrypted_payload.dart';

void main() {
  const AesGcmAttackCipher cipher = AesGcmAttackCipher();

  String aKey([int seed = 1]) {
    final Random random = Random(seed);
    return base64Encode(List<int>.generate(32, (_) => random.nextInt(256)));
  }

  test('what goes in comes back out', () async {
    const String plaintext = '{"intensity":7,"notes":"woke up with it"}';

    final EncryptedPayload payload = await cipher.encrypt(
      plaintext: plaintext,
      base64Key: aKey(),
    );

    expect(
      await cipher.decrypt(payload: payload, base64Key: aKey()),
      plaintext,
    );
  });

  test('the ciphertext does not leak the plaintext', () async {
    final EncryptedPayload payload = await cipher.encrypt(
      plaintext: 'Sumatriptan',
      base64Key: aKey(),
    );

    expect(
      utf8.decode(base64Decode(payload.ciphertext), allowMalformed: true),
      isNot(contains('Sumatriptan')),
    );
  });

  test('non-ASCII survives the round trip', () async {
    const String plaintext = 'đau nửa đầu, buồn nôn — 7/10';

    final EncryptedPayload payload = await cipher.encrypt(
      plaintext: plaintext,
      base64Key: aKey(),
    );

    expect(
      await cipher.decrypt(payload: payload, base64Key: aKey()),
      plaintext,
    );
  });

  test('the same attack encrypts differently every time', () async {
    final EncryptedPayload first = await cipher.encrypt(
      plaintext: 'same',
      base64Key: aKey(),
    );
    final EncryptedPayload second = await cipher.encrypt(
      plaintext: 'same',
      base64Key: aKey(),
    );

    // A repeated nonce is what breaks GCM outright.
    expect(second.nonce, isNot(first.nonce));
    expect(second.ciphertext, isNot(first.ciphertext));
  });

  test('a nonce is the size GCM is defined against', () async {
    final EncryptedPayload payload = await cipher.encrypt(
      plaintext: 'x',
      base64Key: aKey(),
    );

    expect(
      base64Decode(payload.nonce),
      hasLength(AesGcmAttackCipher.nonceBytes),
    );
  });

  test('the wrong key fails loudly instead of returning nonsense', () async {
    final EncryptedPayload payload = await cipher.encrypt(
      plaintext: 'secret',
      base64Key: aKey(),
    );

    expect(
      () => cipher.decrypt(payload: payload, base64Key: aKey(2)),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('a payload tampered with on the server will not open', () async {
    final EncryptedPayload payload = await cipher.encrypt(
      plaintext: 'intensity 3',
      base64Key: aKey(),
    );
    final List<int> bytes = base64Decode(payload.ciphertext);
    bytes[0] ^= 0xFF;

    expect(
      () => cipher.decrypt(
        payload: EncryptedPayload(
          ciphertext: base64Encode(bytes),
          nonce: payload.nonce,
          mac: payload.mac,
        ),
        base64Key: aKey(),
      ),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });
}
