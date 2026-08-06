import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/sync_collection.dart';
import 'encrypted_record_mapper.dart';

/// One synced collection, scoped to one user.
///
/// Exists for a single reason: the collections are shared between users now,
/// so `userId` is the whole boundary. A query that forgets it is refused by
/// the rules — Firestore cannot evaluate ownership over a whole collection —
/// and a write that forgets it creates a record belonging to nobody. Neither
/// mistake is caught at compile time.
///
/// So nothing else may build a `CollectionReference` for these collections.
/// Go through here and the filter cannot be left off, because there is no
/// method that omits it.
class OwnedCollection {
  const OwnedCollection(this._firestore, this._uid, this._collection);

  final FirebaseFirestore _firestore;
  final String _uid;
  final SyncCollection _collection;

  /// Every document this user owns here. The only entry point for reads.
  Query<Map<String, dynamic>> owned() =>
      _root().where(EncryptedRecordMapper.userId, isEqualTo: _uid);

  /// Writes [data] under [id], stamping the owner. The rules reject any
  /// other value, so this is the only way the write can succeed.
  Future<void> write(String id, Map<String, Object?> data) =>
      _root().doc(id).set(data);

  DocumentReference<Map<String, dynamic>> doc(String id) => _root().doc(id);

  WriteBatch batch() => _firestore.batch();

  CollectionReference<Map<String, dynamic>> _root() =>
      _firestore.collection(_collection.name);
}
