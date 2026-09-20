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
/// **Nothing here writes a `try` of its own.** Every step is guarded and
/// logged by [SdBootstrap], and one of them failing must not take the launch
/// with it — a step that swallowed its own failure would report as started.
final class AppBootstrap {
  const AppBootstrap._();

  /// First, so Crashlytics is up before anything else can fail.
  ///
  /// Also the one moment both halves of the build's config exist in the same
  /// process, so it is where they are compared — see [FlavorConfigMismatch]
  /// for the trap. Inside this step rather than a step of its own:
  /// `Firebase.app()` throws `[core/no-app]` when the line above it did not
  /// run, so a separate step would have to re-derive whether it applies, which
  /// is a second copy of the same condition.
  static Future<void> initFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // The native half reporting what it actually loaded. Compared at runtime
    // rather than off the files: a file check answers "what is on disk", and a
    // plist cached in DerivedData or a hot restart after switching flavours
    // passes that one and fails this one.
    final String nativeProjectId = Firebase.app().options.projectId;

    // **A mismatch is refused; an absence never is.** A build with no Dart
    // config is an app whose backend is not set up yet, and a guard that fires
    // there breaks day one of a fresh clone — whoever hits it deletes the
    // guard rather than the cause.
    if (!AppEnv.hasFirebaseConfig) {
      SdLogger.warning(
        LogTagConstant.bootstrap,
        'No Firebase config in this build; skipping the flavour check',
        <String, String>{'nativeProjectId': nativeProjectId},
      );

      return;
    }

    if (nativeProjectId != AppEnv.firebaseProjectId) {
      // Thrown, not logged here: `SdBootstrap` logs every step that throws
      // with the error itself, and `toString` carries both ids and the
      // command — a line beside it would file the same failure twice. It
      // lands before the crash reporter step, so a build pointed at the wrong
      // project does not also send its crashes there.
      throw FlavorConfigMismatch(
        expected: AppEnv.firebaseProjectId,
        actual: nativeProjectId,
      );
    }
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
