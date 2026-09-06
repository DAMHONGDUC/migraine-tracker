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
import '../logging/crash_reporter.dart';

/// The work `main` hands to `SdBootstrap`, one method per step.
///
/// **Nothing here writes a `try` of its own.** Every step is guarded and
/// logged by [SdBootstrap], and one of them failing must not take the launch
/// with it — a step that swallowed its own failure would report as started.
final class AppBootstrap {
  const AppBootstrap._();

  /// First, so Crashlytics is up before anything else can fail.
  static Future<void> initFirebase() => Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
  static Future<void> initPushPresentation() => FirebaseMessaging.instance
      .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

  /// Timezone DB, so reminders fire at local wall time. A failure below leaves
  /// `tz.local` at UTC, which is what reminders fall back to.
  static Future<void> initTimezone() async {
    tzdata.initializeTimeZones();

    final String localTz = (await FlutterTimezone.getLocalTimezone()).identifier;

    tz.setLocalLocation(tz.getLocation(localTz));
    SdLogger.info(LogTagConstant.bootstrap, 'Timezone set', {'tz': localTz});
  }

  /// "Anonymous by default": the app is fully usable without an account, but
  /// the callables behind it still need a caller.
  ///
  /// **After the device check, never before it.** A wipe signs the old session
  /// out, and one opened ahead of it would be the session it deleted.
  /// `SplashController` calls this again as the retry for a launch that had no
  /// network — `getWeather` will not serve a caller it cannot name.
  static Future<void> ensureAnonymousSession() async {
    if (FirebaseAuth.instance.currentUser != null) return;

    await FirebaseAuth.instance.signInAnonymously();
  }
}
