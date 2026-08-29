import 'dart:async';

import 'package:system_design/common.dart';

/// Runs once per test file before its `main()`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  SdLogger.enabled = false;
  SdCrashReporter.detach();
  await testMain();
}
