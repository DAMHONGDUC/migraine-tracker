import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/app_config_flags.dart';
import '../../domain/entities/app_config_grants.dart';
import '../../domain/entities/app_config_schema.dart';
import '../../domain/repositories/app_config_repository.dart';

/// Reads `app_config`: one document per address, keyed by the address itself, plus [AppConfigSchema.globalDocumentId] for what applies to everybody.
///
/// The row's document id IS the lower-cased email, which is what lets the rules
/// hand a client its own row and nothing else
/// (`request.auth.token.email.lower()`). A collection queried by field would
/// have to be readable as a whole to be readable at all, and the whole is a
/// list of real people's addresses.
class FirestoreAppConfigRepository implements AppConfigRepository {
  const FirestoreAppConfigRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<AppConfigGrants> watchGrants(String email) {
    final String id = AppConfigSchema.rowId(email);

    if (id.isEmpty) return Stream<AppConfigGrants>.value(AppConfigGrants.none);

    return _firestore
        .collection(AppConfigSchema.collectionPath)
        .doc(id)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> snap) {
          final Map<String, dynamic>? data = snap.data();

          if (!snap.exists || data == null) return AppConfigGrants.none;

          final AppConfigGrants grants = AppConfigGrants(
            premium: data[AppConfigSchema.premiumField] == true,
            devSettings: data[AppConfigSchema.devSettingsField] == true,
            blocked: data[AppConfigSchema.blockedField] == true,
          );

          // The id, never the address: this line names who is privileged, and a console is not where that belongs.
          SdLogger.info(
            LogTagConstant.appConfig,
            'App config grants read',
            <String, Object?>{
              'premium': grants.premium,
              'devSettings': grants.devSettings,
              'blocked': grants.blocked,
            },
          );

          return grants;
        })
        // A denied read (rules, or a token with no email) and an offline first launch land here alike, and both mean the same thing to a gate: grant nothing.
        .handleError((Object error, StackTrace stackTrace) {
          SdLogger.error(
            LogTagConstant.appConfig,
            'App config grants read failed',
            error: error,
            stackTrace: stackTrace,
            data: <String, Object?>{
              'collection': AppConfigSchema.collectionPath,
              if (error is FirebaseException) 'code': error.code,
            },
          );
        });
  }

  @override
  Stream<AppConfigFlags> watchFlags() {
    return _firestore
        .collection(AppConfigSchema.collectionPath)
        .doc(AppConfigSchema.globalDocumentId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> snap) {
          final Map<String, dynamic>? data = snap.data();

          if (!snap.exists || data == null) return AppConfigFlags.allOn;

          // `!= false` rather than `== true`: an absent field is a switch the
          // owner never threw, and the document exists for whichever other
          // switch they did write. Only a real `false` turns premium off, so a
          // string "false" typed into the console does nothing — the same trap
          // the grant fields have, in the opposite direction.
          final AppConfigFlags flags = AppConfigFlags(
            premiumEnabled: data[AppConfigSchema.premiumEnabledField] != false,
          );

          SdLogger.info(
            LogTagConstant.appConfig,
            'App config flags read',
            <String, Object?>{'premiumEnabled': flags.premiumEnabled},
          );

          return flags;
        })
        // Offline, denied, or never created: the app keeps every switch on. Taking premium away from a paying user because a read failed is the one outcome this must never produce.
        .handleError((Object error, StackTrace stackTrace) {
          SdLogger.error(
            LogTagConstant.appConfig,
            'App config flags read failed',
            error: error,
            stackTrace: stackTrace,
            data: <String, Object?>{
              'collection': AppConfigSchema.collectionPath,
              'document': AppConfigSchema.globalDocumentId,
              if (error is FirebaseException) 'code': error.code,
            },
          );
        });
  }
}
