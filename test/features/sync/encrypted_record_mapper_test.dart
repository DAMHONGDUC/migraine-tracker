import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/sync/data/repositories/encrypted_record_mapper.dart';
import 'package:migraine_tracker/features/sync/domain/entities/encrypted_payload.dart';
import 'package:migraine_tracker/features/sync/domain/entities/encrypted_record.dart';

void main() {
  final EncryptedRecord record = EncryptedRecord(
    id: '2026-09-24',
    updatedAt: DateTime.utc(2026, 9, 24, 8),
    payload: const EncryptedPayload(ciphertext: 'c', nonce: 'n', mac: 'm'),
  );

  // The collections are flat: a bare record id is shared by every user, and a
  // daily log's id is the day. Two accounts' Tuesday was one document, and the
  // second account's push was refused for good.
  test('two users never share a document, even for the same record id', () {
    expect(
      EncryptedRecordMapper.documentId('alice', '2026-09-24'),
      isNot(EncryptedRecordMapper.documentId('bob', '2026-09-24')),
    );
    expect(
      EncryptedRecordMapper.documentId('alice', '2026-09-24'),
      'alice_2026-09-24',
    );
  });

  test('the written document carries exactly these keys', () {
    expect(
      EncryptedRecordMapper.toDocument(record, 'alice').keys.toSet(),
      <String>{
        'userId',
        'record_id',
        'updatedAt',
        'deleted',
        'payload',
        'nonce',
        'mac',
      },
    );
  });

  test('a read takes the record id from record_id, not the document id', () {
    final EncryptedRecord? read = EncryptedRecordMapper.fromDocument(
      'alice_2026-09-24',
      EncryptedRecordMapper.toDocument(record, 'alice'),
    );

    expect(read?.id, '2026-09-24');
  });

  test('a document from before record_id still reads under its own id', () {
    final EncryptedRecord? read = EncryptedRecordMapper.fromDocument(
      'legacy-attack-uuid',
      <String, Object?>{
        'userId': 'alice',
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 8)),
        'deleted': true,
      },
    );

    expect(read?.id, 'legacy-attack-uuid');
  });
}
