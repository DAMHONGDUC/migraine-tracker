import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/index.dart';

import 'bare_ease_app.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/constants/log_tag_constant.dart';
import 'core/env/app_env.dart';
import 'core/env/app_fresh_install.dart';
import 'core/storage/secure_store.dart';

/// The launch, as a list of *what* happens — [SdBootstrap] owns the guarding,
/// the logging, the three framework error hooks and `runApp`.
Future<void> main() async {
  // One assert walking every required AppEnv value, so a missing
  // --dart-define-from-file reports every gap at once. Outside the steps
  // deliberately: a step guard would log it and start the app anyway.
  assert(
    AppEnv.missingConfigKeys.isEmpty,
    'Missing required config: ${AppEnv.missingConfigKeys.join(', ')}. '
    'Run with --dart-define-from-file=env/dev.json (or env/prod.json).',
  );

  late final ProviderContainer container;
  SharedPreferences? prefs;

  await SdBootstrap.run(
    logTag: LogTagConstant.bootstrap,
    steps: <SdBootstrapStep>[
      SdBootstrapStep(
        name: 'Storage',
        run: () async {
          // Never throws — it answers a failed read with an empty store.
          final SecureStore store = await SecureStore.open();

          container = ProviderContainer(
            overrides: [secureStoreProvider.overrideWithValue(store)],
          );
          prefs = await SharedPreferences.getInstance();
        },
      ),
      SdBootstrapStep(name: 'Firebase', run: AppBootstrap.initFirebase),
      SdBootstrapStep(
        name: 'Crash reporting',
        run: AppBootstrap.initCrashReporting,
      ),
      SdBootstrapStep(name: 'Analytics', run: AppBootstrap.initAnalytics),
      SdBootstrapStep(name: 'Push', run: AppBootstrap.initPushPresentation),
      SdBootstrapStep(name: 'Timezone', run: AppBootstrap.initTimezone),
      // Before the session below and before the first frame: the wipe drops a
      // Firestore cache, which cannot be done once anything has read.
      SdBootstrapStep(
        name: 'Device check',
        run: () async {
          final SharedPreferences? loaded = prefs;

          if (loaded == null) {
            // The step above failed, so the stamp cannot be read or written.
            // Starting unchecked beats starting not at all.
            SdLogger.warning(
              LogTagConstant.bootstrap,
              'Device check skipped, preferences unavailable',
            );

            return;
          }
          await AppFreshInstall.run(container, loaded);
        },
      ),
      SdBootstrapStep(name: 'Session', run: AppBootstrap.ensureAnonymousSession),
    ],
    builder: () => UncontrolledProviderScope(
      container: container,
      child: const BaroEaseApp(),
    ),
  );
}
