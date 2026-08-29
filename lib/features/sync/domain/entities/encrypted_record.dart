import 'package:meta/meta.dart';

import 'encrypted_payload.dart';

/// One record as it exists on the server: an opaque id, a plaintext timestamp and — unless it is a deletion — the encrypted record itself.
@immutable
class EncryptedRecord {
  const EncryptedRecord({
    required this.id,
    required this.updatedAt,
    this.payload,
  });

  final String id;
  final DateTime updatedAt;

  /// Null for a deletion — there is nothing left to encrypt, and keeping the old ciphertext around would undo the delete.
  final EncryptedPayload? payload;

  bool get isDeleted => payload == null;
}
