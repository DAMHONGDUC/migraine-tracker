import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/encrypted_attack.dart';
import '../../domain/entities/encrypted_payload.dart';

/// Field names and types for `users/{uid}/attacks/{attackId}`, in one place
/// so the read and the write cannot drift apart.
final class EncryptedAttackMapper {
  const EncryptedAttackMapper._();

  static const String ciphertext = 'payload';
  static const String nonce = 'nonce';
  static const String mac = 'mac';
  static const String updatedAt = 'updatedAt';
  static const String deleted = 'deleted';

  static Map<String, Object?> toDocument(EncryptedAttack record) {
    final EncryptedPayload? payload = record.payload;

    return <String, Object?>{
      updatedAt: Timestamp.fromDate(record.updatedAt),
      deleted: record.isDeleted,
      // Cleared rather than left behind, so a deletion does not keep the
      // ciphertext it was meant to remove.
      ciphertext: payload?.ciphertext,
      nonce: payload?.nonce,
      mac: payload?.mac,
    };
  }

  /// Null when the document cannot be read as a record at all — a shape we do
  /// not recognise is skipped rather than guessed at.
  static EncryptedAttack? fromDocument(
    String id,
    Map<String, Object?>? data,
  ) {
    if (data == null) return null;

    final Object? at = data[updatedAt];
    if (at is! Timestamp) return null;

    if (data[deleted] == true) {
      return EncryptedAttack(id: id, updatedAt: at.toDate().toUtc());
    }
    final Object? text = data[ciphertext];
    final Object? iv = data[nonce];
    final Object? tag = data[mac];

    if (text is! String || iv is! String || tag is! String) return null;
    return EncryptedAttack(
      id: id,
      updatedAt: at.toDate().toUtc(),
      payload: EncryptedPayload(ciphertext: text, nonce: iv, mac: tag),
    );
  }
}
