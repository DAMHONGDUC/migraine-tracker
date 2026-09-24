import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/encrypted_payload.dart';
import '../../domain/entities/encrypted_record.dart';

/// Field names and types for `<collection>/{uid}_{id}`, in one place so the read and the write cannot drift apart.
final class EncryptedRecordMapper {
  const EncryptedRecordMapper._();

  static const String ciphertext = 'payload';
  static const String nonce = 'nonce';
  static const String mac = 'mac';
  static const String updatedAt = 'updatedAt';
  static const String deleted = 'deleted';

  /// Who the record belongs to.
  static const String userId = 'userId';

  /// The record's own id — the document id carries the owner too, so it is not that.
  static const String recordId = 'record_id';

  /// Where a user's record lives: the owner, then the record's id.
  ///
  /// The collections are flat, so a bare record id is shared by every user. A
  /// daily check-in's id is the day itself: the first account to sync
  /// `2026-09-24` owned `daily_logs/2026-09-24`, and every other account's push
  /// was refused by `ownsStored()` for good — 35 records owed on TestFlight,
  /// online, forever.
  static String documentId(String uid, String id) => '${uid}_$id';

  static Map<String, Object?> toDocument(EncryptedRecord record, String uid) {
    final EncryptedPayload? payload = record.payload;

    return <String, Object?>{
      userId: uid,
      recordId: record.id,
      updatedAt: Timestamp.fromDate(record.updatedAt),
      deleted: record.isDeleted,
      // Cleared rather than left behind, so a deletion does not keep the ciphertext it was meant to remove.
      ciphertext: payload?.ciphertext,
      nonce: payload?.nonce,
      mac: payload?.mac,
    };
  }

  /// Null when the document cannot be read as a record at all — a shape we do not recognise is skipped rather than guessed at.
  ///
  /// [documentId] is used as the record id only for a document written before
  /// `record_id` existed, whose id was the bare record id.
  static EncryptedRecord? fromDocument(
    String documentId,
    Map<String, Object?>? data,
  ) {
    if (data == null) return null;

    final Object? stored = data[recordId];
    final String id = stored is String ? stored : documentId;

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
