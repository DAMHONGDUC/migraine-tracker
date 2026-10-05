import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:system_design/common.dart';

import '../constants/log_tag_constant.dart';

/// Crash + non-fatal error reporting (Firebase Crashlytics).
abstract final class CrashReporter {
  static FirebaseCrashlytics? _crashlytics;

  static bool get isReady => _crashlytics != null;

  /// Installs the global handlers: uncaught Flutter framework errors and errors that escape to the platform dispatcher (async gaps, isolates).
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

    // - Anything that escapes the framework: a failed async gap, a platform channel error. - Returning true marks it handled, so the app survives.
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      // `recordError` below, not the one SdLogger would reach.
      SdLogger.error(
        LogTagConstant.bootstrap,
        'Uncaught async error',
        error: error,
        stackTrace: stack,
      );
      unawaited(crashlytics.recordError(error, stack, fatal: true));
      return true;
    };
  }

  /// A caught failure worth knowing about in production (weather fetch, alert registration, sync). Non-fatal: the app kept running.
  static void recordError(
    Object error,
    StackTrace? stackTrace, {
    required String reason,
  }) {
    unawaited(_crashlytics?.recordError(error, stackTrace, reason: reason));
  }

  /// Breadcrumb attached to the next report — the trail of what the user was doing before it broke. Screen names and action labels only.
  static void log(String message) => unawaited(_crashlytics?.log(message));

  /// The Firebase Auth UID (opaque), so a crash can be tied to a support request. Null on sign-out.
  static void setUserId(String? uid) =>
      unawaited(_crashlytics?.setUserIdentifier(uid ?? ''));

  /// Slices the crash list by cohort — e.g. `flavor`, `is_premium`.
  static void setCustomKey(String key, Object value) =>
      unawaited(_crashlytics?.setCustomKey(key, value));

  static void setCollectionEnabled(bool enabled) =>
      unawaited(_crashlytics?.setCrashlyticsCollectionEnabled(enabled));

  /// Whether reports leave the device: off in debug builds, on in release.
  static bool get isCollectionEnabled =>
      _crashlytics?.isCrashlyticsCollectionEnabled ?? false;

  /// Dev menu: a non-fatal, so a build is checked end to end without waiting for a real failure.
  ///
  /// **Sent on the next launch, not now**: iOS Crashlytics batches recorded
  /// errors into the session's report and uploads it when the app next opens
  /// (seen 2026-10-05: recorded 21:38, uploaded on the 21:45 relaunch).
  ///
  /// Collection is switched on first, since a debug build starts with it off;
  /// the next launch's [init] puts it back.
  static Future<void> sendTestError() async {
    final FirebaseCrashlytics crashlytics = _requireReady();

    await crashlytics.setCrashlyticsCollectionEnabled(true);
    await crashlytics.recordError(
      const CrashlyticsTestException('non-fatal'),
      StackTrace.current,
      reason: 'Dev menu Crashlytics test',
    );
  }

  /// Dev menu: a NATIVE crash, the kind a real one is. The app closes; the report is sent on the next launch.
  ///
  /// Not caught by Crashlytics while a debugger is attached — launch from the home screen.
  static Future<void> crashForTest() async {
    final FirebaseCrashlytics crashlytics = _requireReady();

    await crashlytics.setCrashlyticsCollectionEnabled(true);
    crashlytics.crash();
  }

  static FirebaseCrashlytics _requireReady() =>
      _crashlytics ??
      (throw StateError('Crashlytics did not start: the Firebase step failed'));
}

/// What the dev menu's Crashlytics test records, so it is filtered out of the real issues at a glance.
class CrashlyticsTestException implements Exception {
  const CrashlyticsTestException(this.kind);

  final String kind;

  @override
  String toString() => 'CrashlyticsTestException: $kind (dev menu test)';
}

/// Points `SdLogger.error` at [CrashReporter].
class FirebaseCrashReporter implements SdCrashReporter {
  const FirebaseCrashReporter();

  /// [reason] arrives already composed by `SdLogger` as `«tag».
  @override
  void recordError(String reason, {Object? error, StackTrace? stackTrace}) {
    // A log line without a thrown object still deserves a report, and Crashlytics needs *something* to title the issue.
    CrashReporter.recordError(error ?? reason, stackTrace, reason: reason);
  }

  @override
  void setUserId(String? uid) => CrashReporter.setUserId(uid);
}
