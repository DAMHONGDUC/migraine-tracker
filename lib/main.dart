import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import 'bare_ease_app.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/constants/log_tag_constant.dart';
import 'core/env/app_env.dart';
import 'core/storage/secure_store.dart';

/// The launch, as a list of *what* happens — [SdBootstrap] owns the guarding,
/// the logging, the three framework error hooks and `runApp`.
///
/// **Nothing slow is in this list.** Every step runs before the first frame,
/// where the only thing on screen is the platform launch image; the device
/// check and the anonymous session are behind the splash instead, under
/// something moving.
Future<void> main() async {
  // One assert walking every required AppEnv value, so a missing
  // --dart-define-from-file reports every gap at once. Outside the steps
  // deliberately: a step guard would log it and start the app anyway.
  assert(
    AppEnv.missingConfigKeys.isEmpty,
    'Missing required config: ${AppEnv.missingConfigKeys.join(', ')}. '
    'Run with --dart-define-from-file=env/dev.json (or env/prod.json).',
  );

  late final SecureStore store;

  await SdBootstrap.run(
    logTag: LogTagConstant.bootstrap,
    steps: <SdBootstrapStep>[
      // Never throws — it answers a failed read with an empty store.
      SdBootstrapStep(
        name: 'Secure store',
        run: () async => store = await SecureStore.open(),
      ),
      SdBootstrapStep(name: 'Firebase', run: AppBootstrap.initFirebase),
      SdBootstrapStep(
        name: 'Crash reporting',
        run: AppBootstrap.initCrashReporting,
      ),
      SdBootstrapStep(name: 'Analytics', run: AppBootstrap.initAnalytics),
      SdBootstrapStep(name: 'Push', run: AppBootstrap.initPushPresentation),
      SdBootstrapStep(name: 'Timezone', run: AppBootstrap.initTimezone),
    ],
    builder: () => ProviderScope(
      overrides: [secureStoreProvider.overrideWithValue(store)],
      child: const BaroEaseApp(),
    ),
  );
}
