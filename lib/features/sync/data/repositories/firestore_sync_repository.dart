import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/encrypted_record.dart';
import '../../domain/entities/sync_collection.dart';
import '../../domain/repositories/remote_sync_repository.dart';
import 'encrypted_record_mapper.dart';

/// Firestore-backed [RemoteSyncRepository]: `users/{uid}/{collection}/{id}`,
/// one subcollection per kind of record.
///
/// Every document is ciphertext plus its timestamp, so this class never sees
/// an intensity, a note or a medication name. Hard rule 1 allows nothing else
/// up here.
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
  ) => _collection(
    uid,
    collection,
  ).doc(record.id).set(EncryptedRecordMapper.toDocument(record));

  @override
  Future<List<EncryptedRecord>> changesSince(
    String uid,
    SyncCollection collection,
    DateTime? since,
  ) async {
    Query<Map<String, dynamic>> query = _collection(
      uid,
      collection,
    ).orderBy(EncryptedRecordMapper.updatedAt);

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
    // Deleted in pages: a long history would otherwise blow the batch limit,
    // and a wipe that half-runs is exactly what hard rule 8 forbids.
    while (true) {
      final QuerySnapshot<Map<String, dynamic>> page = await _collection(
        uid,
        collection,
      ).limit(_batchLimit).get();

      if (page.docs.isEmpty) return;

      final WriteBatch batch = _firestore.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  CollectionReference<Map<String, dynamic>> _collection(
    String uid,
    SyncCollection collection,
  ) => _firestore.collection('users').doc(uid).collection(collection.name);
}
