import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/encrypted_record.dart';
import '../../domain/entities/sync_collection.dart';
import '../../domain/repositories/remote_sync_repository.dart';
import 'encrypted_record_mapper.dart';
import 'owned_collection.dart';

/// Firestore-backed [RemoteSyncRepository]: one top-level collection per kind of record, each document carrying the `userId` it belongs to.
class FirestoreSyncRepository implements RemoteSyncRepository {
  const FirestoreSyncRepository(this._firestore);

  /// Firestore caps a batch at 500 writes.
  static const int _batchLimit = 500;

  /// Pages of [_batchLimit] one collection may take before the wipe gives up —
  /// 20 000 documents, far past any history this app can produce.
  ///
  /// The loop was a bare `while (true)` whose only exit was an empty page, and
  /// the write-through uploads every local write: a push landing between the
  /// read and the delete refilled the page that had just been emptied, and the
  /// three dev tiles spun forever with no error and no way out.
  static const int _maxDeleteRounds = 40;

  final FirebaseFirestore _firestore;

  @override
  Future<void> put(
    String uid,
    SyncCollection collection,
    EncryptedRecord record,
  ) async {
    // Ids and timestamps only — the payload is ciphertext and the plaintext never reaches this class, so there is nothing here to leak.
    final Map<String, Object?> what = <String, Object?>{
      'collection': collection.name,
      'id': record.id,
      'updatedAt': record.updatedAt.toIso8601String(),
    };

    try {
      await _owned(
        uid,
        collection,
      ).write(record.id, EncryptedRecordMapper.toDocument(record, uid));
      SdLogger.debug(LogTagConstant.sync, 'Sync push ok', what);
    } on FirebaseException catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.sync,
        'Sync push failed',
        error: error,
        stackTrace: stackTrace,
        // `permission-denied` here almost always means the rules or the indexes were never deployed — worth saying which collection.
        data: <String, Object?>{...what, 'code': error.code},
      );
      rethrow;
    }
  }

  @override
  Future<List<EncryptedRecord>> changesSince(
    String uid,
    SyncCollection collection,
    DateTime? since,
  ) async {
    // Needs the composite index (userId, updatedAt) in firestore.indexes.json.
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
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
      final List<EncryptedRecord> records = snapshot.docs
          .map((doc) => EncryptedRecordMapper.fromDocument(doc.id, doc.data()))
          .nonNulls
          .toList();

      SdLogger.info(LogTagConstant.sync, 'Sync pull ok', <String, Object?>{
        'collection': collection.name,
        'since': since?.toIso8601String(),
        'documents': snapshot.docs.length,
        // A gap between the two means rows that would not map — a payload version this build cannot read, which is otherwise silent.
        'usable': records.length,
      });

      return records;
    } on FirebaseException catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.sync,
        'Sync pull failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'collection': collection.name,
          'since': since?.toIso8601String(),
          'code': error.code,
        },
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteAll(String uid) async {
    for (final SyncCollection collection in SyncCollection.values) {
      await _deleteCollection(uid, collection);
    }
  }

  Future<void> _deleteCollection(String uid, SyncCollection collection) async {
    final OwnedCollection owned = _owned(uid, collection);

    // Deleted in pages: a long history would otherwise blow the batch limit, and a wipe that half-runs is exactly what hard rule 8 forbids.
    for (int round = 0; round < _maxDeleteRounds; round++) {
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

    // Documents are still arriving after the cap, so something is writing this
    // collection as fast as the wipe empties it. Thrown rather than left: a
    // wipe that stops half-way must not report success (hard rule 8).
    throw StateError(
      'Wiping ${collection.name} gave up after $_maxDeleteRounds rounds of '
      '$_batchLimit documents',
    );
  }

  OwnedCollection _owned(String uid, SyncCollection collection) =>
      OwnedCollection(_firestore, uid, collection);
}
