import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/encrypted_attack.dart';
import '../../domain/repositories/remote_attack_repository.dart';
import 'encrypted_attack_mapper.dart';

/// Firestore-backed [RemoteAttackRepository]: `users/{uid}/attacks/{id}`.
///
/// Every document is ciphertext plus its timestamp, so this class never sees
/// an intensity or a note. Hard rule 1 allows nothing else up here.
class FirestoreAttackRepository implements RemoteAttackRepository {
  const FirestoreAttackRepository(this._firestore);

  /// Firestore caps a batch at 500 writes.
  static const int _batchLimit = 500;

  final FirebaseFirestore _firestore;

  @override
  Future<void> put(String uid, EncryptedAttack record) =>
      _attacks(uid).doc(record.id).set(EncryptedAttackMapper.toDocument(record));

  @override
  Future<List<EncryptedAttack>> changesSince(String uid, DateTime? since) async {
    Query<Map<String, dynamic>> query = _attacks(
      uid,
    ).orderBy(EncryptedAttackMapper.updatedAt);

    if (since != null) {
      query = query.where(
        EncryptedAttackMapper.updatedAt,
        isGreaterThan: Timestamp.fromDate(since),
      );
    }
    final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();

    return snapshot.docs
        .map((doc) => EncryptedAttackMapper.fromDocument(doc.id, doc.data()))
        .nonNulls
        .toList();
  }

  @override
  Future<void> deleteAll(String uid) async {
    // Deleted in pages: a long history would otherwise blow the batch limit,
    // and a wipe that half-runs is exactly what hard rule 8 forbids.
    while (true) {
      final QuerySnapshot<Map<String, dynamic>> page = await _attacks(
        uid,
      ).limit(_batchLimit).get();

      if (page.docs.isEmpty) return;

      final WriteBatch batch = _firestore.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  CollectionReference<Map<String, dynamic>> _attacks(String uid) =>
      _firestore.collection('users').doc(uid).collection('attacks');
}
