import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/logging/app_logger.dart';
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
    AppLogger.action('Read $collectionPath');
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection(collectionPath)
          .orderBy(AppUpdateMapper.createDateField, descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        // Not an error: hard rule 9 fails open, and "no record published"
        // is the normal state before the first release is announced.
        AppLogger.info('$collectionPath is empty');

        return null;
      }

      final Map<String, dynamic> raw = snapshot.docs.first.data();

      AppLogger.info('$collectionPath read', raw);

      return AppUpdateMapper.fromMap(raw);
    } catch (error, stackTrace) {
      // The launch check swallows this and lets the user in (hard rule 9),
      // so this line is the only place the reason is ever stated.
      AppLogger.error(
        'Read $collectionPath failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'collection': collectionPath},
      );
      rethrow;
    }
  }
}
