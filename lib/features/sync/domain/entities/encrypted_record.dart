import 'package:meta/meta.dart';

import 'encrypted_payload.dart';

/// One record as it exists on the server: an opaque id, a plaintext timestamp
/// and — unless it is a deletion — the encrypted record itself.
///
/// [updatedAt] is deliberately NOT encrypted. Both sides need to compare
/// versions and pull only what changed, and neither can do that without
/// decrypting everything on every sync. It reveals when the user last touched
/// a record and nothing about what is in it.
@immutable
class EncryptedRecord {
  const EncryptedRecord({
    required this.id,
    required this.updatedAt,
    this.payload,
  });

  final String id;
  final DateTime updatedAt;

  /// Null for a deletion — there is nothing left to encrypt, and keeping the
  /// old ciphertext around would undo the delete.
  final EncryptedPayload? payload;

  bool get isDeleted => payload == null;
}
