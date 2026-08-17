import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:system_design/common.dart';

import '../constants/log_tag_constant.dart';

/// Crash + non-fatal error reporting (Firebase Crashlytics).
///
/// **The two are no longer called side by side.** `SdLogger.error` now hands
/// every failure it prints to `SdCrashReporter.instance`, which
/// [FirebaseCrashReporter] points here — so one call both prints for the
/// developer and reports for the crashes nobody is watching. What is left on
/// this class is the part that is Crashlytics' alone and has no logging
/// equivalent: the global handlers, the cohort keys, the collection switch.
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
      // `recordError` below, not the one SdLogger would reach: this one is
      // fatal, and the log line is only here so a debug console shows what
      // the app just swallowed.
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

/// Points `SdLogger.error` at [CrashReporter].
///
/// The design system holds the `SdCrashReporter` contract and a no-op, and
/// deliberately no vendor — `firebase_crashlytics` is this app's dependency,
/// not the package's. This adapter is where the two meet, and it is the only
/// file that would change if the app ever reported somewhere else.
///
/// Attached once, from `AppBootstrap`, after [CrashReporter.init]. Until then
/// `SdLogger.error` reports to the no-op, which is what lets it be called from
/// a `domain/` service or a unit test without starting Firebase.
class FirebaseCrashReporter implements SdCrashReporter {
  const FirebaseCrashReporter();

  /// [reason] arrives already composed by `SdLogger` as `«tag» - «message» —
  /// «data»`, which is what makes a report findable in the dashboard by the
  /// flow it belongs to.
  @override
  void recordError(String reason, {Object? error, StackTrace? stackTrace}) {
    // A log line without a thrown object still deserves a report, and
    // Crashlytics needs *something* to title the issue — the composed reason
    // is the best available stand-in.
    CrashReporter.recordError(error ?? reason, stackTrace, reason: reason);
  }

  @override
  void setUserId(String? uid) => CrashReporter.setUserId(uid);
}
