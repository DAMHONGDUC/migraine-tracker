import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'app_logger.dart';

/// Crash + non-fatal error reporting (Firebase Crashlytics).
///
/// [AppLogger] is the *developer* console and is silent in release; this is
/// the production eye. Both are called at the same places: log for the
/// person running the app, report for the crashes nobody is watching.
///
/// PRIVACY: a report carries the stack trace, the custom keys set here and
/// the (opaque) Firebase Auth UID — never attack data. Keep [reason] strings
/// generic; they end up in a Google console.
///
/// Silent until [init] runs (only from `main`), so widget tests and pure
/// Dart code paths are no-ops instead of crashes.
abstract final class CrashReporter {
  static FirebaseCrashlytics? _crashlytics;

  static bool get isReady => _crashlytics != null;

  /// Installs the global handlers: uncaught Flutter framework errors and
  /// errors that escape to the platform dispatcher (async gaps, isolates).
  ///
  /// Collection is off in debug by default — local stack traces belong in
  /// the console, not in the release crash-free-rate metric.
  static Future<void> init({bool? collectionEnabled}) async {
    final FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;
    final bool enabled = collectionEnabled ?? !kDebugMode;
    final FlutterExceptionHandler? previousOnError = FlutterError.onError;

    await crashlytics.setCrashlyticsCollectionEnabled(enabled);
    _crashlytics = crashlytics;

    // Chains: `main`'s console handler still runs first, then this records the crash.
    FlutterError.onError = (FlutterErrorDetails details) {
      previousOnError?.call(details);
      crashlytics.recordFlutterFatalError(details);
    };

    // - Anything that escapes the framework: a failed async gap, a platform channel error.
    // - Returning true marks it handled, so the app survives.
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      AppLogger.error('Uncaught async error', error: error, stackTrace: stack);
      unawaited(crashlytics.recordError(error, stack, fatal: true));
      return true;
    };
  }

  /// A caught failure worth knowing about in production (weather fetch,
  /// alert registration, sync). Non-fatal: the app kept running.
  static void recordError(
    Object error,
    StackTrace? stackTrace, {
    required String reason,
  }) {
    unawaited(_crashlytics?.recordError(error, stackTrace, reason: reason));
  }

  /// Breadcrumb attached to the next report — the trail of what the user
  /// was doing before it broke. Screen names and action labels only.
  static void log(String message) => unawaited(_crashlytics?.log(message));

  /// The Firebase Auth UID (opaque), so a crash can be tied to a support
  /// request. Null on sign-out.
  static void setUserId(String? uid) =>
      unawaited(_crashlytics?.setUserIdentifier(uid ?? ''));

  /// Slices the crash list by cohort — e.g. `flavor`, `is_premium`.
  static void setCustomKey(String key, Object value) =>
      unawaited(_crashlytics?.setCustomKey(key, value));

  static void setCollectionEnabled(bool enabled) =>
      unawaited(_crashlytics?.setCrashlyticsCollectionEnabled(enabled));
}
