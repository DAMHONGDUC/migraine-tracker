import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/encrypted_record.dart';
import '../../domain/entities/sync_collection.dart';
import '../../domain/repositories/remote_sync_repository.dart';
import 'encrypted_record_mapper.dart';
import 'owned_collection.dart';

/// Firestore-backed [RemoteSyncRepository]: one top-level collection per kind
/// of record, each document carrying the `userId` it belongs to.
///
/// Every document is ciphertext plus its timestamp, so this class never sees
/// an intensity, a note or a medication name. Hard rule 1 allows nothing else
/// up here.
///
/// Every read and write goes through [OwnedCollection], which is what keeps
/// `userId` on the write and the filter on the query — the two things that
/// stand between one user's records and another's.
class FirestoreSyncRepository implements RemoteSyncRepository {
  const FirestoreSyncRepository(this._firestore);

  /// Firestore caps a batch at 500 writes.
  static const int _batchLimit = 500;

  final FirebaseFirestore _firestore;

  @override
  Future<void> put(
    String uid,
    SyncCollection collection,
    EncryptedRecord record,
  ) => _owned(uid, collection).write(
    record.id,
    EncryptedRecordMapper.toDocument(record, uid),
  );

  @override
  Future<List<EncryptedRecord>> changesSince(
    String uid,
    SyncCollection collection,
    DateTime? since,
  ) async {
    // Needs the composite index (userId, updatedAt) in firestore.indexes.json:
    // an equality filter on one field with a range and order on another is
    // exactly what Firestore will not serve on its own.
    Query<Map<String, dynamic>> query = _owned(
      uid,
      collection,
    ).owned().orderBy(EncryptedRecordMapper.updatedAt);

    if (since != null) {
      query = query.where(
        EncryptedRecordMapper.updatedAt,
        isGreaterThan: Timestamp.fromDate(since),
      );
    }
    final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();

    return snapshot.docs
        .map((doc) => EncryptedRecordMapper.fromDocument(doc.id, doc.data()))
        .nonNulls
        .toList();
  }

  @override
  Future<void> deleteAll(String uid) async {
    for (final SyncCollection collection in SyncCollection.values) {
      await _deleteCollection(uid, collection);
    }
  }

  Future<void> _deleteCollection(String uid, SyncCollection collection) async {
    final OwnedCollection owned = _owned(uid, collection);

    // Deleted in pages: a long history would otherwise blow the batch limit,
    // and a wipe that half-runs is exactly what hard rule 8 forbids.
    while (true) {
      final QuerySnapshot<Map<String, dynamic>> page = await owned
          .owned()
          .limit(_batchLimit)
          .get();

      if (page.docs.isEmpty) return;

      final WriteBatch batch = owned.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  OwnedCollection _owned(String uid, SyncCollection collection) =>
      OwnedCollection(_firestore, uid, collection);
}
