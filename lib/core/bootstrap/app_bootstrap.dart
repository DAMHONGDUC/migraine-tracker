import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/common.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants/log_tag_constant.dart';
import '../../firebase_options.dart';
import '../analytics/app_analytics.dart';
import '../env/app_env.dart';
import '../logging/crash_reporter.dart';
import '../storage/fresh_install_guard.dart';
import '../storage/secure_store.dart';

/// One-time app initialization run before `runApp`.
final class AppBootstrap {
  const AppBootstrap._();

  /// Each step is guarded on its own, and deliberately NOT wrapped as a whole. Hands back the store `main` overrides the provider with.
  static Future<SecureStore> init() async {
    _installErrorLogging();

    // Both before Firebase: the first-launch guard runs inside it, and it needs the marker and the store already open.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final SecureStore store = await SecureStore.open();

    // - Firebase first so Crashlytics is up before anything else can fail. - It used to run last, which left a timezone failure reported nowhere.
    await _initFirebase(prefs, store);
    await _initTimezone();

    // One assert walking every required AppEnv value, so a missing --dart-define-from-file reports every gap at once.
    assert(
      AppEnv.missingConfigKeys.isEmpty,
      'Missing required config: ${AppEnv.missingConfigKeys.join(', ')}. '
      'Run with --dart-define-from-file=env/dev.json (or env/prod.json).',
    );

    return store;
  }

  static Future<void> _initFirebase(
    SharedPreferences prefs,
    SecureStore store,
  ) async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Immediately after initializeApp, ahead of Crashlytics, Analytics and messaging: each of those is an await that can throw, and the catch below would then swallow the purge along with it — leaving the reinstall signed in, which is the one thing this guard exists to prevent.
      await FreshInstallGuard.run(prefs, store, FirebaseAuth.instance.signOut);
      await CrashReporter.init();
      // After init, so the first report SdLogger forwards has somewhere to go.
      SdCrashReporter.attach(const FirebaseCrashReporter());
      CrashReporter.setCustomKey('flavor', AppEnv.flavor);
      await AppAnalytics.init();

      // iOS shows nothing for a push landing while the app is open unless it is told to — no banner, and no sound.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
      // After the guard, never before: a reinstall has to be signed out before anything signs it back in.
      await _ensureAnonymousSession();
    } catch (err, stackTrace) {
      SdLogger.error(
        LogTagConstant.bootstrap,
        'Firebase init failed',
        error: err,
        stackTrace: stackTrace,
      );
    }
  }

  /// "Anonymous by default": the app is fully usable without an account, but the callables behind it still need a caller.
  static Future<void> _ensureAnonymousSession() async {
    if (FirebaseAuth.instance.currentUser != null) return;

    await FirebaseAuth.instance.signInAnonymously();
  }

  /// Timezone DB, so reminders fire at local wall time.
  static Future<void> _initTimezone() async {
    tzdata.initializeTimeZones();

    try {
      final String localTz =
          (await FlutterTimezone.getLocalTimezone()).identifier;

      tz.setLocalLocation(tz.getLocation(localTz));
      SdLogger.info(LogTagConstant.bootstrap, 'App started', {'tz': localTz});
    } catch (err, stackTrace) {
      SdLogger.error(
        LogTagConstant.bootstrap,
        'Timezone init failed, reminders fall back to UTC',
        error: err,
        stackTrace: stackTrace,
      );
    }
  }

  /// Console logging for framework errors, installed before anything else so a failed Firebase init still leaves a usable debug build.
  static void _installErrorLogging() {
    final FlutterExceptionHandler? previousOnError = FlutterError.onError;

    FlutterError.onError = (FlutterErrorDetails details) {
      previousOnError?.call(details);
      SdLogger.error(
        LogTagConstant.bootstrap,
        'Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
      );
    };
  }
}
