import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/encrypted_payload.dart';
import '../../domain/entities/encrypted_record.dart';

/// Field names and types for `<collection>/{id}`, in one place so the read
/// and the write cannot drift apart.
final class EncryptedRecordMapper {
  const EncryptedRecordMapper._();

  static const String ciphertext = 'payload';
  static const String nonce = 'nonce';
  static const String mac = 'mac';
  static const String updatedAt = 'updatedAt';
  static const String deleted = 'deleted';

  /// Who the record belongs to. The collections are shared, so this field is
  /// the entire boundary between one user's records and another's — the rules
  /// check it on every operation, and every query filters on it.
  static const String userId = 'userId';

  static Map<String, Object?> toDocument(EncryptedRecord record, String uid) {
    final EncryptedPayload? payload = record.payload;

    return <String, Object?>{
      userId: uid,
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
  static EncryptedRecord? fromDocument(String id, Map<String, Object?>? data) {
    if (data == null) return null;

    final Object? at = data[updatedAt];
    if (at is! Timestamp) return null;

    if (data[deleted] == true) {
      return EncryptedRecord(id: id, updatedAt: at.toDate().toUtc());
    }
    final Object? text = data[ciphertext];
    final Object? iv = data[nonce];
    final Object? tag = data[mac];

    if (text is! String || iv is! String || tag is! String) return null;
    return EncryptedRecord(
      id: id,
      updatedAt: at.toDate().toUtc(),
      payload: EncryptedPayload(ciphertext: text, nonce: iv, mac: tag),
    );
  }
}
