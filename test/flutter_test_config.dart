import 'dart:async';

import 'package:system_design/common.dart';

/// Runs once per test file before its `main()`.
///
/// Silences the dev logger so [SdLogger] output never clutters the test
/// console (it defaults on in debug, which tests run as), and resets the
/// crash reporter to the package's no-op — a test that reached a real
/// Crashlytics would need Firebase, which widget tests boot without.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  SdLogger.enabled = false;
  SdCrashReporter.detach();
  await testMain();
}
