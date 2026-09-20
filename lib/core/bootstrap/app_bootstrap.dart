import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:system_design/common.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants/log_tag_constant.dart';
import '../../firebase_options.dart';
import '../analytics/app_analytics.dart';
import '../env/app_env.dart';
import '../env/flavor_config_mismatch.dart';
import '../logging/crash_reporter.dart';

/// The work `main` hands to `SdBootstrap`, one method per step.
///
/// **Nothing here writes a `try` of its own**, with one stated exception.
/// Every step is guarded and logged by [SdBootstrap], and one of them failing
/// must not take the launch with it — a step that swallowed its own failure
/// would report as started. [initFirebase] catches, and only to *widen* what
/// is reported: `duplicate-app` is the shape a flavour mismatch arrives in, so
/// letting it escape would end the step before the check that names it.
final class AppBootstrap {
  const AppBootstrap._();

  /// First, so Crashlytics is up before anything else can fail.
  ///
  /// Also where the build's two halves of config are compared — see
  /// [FlavorConfigMismatch] for the trap. Inside this step rather than a step
  /// of its own: `Firebase.app()` throws `[core/no-app]` when the line above
  /// it did not run, so a separate step would have to re-derive whether it
  /// applies, which is a second copy of the same condition.
  static Future<void> initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (error) {
      SdLogger.warning(
        LogTagConstant.bootstrap,
        'Firebase.initializeApp refused the options this build passed',
        <String, String>{'code': error.code},
      );

      // **`duplicate-app` is what a flavour mismatch actually looks like**, so
      // it must not escape before the comparison below runs.
      //
      // The native default app is already up by the time Dart asks for one —
      // `FLTFirebaseCorePlugin` configures it from `GoogleService-Info.plist`,
      // Android's `FirebaseInitProvider` from `google-services.json` — and
      // firebase_core answers our options by soft-comparing apiKey,
      // databaseURL and storageBucket against that app, never projectId. Two
      // different projects differ on apiKey, so a mismatch lands here rather
      // than on the check. A hot restart lands here too, with the same project
      // on both sides, which is why the code decides nothing and the ids do.
      if (error.code != 'duplicate-app') rethrow;
    }

    _guardFlavorAgainstNativeConfig();
  }

  /// Compares the build's two halves of config, at the one moment both exist
  /// in the same process.
  ///
  /// **`Firebase.app().options` is the native half, not an echo of ours.**
  /// When a plist or a `google-services.json` is bundled, firebase_core keeps
  /// the app the platform already created from that file and discards the
  /// options we passed — so on a mismatch the app does not run against the
  /// project its dart-defines name, it runs against the file's, which is the
  /// whole reason this is worth refusing.
  ///
  /// Compared at runtime rather than off the files: a file check answers "what
  /// is on disk", and a plist cached in DerivedData or a hot restart after
  /// switching flavours passes that one and fails this one. The lane's own
  /// file check (`sd_verify_flavor_config`) is the other half and neither
  /// replaces the other.
  static void _guardFlavorAgainstNativeConfig() {
    final String nativeProjectId = Firebase.apps.isEmpty
        ? ''
        : Firebase.app().options.projectId;

    // **A mismatch is refused; an absence never is.** A build with no config
    // on one side is an app whose backend is not set up yet, and a guard that
    // fires there breaks day one of a fresh clone — whoever hits it deletes
    // the guard rather than the cause.
    if (!FlavorConfigMismatch.disagree(
      AppEnv.firebaseProjectId,
      nativeProjectId,
    )) {
      return;
    }

    final FlavorConfigMismatch mismatch = FlavorConfigMismatch(
      expected: AppEnv.firebaseProjectId,
      actual: nativeProjectId,
    );

    // **Logged here as well as thrown**, which is the one place in this file
    // worth spending a second line on. `SdBootstrap` logs every step that
    // throws, but that line says "Firebase failed to start" — it names the
    // step, not the two projects, and someone scrolling a console is looking
    // for the ids and the command. They go in as `data` so a structured log
    // can be filtered on them rather than grepped out of a sentence.
    //
    // It does not double-report: `SdCrashReporter` is attached by the *next*
    // step, so nothing here reaches Crashlytics — which is the point, because
    // a build pointed at the wrong project must not file its crashes there
    // either.
    SdLogger.error(
      LogTagConstant.bootstrap,
      'Checking the build flavour against the native Firebase config',
      error: mismatch,
      data: <String, String>{
        'flavor': AppEnv.flavor,
        'dartProjectId': AppEnv.firebaseProjectId,
        'nativeProjectId': nativeProjectId,
        'fix': 'melos run prepare-env-${AppEnv.flavor}',
      },
    );

    throw mismatch;
  }

  /// Its own step, not part of [initFirebase]: the reporter is what names
  /// every failure after it, so it must not be skipped by one before it.
  static Future<void> initCrashReporting() async {
    await CrashReporter.init();
    // After init, so the first report SdLogger forwards has somewhere to go.
    SdCrashReporter.attach(const FirebaseCrashReporter());
    CrashReporter.setCustomKey('flavor', AppEnv.flavor);
  }

  static Future<void> initAnalytics() => AppAnalytics.init();

  /// iOS shows nothing for a push landing while the app is open unless it is told to — no banner, and no sound.
  static Future<void> initPushPresentation() =>
      FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

  /// Timezone DB, so reminders fire at local wall time. A failure below leaves
  /// `tz.local` at UTC, which is what reminders fall back to.
  static Future<void> initTimezone() async {
    tzdata.initializeTimeZones();

    final String localTz =
        (await FlutterTimezone.getLocalTimezone()).identifier;

    tz.setLocalLocation(tz.getLocation(localTz));
    SdLogger.info(LogTagConstant.bootstrap, 'Timezone set', {'tz': localTz});
  }

  /// "Anonymous by default": the app is fully usable without an account, but
  /// the callables behind it still need a caller.
  ///
  /// **Called from `SplashController`, and after the device check** — a wipe
  /// signs the old session out, so one opened ahead of it would be the session
  /// it deleted. Not a bootstrap step for the same reason: `getWeather` will
  /// not serve a caller it cannot name, and that call belongs under the dots
  /// rather than under the launch image.
  static Future<void> ensureAnonymousSession() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      await FirebaseAuth.instance.signInAnonymously();

      return;
    }

    // A cached user is not a session: the account behind it can be gone —
    // deleted from the console, or wiped with the project — and the client
    // goes on reporting signed_in while every callable answers
    // "unauthenticated". That state costs the user the whole weather feature
    // and says nothing on screen, so the token is what decides, not the cache.
    try {
      await user.getIdToken(true);
    } on FirebaseAuthException catch (error) {
      SdLogger.warning(
        LogTagConstant.bootstrap,
        'Cached session is dead; signing in again',
        <String, Object?>{'uid': user.uid, 'code': error.code},
      );
      await FirebaseAuth.instance.signOut();
      await FirebaseAuth.instance.signInAnonymously();
    }
  }
}
