import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'bare_ease_app.dart';
import 'core/env/app_env.dart';
import 'core/l10n/locale_provider.dart';
import 'core/logging/app_logger.dart';
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

/// One-time app initialization run before `runApp`: crash logging, Firebase,
/// and the timezone DB used to schedule reminders at local wall time.
abstract final class _AppBootstrap {
  static Future<void> init() async {
    try {
      final previousOnError = FlutterError.onError;
      final localTz = await FlutterTimezone.getLocalTimezone();

      FlutterError.onError = (details) {
        previousOnError?.call(details);
        AppLogger.error(
          'Flutter framework error',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      assert(AppEnv.hasFirebaseConfig, AppEnv.missingConfigMessage);

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Timezone DB for scheduling daily medication reminders at local wall
      // time.
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(localTz.identifier));

      AppLogger.info('App started', {'tz': localTz.identifier});
    } catch (err) {
      AppLogger.error('App started', error: err);
    }
  }
}
