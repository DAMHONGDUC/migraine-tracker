import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/common.dart';

import '../../features/auth/providers.dart';
import '../constants/log_tag_constant.dart';
import '../constants/prefs_key_constant.dart';
import '../storage/prefs_install_store.dart';
import '../storage/secure_device_store.dart';
import '../storage/secure_store.dart';
import 'app_env.dart';

/// What "a fresh install" means on this device, and the two vendor calls that
/// take it back to one.
///
/// Dev and prod ship under one bundle id (`app.dd.migraine.tracker`), so they
/// share a sandbox: installing one over the other leaves the new binary
/// reading the old one's signed-in session, its Keychain and its cached
/// documents — a dev account pointed at the real project, or the reverse. A
/// delete and reinstall is the same problem from the other side: iOS keeps the
/// Keychain, so the session comes back on what the user thinks is a clean
/// install. [SdFreshInstall] decides which of those a launch is and runs the
/// wipe; what is left here is the only part that is this app's — which SDKs
/// have something to drop.
///
/// ```text
/// stamp: dev (shared_preferences)   binary: FLAVOR=prod
///        ▼
/// 1 Sign out               google.signOut + auth.signOut, uid AbC123… → none
/// 2 Clear Firestore cache  app_config/app, users/AbC123 → dropped
/// 3 Clear the Keychain     onboarding_completed, alert_threshold: 7.0 → gone
/// 4 Clear shared_preferences        last_env: dev → gone, then rewritten
///        ▼
/// stamp: prod              onboarding again, anonymous session again
/// ```
///
/// **The on-device database is not wiped, on purpose.** The steps above cost a
/// sign-in and an onboarding run; the `baroease` SQLite file is the user's
/// migraine history and nothing else holds it. [AppEnv.flavor] falls back to
/// `dev` when a build forgets `--dart-define-from-file`, and the assert that
/// catches that is debug-only — so a release built wrong would read as an
/// environment change and delete health data that has no copy. Losing a
/// session to that mistake is recoverable; losing the record is not.
final class AppFreshInstall implements SdFreshInstallHost {
  const AppFreshInstall(this._ref);

  /// Read lazily, and only by [signOut]: building the auth repository reaches
  /// for `FirebaseAuth.instance`, which throws in a build that never
  /// initialised Firebase — the same build [isBackendReady] answers false for.
  final Ref _ref;

  /// Check this device, wipe it if it is not this build's, and stamp it.
  ///
  /// **Nothing may have opened a Firestore stream before this finishes**:
  /// `clearPersistence` throws `failed-precondition` once the client is
  /// running. `FreshInstallGate` is what holds those back — it sits above
  /// `_BaroEaseAppView`, whose first frame fires a sync, a weather write and a
  /// force-update read.
  static Future<SdFreshInstallOutcome> run(Ref ref) async => SdFreshInstall.run(
    logTag: LogTagConstant.freshInstall,
    buildStamp: AppEnv.flavor,
    installScoped: PrefsInstallStore(await SharedPreferences.getInstance()),
    deviceScoped: SecureDeviceStore(ref.read(secureStoreProvider)),
    host: AppFreshInstall(ref),
    // The flavour record the app already had a name for. An install that
    // predates the stamp has no value under it — it kept the flavour in the
    // Keychain — so it lands in the update row, which keeps the session.
    stampKey: PrefsKeyConstant.lastEnv,
  );

  /// Whether there is a Firebase app to sign out of at all.
  ///
  /// A build with no config never called `initializeApp`, and reaching for
  /// `FirebaseAuth.instance` there throws `[core/no-app]`.
  @override
  bool get isBackendReady =>
      AppEnv.hasFirebaseConfig && Firebase.apps.isNotEmpty;

  /// The repository's own, which also signs out of Google — without that the
  /// next sign-in skips the picker and lands back in the account the wipe just
  /// left.
  @override
  Future<void> signOut() => _ref.read(authRepositoryProvider).signOut();

  /// Drop every document Firestore cached for the other environment.
  ///
  /// `terminate` first: `clearPersistence` refuses while the client is
  /// running.
  @override
  Future<void> clearCache() async {
    await FirebaseFirestore.instance.terminate();
    await FirebaseFirestore.instance.clearPersistence();
  }
}
