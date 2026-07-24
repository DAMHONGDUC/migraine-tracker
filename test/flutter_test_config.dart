import 'dart:async';

import 'package:migraine_tracker/core/logging/app_logger.dart';

/// Runs once per test file before its `main()`. Silences the dev logger so
/// [AppLogger] output never clutters the test console (it defaults on in debug,
/// which tests run as).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppLogger.enabled = false;
  await testMain();
}
