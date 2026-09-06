import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/app_config.dart';
import '../../domain/entities/app_config_schema.dart';
import '../../domain/repositories/app_config_repository.dart';

/// Reads the one `app_config/app` document.
///
/// Everything the owner controls is on it, so this is a single listener rather
/// than a query: no `where`, no `orderBy`, and nothing about which document is
/// current. That is also why the rules can allow a plain `get` and still refuse
/// a `list` — there is nothing to list.
class FirestoreAppConfigRepository implements AppConfigRepository {
  const FirestoreAppConfigRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<AppConfig> watch() {
    return _firestore
        .collection(AppConfigSchema.collectionPath)
        .doc(AppConfigSchema.documentId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> snap) {
          final Map<String, dynamic>? data = snap.data();

          if (!snap.exists || data == null) return AppConfig.empty;

          final AppConfig config = AppConfig(
            // `!= false` rather than `== true`: an absent field is a switch the
            // owner never threw, and the document exists for whichever other
            // field they did write. Only a real `false` turns premium off, so
            // `"false"` typed into the console as a string does nothing.
            premiumEnabled:
                data[AppConfigSchema.premiumEnabledField] != false,
            premiumEmails: _emails(data[AppConfigSchema.premiumEmailsField]),
            devModeEmails: _emails(data[AppConfigSchema.devModeEmailsField]),
            blockedEmails: _emails(data[AppConfigSchema.blockedEmailsField]),
          );

          // Counts, never the addresses: this line says how many people are
          // privileged, and a console log is not where their names belong.
          SdLogger.info(
            LogTagConstant.appConfig,
            'App config read',
            <String, Object?>{
              'premiumEnabled': config.premiumEnabled,
              'premiumEmails': config.premiumEmails.length,
              'devModeEmails': config.devModeEmails.length,
              'blockedEmails': config.blockedEmails.length,
            },
          );

          return config;
        })
        // Offline, denied, or never created: premium stays on and no list holds anybody. Taking premium away from a paying user because a read failed is the one outcome this must never produce.
        .handleError((Object error, StackTrace stackTrace) {
          SdLogger.error(
            LogTagConstant.appConfig,
            'App config read failed',
            error: error,
            stackTrace: stackTrace,
            data: <String, Object?>{
              'document':
                  '${AppConfigSchema.collectionPath}/${AppConfigSchema.documentId}',
              if (error is FirebaseException) 'code': error.code,
            },
          );
        });
  }

  /// Anything that is not a list of strings is an empty list — the field is typed by hand in the console, and a malformed one must grant nothing rather than throw on launch.
  static Set<String> _emails(Object? value) {
    if (value is! List) return const <String>{};

    return AppConfig.normalise(value.whereType<String>());
  }
}
