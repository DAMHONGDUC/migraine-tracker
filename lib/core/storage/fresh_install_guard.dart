import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/common.dart';

import '../constants/log_tag_constant.dart';
import 'secure_store.dart';

/// Makes deleting the app and installing it again behave like a first install (owner's rule).
///
/// iOS keeps the Keychain when an app is deleted, so the Firebase session — and everything in [SecureStore] — came back on the next install and the user was still signed in. `shared_preferences` is the opposite: iOS deletes it with the app, which is exactly why the marker below lives there and nowhere else.
final class FreshInstallGuard {
  const FreshInstallGuard._();

  /// The one `shared_preferences` key in the app. Present = this install has run before; absent = the Keychain is speaking for an install that no longer exists.
  static const String installMarkerKey = 'install_marker';

  /// Runs before the anonymous session is created, so a purge is not immediately followed by signing the old user back in. [signOut] is `FirebaseAuth.instance.signOut` — passed in because the session is the one thing here a unit test cannot have.
  ///
  /// Never throws: a cleanup that fails must not take the launch with it, and every branch logs what it decided.
  static Future<void> run(
    SharedPreferences prefs,
    SecureStore store,
    Future<void> Function() signOut,
  ) async {
    if (prefs.getBool(installMarkerKey) ?? false) return;

    // Keys other than the marker mean an install that predates it — an update, not a reinstall. Its settings are carried over rather than wiped; the session goes either way (owner's rule).
    final List<String> legacy = prefs
        .getKeys()
        .where((String key) => key != installMarkerKey)
        .toList();

    SdLogger.action(LogTagConstant.storage, 'First launch of this install', {
      'isUpgrade': legacy.isNotEmpty,
      'legacyKeys': legacy.length,
    });
    try {
      if (legacy.isEmpty) {
        await store.deleteAll();
      } else {
        await _adopt(prefs, legacy, store);
      }
      // Unconditional, and the reason it is not inside the reinstall branch: the session is the ONE thing the Keychain carries across a delete, and a first launch that guesses wrong about which kind it is would leave the user signed into an install they never signed into. Signing out costs a tap; the other way round is the bug this guard exists for.
      await _signOut(signOut);
      // Last, so a crash anywhere above is retried on the next launch rather than skipped.
      await prefs.setBool(installMarkerKey, true);
      if (legacy.isNotEmpty) await _dropLegacy(prefs, legacy);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.storage,
        'First-launch guard failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// The session is Firebase's own Keychain item, not ours — signing out is the only way to reach it, and `_ensureAnonymousSession` opens a fresh anonymous one right after.
  static Future<void> _signOut(Future<void> Function() signOut) async {
    await signOut();
    SdLogger.info(
      LogTagConstant.storage,
      'First launch: the carried-over session signed out',
    );
  }

  /// An update from a build that kept its settings in `shared_preferences`: the same values, moved into the store that now owns them. Idempotent, because a crash before the marker is written repeats it.
  static Future<void> _adopt(
    SharedPreferences prefs,
    List<String> legacy,
    SecureStore store,
  ) async {
    for (final String key in legacy) {
      final Object? value = prefs.get(key);

      switch (value) {
        case final bool value:
          await store.setBool(key, value);
        case final int value:
          await store.setInt(key, value);
        case final double value:
          await store.setDouble(key, value);
        case final String value:
          await store.setString(key, value);
        default:
          // Nothing the app writes is a string list, so anything else is not ours to carry.
          SdLogger.warning(LogTagConstant.storage, 'Legacy key not carried', {
            'key': key,
          });
      }
    }
    SdLogger.info(LogTagConstant.storage, 'Legacy settings adopted', {
      'keys': legacy.length,
    });
  }

  /// One owner per value: the copies left behind would otherwise be read by nothing and outlive the ones that matter.
  static Future<void> _dropLegacy(
    SharedPreferences prefs,
    List<String> legacy,
  ) async {
    for (final String key in legacy) {
      await prefs.remove(key);
    }
  }
}
