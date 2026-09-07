import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/app_config_schema.dart';
import '../../domain/entities/app_update_config.dart';
import '../../domain/repositories/app_update_repository.dart';
import 'app_update_mapper.dart';

/// Reads the published-build record out of the `force_update` field of `app_config/current`.
///
/// One document rather than the collection of dated records this used to be: a
/// release is announced by editing the one place the owner already edits, and
/// "which record is current" stops being a question an `orderBy` has to answer.
class FirestoreAppUpdateRepository implements AppUpdateRepository {
  const FirestoreAppUpdateRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<AppUpdateConfig?> latest() async {
    final String path =
        '${AppConfigSchema.collectionPath}/${AppConfigSchema.documentId}';

    SdLogger.action(LogTagConstant.appUpdate, 'Read $path');
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection(AppConfigSchema.collectionPath)
          .doc(AppConfigSchema.documentId)
          .get();

      final Map<String, dynamic>? data = snapshot.data();
      final Object? section = data?[AppConfigSchema.forceUpdateField];

      if (section is! Map) {
        // Not an error: hard rule 9 fails open, and "no record published" is the normal state before the first release is announced.
        SdLogger.info(LogTagConstant.appUpdate, '$path has no force update');

        return null;
      }

      final Map<String, Object?> raw = Map<String, Object?>.from(section);

      SdLogger.info(LogTagConstant.appUpdate, '$path read', raw);

      return AppUpdateMapper.fromMap(raw);
    } catch (error, stackTrace) {
      // The launch check swallows this and lets the user in (hard rule 9), so this line is the only place the reason is ever stated.
      SdLogger.error(
        LogTagConstant.appUpdate,
        'Read $path failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'document': path},
      );
      rethrow;
    }
  }
}
