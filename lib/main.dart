import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'bare_ease_app.dart';
import 'core/analytics/app_analytics.dart';
import 'core/env/app_env.dart';
import 'core/l10n/locale_provider.dart';
import 'core/logging/app_logger.dart';
import 'core/logging/crash_reporter.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _AppBootstrap.init();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const BaroEaseApp(),
    ),
  );
}

/// One-time app initialization run before `runApp`: the timezone DB used to
/// schedule reminders at local wall time, Firebase, then crash reporting and
/// analytics on top of it.
abstract final class _AppBootstrap {
  static Future<void> init() async {
    _installErrorLogging();

    // Timezone DB for scheduling daily medication reminders at local wall
    // time. Before Firebase: reminders must survive a backend that isn't
    // reachable (or configured).
    final String localTz =
        (await FlutterTimezone.getLocalTimezone()).identifier;

    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(localTz));
    AppLogger.info('App started', {'tz': localTz});

    try {
      assert(AppEnv.hasFirebaseConfig, AppEnv.missingConfigMessage);

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Crash reporting first, so anything the rest of the bootstrap throws
      // is already being recorded.
      await CrashReporter.init();
      CrashReporter.setCustomKey('flavor', AppEnv.flavor);
      await AppAnalytics.init();
    } catch (err, stackTrace) {
      AppLogger.error(
        'Firebase init failed',
        error: err,
        stackTrace: stackTrace,
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
