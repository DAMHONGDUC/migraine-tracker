import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/app_config.dart';
import '../../domain/entities/app_config_schema.dart';
import '../../domain/entities/app_update_config.dart';
import '../../domain/entities/error_view_config.dart';
import '../../domain/repositories/app_config_repository.dart';
import 'app_update_mapper.dart';
import 'error_view_mapper.dart';

/// Reads the one `app_config/current` document — **the app's only read of it**.
///
/// Everything the owner controls is on it, so this is a single listener rather
/// than a query: no `where`, no `orderBy`, and nothing about which document is
/// current. That is also why the rules can allow a plain `get` and still refuse
/// a `list` — there is nothing to list.
///
/// Force update is parsed here too. It had its own repository and its own
/// `get` of this same document, which was a second reader to keep pointing at
/// the right id, a second thing to be denied on its own, and a second read
/// charged for every launch and every resume.
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
            premiumEmails: _emails(data[AppConfigSchema.premiumEmailsField]),
            devModeEmails: _emails(data[AppConfigSchema.devModeEmailsField]),
            blockedEmails: _emails(data[AppConfigSchema.blockedEmailsField]),
            forceUpdate: _forceUpdate(data[AppConfigSchema.forceUpdateField]),
            errorView: _errorView(data[AppConfigSchema.errorViewField]),
          );

          // Counts, never the addresses: this line says how many people are
          // privileged, and a console log is not where their names belong.
          SdLogger.info(
            LogTagConstant.appConfig,
            'App config read',
            <String, Object?>{
              'premiumEmails': config.premiumEmails.length,
              'devModeEmails': config.devModeEmails.length,
              'blockedEmails': config.blockedEmails.length,
              'hasForceUpdate': config.forceUpdate != null,
              // The copy itself is the owner's and can be long; what a console
              // needs to answer is whether a notice is up and how loud it is.
              'errorView': config.errorView?.type.name ?? 'none',
            },
          );

          return config;
        })
        // Offline, denied, or never created: no list holds anybody, nothing is
        // blocked and no build is out of date. A read that failed must leave
        // the app exactly as it was rather than take something away.
        //
        // **The fallback is EMITTED, not swallowed.** A `handleError` that only
        // logs ends the stream without a value, and every reader awaiting the
        // first one — the force-update check does — waits for good.
        .transform(
          StreamTransformer<AppConfig, AppConfig>.fromHandlers(
            handleError:
                (
                  Object error,
                  StackTrace stackTrace,
                  EventSink<AppConfig> sink,
                ) {
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
                  sink.add(AppConfig.empty);
                },
          ),
        );
  }

  /// Anything that is not a map is no record at all — typed by hand like the rest, and a malformed one must block nobody rather than throw on launch.
  static AppUpdateConfig? _forceUpdate(Object? value) => value is Map
      ? AppUpdateMapper.fromMap(Map<String, Object?>.from(value))
      : null;

  /// Anything that is not a map is no notice at all — typed by hand like the rest, and a malformed one must leave the app alone rather than replace it.
  static ErrorViewConfig? _errorView(Object? value) => value is Map
      ? ErrorViewMapper.fromMap(Map<String, Object?>.from(value))
      : null;

  /// Anything that is not a list of strings is an empty list — the field is typed by hand in the console, and a malformed one must grant nothing rather than throw on launch.
  static Set<String> _emails(Object? value) {
    if (value is! List) return const <String>{};

    return AppConfig.normalise(value.whereType<String>());
  }
}
