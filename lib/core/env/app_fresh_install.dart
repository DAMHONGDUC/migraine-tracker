import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../features/auth/providers.dart';
import '../constants/log_tag_constant.dart';
import '../constants/prefs_key_constant.dart';
import '../storage/secure_fresh_install_store.dart';
import '../storage/secure_store.dart';
import 'app_env.dart';

/// The policy `SdDevWrapper` runs the flavour check with, or null where there
/// is nothing to check.
///
/// Widget tests override it with null: a test process shares its sandbox with
/// no other build, and a guard that holds the first frame back would hold back
/// every tree they pump.
final appFreshInstallPolicyProvider = Provider<SdFreshInstallPolicy?>(
  (ref) => AppFreshInstall.policy(ref),
);

/// What "a fresh install" means on this device.
///
/// Dev and prod ship under one bundle id (`app.dd.migraine.tracker`), so they
/// share a sandbox: installing one over the other leaves the new binary
/// reading the old one's signed-in session, its Keychain and its cached
/// documents — a dev account pointed at the real project, or the reverse.
/// `SdFreshInstallGuard` makes the comparison and `SdFreshInstall` runs the
/// wipe; what is left here is the only part that is this app's — which SDKs
/// have something to drop, and the store behind them.
///
/// ```text
/// last_env: dev            binary: FLAVOR=prod
///        ▼
/// 1 Sign out               google.signOut + auth.signOut, uid AbC123… → none
/// 2 Clear Firestore cache  app_config/config, users/AbC123 → dropped
/// 3 Clear the Keychain     onboarding_completed, alert_threshold: 7.0 → gone
///        ▼
/// last_env: prod           onboarding again, anonymous session again
/// ```
///
/// **The on-device database is not wiped, on purpose.** The steps above cost a
/// sign-in and an onboarding run; the `baroease` SQLite file is the user's
/// migraine history and nothing else holds it. [AppEnv.flavor] falls back to
/// `dev` when a build forgets `--dart-define-from-file`, and the assert that
/// catches that is debug-only — so a release built wrong would read as an
/// environment change and delete health data that has no copy. Losing a
/// session to that mistake is recoverable; losing the record is not.
final class AppFreshInstall {
  const AppFreshInstall._();

  /// Order matters: sign out first so nothing is still writing, then drop the
  /// documents that session cached. The Keychain goes last and
  /// `SdFreshInstall` does that itself, after every step — it holds the
  /// environment record, so clearing it early would leave a half-wiped device
  /// claiming an environment it no longer has.
  static SdFreshInstallPolicy policy(Ref ref) => SdFreshInstall.policy(
    logTag: LogTagConstant.freshInstall,
    envKey: PrefsKeyConstant.lastEnv,
    store: SecureFreshInstallStore(ref.read(secureStoreProvider)),
    steps: <SdFreshInstallStep>[
      SdFreshInstallStep(
        name: 'Sign out',
        when: _hasFirebase,
        // The repository's own, which also signs out of Google — without that
        // the next sign-in skips the picker and lands back in the account the
        // wipe just left.
        run: () => ref.read(authRepositoryProvider).signOut(),
      ),
      SdFreshInstallStep(
        name: 'Clear Firestore cache',
        when: _hasFirebase,
        run: _clearFirestoreCache,
      ),
    ],
  );

  /// Drop every document Firestore cached for the other environment.
  ///
  /// **`terminate` first, and this only works before anything reads.**
  /// `clearPersistence` throws `failed-precondition` while the client is
  /// running, which is why the guard holds the app's first frame back rather
  /// than wiping alongside it.
  static Future<void> _clearFirestoreCache() async {
    await FirebaseFirestore.instance.terminate();
    await FirebaseFirestore.instance.clearPersistence();
  }

  /// Whether there is a Firebase app to sign out of at all.
  ///
  /// A build with no config never called `initializeApp`, and reaching for
  /// `FirebaseAuth.instance` there throws `[core/no-app]`.
  static bool _hasFirebase() =>
      AppEnv.hasFirebaseConfig && Firebase.apps.isNotEmpty;
}
