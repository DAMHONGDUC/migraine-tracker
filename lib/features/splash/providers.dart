import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../core/env/app_fresh_install.dart';
import 'presentation/controllers/splash_controller.dart';

/// The device check, as the one thing `FreshInstallGate` waits on.
///
/// A `FutureProvider` so it runs once per launch however many times the gate
/// above it rebuilds — and so its result can be read later without running it
/// again.
///
/// Widget tests override it with a resolved value: no other build shares a
/// test process's sandbox, and a pending check would hold back every tree they
/// pump.
final freshInstallProvider = FutureProvider<SdFreshInstallOutcome>(
  AppFreshInstall.run,
);

final splashControllerProvider = Provider<SplashController>(
  (ref) => const SplashController(),
);
