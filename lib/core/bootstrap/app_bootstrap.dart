import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../firebase_options.dart';
import '../analytics/app_analytics.dart';
import '../env/app_env.dart';
import '../logging/app_logger.dart';
import '../logging/crash_reporter.dart';

/// One-time app initialization run before `runApp`: Firebase with crash
/// reporting and analytics on top of it, then the timezone DB used to
/// schedule reminders at local wall time.
final class AppBootstrap {
  const AppBootstrap._();

  /// Each step is guarded on its own, and deliberately NOT wrapped as a
  /// whole: these concerns are independent, and one `try` around all of them
  /// would let the first failure skip everything after it — including the
  /// crash reporting that would have told us about it.
  static Future<void> init() async {
    _installErrorLogging();

    // - Firebase first so Crashlytics is up before anything else can fail.
    // - It used to run last, which left a timezone failure reported nowhere.
    await _initFirebase();
    await _initTimezone();

    // One assert walking every required AppEnv value, replacing the old
    // per-field asserts — a missing --dart-define-from-file flag reports
    // every gap at once instead of failing on the first field checked.
    //
    // Debug only: Dart strips asserts from release, which is the build where
    // the flag actually goes missing. `melos run release-ios` is the guard
    // that matters there.
    assert(
      AppEnv.missingConfigKeys.isEmpty,
      'Missing required config: ${AppEnv.missingConfigKeys.join(', ')}. '
      'Run with --dart-define-from-file=env/dev.json (or env/prod.json).',
    );
  }

  static Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await CrashReporter.init();
      CrashReporter.setCustomKey('flavor', AppEnv.flavor);
      await AppAnalytics.init();

      // iOS shows nothing at all for a push that lands while the app is
      // open unless it is told to — no banner and, the part people notice,
      // no sound. Local reminders ask for the same thing per notification
      // (`presentSound`); a push has no such field, so it is set once here.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
      await _ensureAnonymousSession();
    } catch (err, stackTrace) {
      AppLogger.error(
        'Firebase init failed',
        error: err,
        stackTrace: stackTrace,
      );
    }
  }

  /// "Anonymous by default": the app is fully usable without an account, but
  /// the callables behind it still need a caller.
  ///
  /// `getWeather` is why. Weather is free (hard rule 1) and is what pairs a
  /// logged attack with the pressure at that moment, but the endpoint spends
  /// our WeatherKit key, so it will not serve a caller it cannot name. Without
  /// this a fresh install got no forecast and no pressure on a logged attack,
  /// both failing silently as "no weather".
  ///
  /// Awaited rather than fired off: a race would show that empty state on
  /// first launch and nowhere else, which is the kind of bug reproduced once
  /// and never again. Firebase persists the session, so this is one network
  /// call on first launch and a no-op after.
  ///
  /// **Needs Anonymous enabled in the Firebase console.** Without it this
  /// throws `admin-restricted-operation`, which the caller's guard swallows —
  /// the app still starts, and weather is simply dead.
  static Future<void> _ensureAnonymousSession() async {
    if (FirebaseAuth.instance.currentUser != null) return;

    await FirebaseAuth.instance.signInAnonymously();
  }

  /// Timezone DB, so reminders fire at local wall time.
  ///
  /// Guarded because it runs before `runApp`: an unhandled throw here does
  /// not show an error screen, it stops the app from starting at all. A
  /// device can report an identifier this database has never heard of, and
  /// that must not be the difference between a working app and a dead one.
  ///
  /// The fallback leaves `tz.local` at UTC, so reminders would fire at the
  /// wrong hour rather than not at all — worse than correct, better than an
  /// app that will not open, and reported either way so it does not stay
  /// invisible.
  static Future<void> _initTimezone() async {
    tzdata.initializeTimeZones();

    try {
      final String localTz =
          (await FlutterTimezone.getLocalTimezone()).identifier;

      tz.setLocalLocation(tz.getLocation(localTz));
      AppLogger.info('App started', {'tz': localTz});
    } catch (err, stackTrace) {
      AppLogger.error(
        'Timezone init failed, reminders fall back to UTC',
        error: err,
        stackTrace: stackTrace,
      );
      CrashReporter.recordError(
        err,
        stackTrace,
        reason: 'Timezone init failed, reminders fall back to UTC',
      );
    }
  }

  /// Console logging for framework errors, installed before anything else so
  /// a failed Firebase init still leaves a usable debug build.
  /// [CrashReporter.init] chains onto this handler and adds the reporting.
  static void _installErrorLogging() {
    final FlutterExceptionHandler? previousOnError = FlutterError.onError;

    FlutterError.onError = (FlutterErrorDetails details) {
      previousOnError?.call(details);
      AppLogger.error(
        'Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
      );
    };
  }
}
