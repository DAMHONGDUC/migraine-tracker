import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/sync/data/services/aes_gcm_attack_cipher.dart';
import 'package:migraine_tracker/features/sync/domain/entities/encrypted_payload.dart';

void main() {
  const AesGcmAttackCipher cipher = AesGcmAttackCipher();
  final String key = base64Encode(List<int>.filled(32, 7));
  final String otherKey = base64Encode(List<int>.filled(32, 9));

  Future<EncryptedPayload> sealed(String plaintext) =>
      cipher.encrypt(plaintext: plaintext, base64Key: key);

  test('a batch comes back index for index', () async {
    final List<EncryptedPayload?> payloads = <EncryptedPayload?>[
      await sealed('one'),
      await sealed('two'),
      await sealed('three'),
    ];

    expect(
      await cipher.decryptAll(payloads: payloads, base64Key: key),
      <String?>['one', 'two', 'three'],
    );
  });

  test(
    'a null payload comes back null, keeping every later index put',
    () async {
      final List<EncryptedPayload?> payloads = <EncryptedPayload?>[
        await sealed('one'),
        null,
        await sealed('three'),
      ];

      // Alignment is the contract: the caller reads plaintexts[i] for
      // changes[i], so a hole must stay a hole rather than shift the rest.
      expect(
        await cipher.decryptAll(payloads: payloads, base64Key: key),
        <String?>['one', null, 'three'],
      );
    },
  );

  test('one unopenable record does not take the batch down with it', () async {
    final EncryptedPayload good = await sealed('readable');
    final List<EncryptedPayload?> payloads = <EncryptedPayload?>[
      good,
      // Sealed with another key: authentic-looking, and it will not open.
      await cipher.encrypt(plaintext: 'nope', base64Key: otherKey),
      const EncryptedPayload(
        ciphertext: 'not base64 at all',
        nonce: '',
        mac: '',
      ),
      good,
    ];

    final List<String?> result = await cipher.decryptAll(
      payloads: payloads,
      base64Key: key,
    );

    // Hard rule 12: one bad record is counted and skipped, never allowed to
    // wedge every later one behind it.
    expect(result, <String?>['readable', null, null, 'readable']);
  });

  test('an empty batch is an empty answer, and starts no isolate', () async {
    expect(
      await cipher.decryptAll(
        payloads: const <EncryptedPayload?>[],
        base64Key: key,
      ),
      isEmpty,
    );
  });

  test('the isolate path answers exactly as the inline one does', () async {
    // Above the threshold, so this batch takes the compute() route while the
    // small ones above did not.
    final int count = AesGcmAttackCipher.isolateThreshold + 5;
    final List<EncryptedPayload?> payloads = <EncryptedPayload?>[
      for (int i = 0; i < count; i++) i == 3 ? null : await sealed('record $i'),
    ];

    final List<String?> result = await cipher.decryptAll(
      payloads: payloads,
      base64Key: key,
    );

    expect(result, hasLength(count));
    expect(result[0], 'record 0');
    expect(result[3], isNull);
    expect(result.last, 'record ${count - 1}');
  });
}
