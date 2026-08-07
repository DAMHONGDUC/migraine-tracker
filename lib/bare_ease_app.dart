import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/analytics/app_analytics.dart';
import 'core/l10n/locale_provider.dart';
import 'core/logging/crash_reporter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/theme/app_theme.dart';
import 'features/app_update/presentation/widgets/force_update_wrapper.dart';
import 'features/attacks/providers.dart';
import 'features/auth/domain/entities/auth_user.dart';
import 'features/auth/providers.dart';
import 'features/premium/providers.dart';
import 'features/sync/providers.dart';
import 'l10n/gen/app_localizations.dart';

class BaroEaseApp extends HookConsumerWidget {
  const BaroEaseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeControllerProvider);

    // One backfill pass per app start: attacks logged offline get their weather snapshot once back online.
    useEffect(() {
      unawaited(ref.read(weatherAttachServiceProvider).backfillMissing());
      return null;
    }, const []);

    // Coming back from the background counts as entering the app: another
    // device may have logged something while this one was away.
    useEffect(() {
      final AppLifecycleListener listener = AppLifecycleListener(
        onResume: () =>
            unawaited(ref.read(syncControllerProvider.notifier).sync()),
      );
      return listener.dispose;
    }, const []);

    // Keeps analytics/crash identity in step with the account — UID is opaque, null once signed out.
    ref.listen<AsyncValue<AuthUser?>>(authUserProvider, (previous, next) {
      final AuthUser? user = switch (next) {
        AsyncData(value: final AuthUser? value) => value,
        _ => null,
      };

      AppAnalytics.setUser(uid: user?.uid, signedIn: user?.isSignedIn ?? false);
      CrashReporter.setUserId(user?.uid);
      // Sign-in, and every launch of a signed-in session: keep the account doc in step with the provider.
      if (user != null) {
        unawaited(ref.read(accountControllerProvider).syncProfile(user));
      }
      // - Same moments for attack sync: sign-in, and each launch of a signed-in session.
      // - Unawaited and best-effort, exactly like the profile write above — nothing on screen waits on it.
      if (user?.isSignedIn == true) {
        unawaited(ref.read(syncControllerProvider.notifier).sync());
      } else {
        unawaited(ref.read(syncControllerProvider.notifier).onSignedOut());
      }
      // - Bind purchases to the account so an entitlement follows the person, not the install — survives a reinstall or a second device.
      // - Anonymous sessions stay unbound: nothing durable to attach a purchase to yet.
      unawaited(
        ref
            .read(purchaseIdentityProvider)
            .sync(user?.isSignedIn == true ? user!.uid : null),
      );
    });
    ref.listen<bool>(hasPremiumProvider, (previous, next) {
      AppAnalytics.setPremium(next);
      CrashReporter.setCustomKey('is_premium', next);
    });

    return ScreenUtilInit(
      // iPhone 14/15/16-class logical size; .w/.h/.sp/.r scale from this.
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        // Fits-on-screen content must not scroll/bounce (calm UI).
        scrollBehavior: const AppScrollBehavior(),
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        locale: locale,
        routerConfig: router,
        // Wraps every route: checks on each entry whether this build is still allowed to run (see ForceUpdateWrapper).
        builder: (context, child) =>
            ForceUpdateWrapper(child: child ?? const SizedBox.shrink()),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
