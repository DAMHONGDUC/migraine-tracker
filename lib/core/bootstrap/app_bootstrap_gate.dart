import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../bare_ease_app.dart';
import '../../features/splash/presentation/screens/splash_screen/splash_screen.dart';
import '../constants/log_tag_constant.dart';
import '../storage/secure_store.dart';
import '../theme/app_theme.dart';
import 'app_bootstrap.dart';

/// Startup, as a future the UI can wait on. Read once, by [AppBootstrapGate].
final appBootstrapProvider = FutureProvider<SecureStore>((ref) async {
  try {
    return await AppBootstrap.init();
  } catch (error, stackTrace) {
    // Only the two storage reads at the top of `init` can land here — everything after them guards itself. The app still has to open, and every value it holds has a default at its call site, so an empty store beats a dead launch.
    SdLogger.error(
      LogTagConstant.bootstrap,
      'Bootstrap failed, opening on an empty store',
      error: error,
      stackTrace: stackTrace,
    );

    return SecureStore.open();
  }
});

/// The splash while `AppBootstrap.init` runs, then the app.
///
/// Bootstrap used to finish before `runApp`, which meant the platform's launch screen stood in for it — nothing moving, and nothing saying the app had not hung. It runs under the splash now, so the wait is the same length but looks like work.
///
/// **Nothing of the app is built until it resolves.** `BaroEaseApp` installs listeners that read Firebase and the store on their first frame, and `FreshInstallGuard` has to have signed a reinstall out before any of them run.
class AppBootstrapGate extends ConsumerWidget {
  const AppBootstrapGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SecureStore> bootstrap = ref.watch(appBootstrapProvider);

    return switch (bootstrap) {
      // A child scope, because the store does not exist when the root one is created — the app below reads it synchronously, exactly as it did when `main` had it in hand.
      AsyncData(value: final SecureStore store) => ProviderScope(
        overrides: [secureStoreProvider.overrideWithValue(store)],
        child: const BaroEaseApp(),
      ),
      // A MaterialApp of its own: MediaQuery is what picks the 2×/3× icon, and there is no app above this to provide one.
      _ => MaterialApp(
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    };
  }
}
