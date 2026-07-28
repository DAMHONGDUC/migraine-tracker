import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_update_config.dart';
import '../../domain/repositories/app_update_repository.dart';
import 'app_update_mapper.dart';

/// Reads the published-build record from Firestore.
///
/// The collection is world-readable and never written by the app (see
/// `firestore.rules`) — it carries release metadata only, no user data, so
/// the read works before sign-in and while anonymous.
class FirestoreAppUpdateRepository implements AppUpdateRepository {
  const FirestoreAppUpdateRepository(this._firestore);

  static const String collectionPath = 'app_updates';

  final FirebaseFirestore _firestore;

  /// Newest `create_date` first, one document — a new release is published
  /// by adding a record, so history stays in the collection.
  @override
  Future<AppUpdateConfig?> latest() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection(collectionPath)
        .orderBy(AppUpdateMapper.createDateField, descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return AppUpdateMapper.fromMap(snapshot.docs.first.data());
  }
}
