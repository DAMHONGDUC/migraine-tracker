import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/access_grants.dart';
import '../../domain/repositories/access_repository.dart';

/// Reads one document out of `app_access`, keyed by the address itself.
///
/// The document id IS the lower-cased email, which is what lets the rules hand
/// a client its own row and nothing else (`request.auth.token.email.lower()`).
/// A collection queried by field would have to be readable as a whole to be
/// readable at all, and the whole is a list of real people's addresses.
class FirestoreAccessRepository implements AccessRepository {
  const FirestoreAccessRepository(this._firestore);

  static const String collectionPath = 'app_access';

  /// Grants premium in the app and makes the address a target of the pressure-alert cron.
  static const String premiumField = 'premium';

  /// Shows the Dev group in Settings.
  static const String devSettingsField = 'devSettings';

  final FirebaseFirestore _firestore;

  /// The one spelling both sides agree on: the app lower-cases before the read, the owner lower-cases when creating the row, and Firebase Auth already stores addresses lower-cased.
  static String documentId(String email) => email.trim().toLowerCase();

  @override
  Stream<AccessGrants> watch(String email) {
    final String id = documentId(email);

    if (id.isEmpty) return Stream<AccessGrants>.value(AccessGrants.none);

    return _firestore
        .collection(collectionPath)
        .doc(id)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> snap) {
          final Map<String, dynamic>? data = snap.data();

          if (!snap.exists || data == null) return AccessGrants.none;

          final AccessGrants grants = AccessGrants(
            premium: data[premiumField] == true,
            devSettings: data[devSettingsField] == true,
          );

          // The id, never the address: this line names who is privileged, and a console is not where that belongs.
          SdLogger.info(
            LogTagConstant.access,
            'Access grants read',
            <String, Object?>{
              'premium': grants.premium,
              'devSettings': grants.devSettings,
            },
          );

          return grants;
        })
        // A denied read (rules, or a token with no email) and an offline first launch land here alike, and both mean the same thing to a gate: grant nothing.
        .handleError((Object error, StackTrace stackTrace) {
          SdLogger.error(
            LogTagConstant.access,
            'Access grants read failed',
            error: error,
            stackTrace: stackTrace,
            data: <String, Object?>{
              'collection': collectionPath,
              if (error is FirebaseException) 'code': error.code,
            },
          );
        });
  }
}
