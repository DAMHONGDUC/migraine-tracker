import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/sync_collection.dart';
import 'encrypted_record_mapper.dart';

/// One synced collection, scoped to one user.
class OwnedCollection {
  const OwnedCollection(this._firestore, this._uid, this._collection);

  final FirebaseFirestore _firestore;
  final String _uid;
  final SyncCollection _collection;

  /// Every document this user owns here. The only entry point for reads.
  Query<Map<String, dynamic>> owned() =>
      _root().where(EncryptedRecordMapper.userId, isEqualTo: _uid);

  /// Writes [data] for record [id], stamping the owner. The rules reject any other value, so this is the only way the write can succeed.
  Future<void> write(String id, Map<String, Object?> data) => doc(id).set(data);

  /// Record [id]'s document — under this user's own id, never the bare record id.
  DocumentReference<Map<String, dynamic>> doc(String id) =>
      _root().doc(EncryptedRecordMapper.documentId(_uid, id));

  WriteBatch batch() => _firestore.batch();

  CollectionReference<Map<String, dynamic>> _root() =>
      _firestore.collection(_collection.name);
}
