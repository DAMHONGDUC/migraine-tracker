import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'core/widgets/dismiss_keyboard_on_tap.dart';
import 'features/app_update/presentation/widgets/force_update_wrapper.dart';
import 'features/attacks/domain/entities/attack.dart';
import 'features/attacks/providers.dart';
import 'features/auth/domain/entities/auth_user.dart';
import 'features/auth/providers.dart';
import 'features/home_widget/presentation/widgets/home_widget_tap_listener.dart';
import 'features/home_widget/providers.dart';
import 'features/notifications/presentation/widgets/notification_tap_listener.dart';
import 'features/notifications/providers.dart';
import 'features/premium/providers.dart';
import 'features/sync/providers.dart';
import 'features/weather/providers.dart';
import 'l10n/gen/app_localizations.dart';

class BaroEaseApp extends HookConsumerWidget {
  const BaroEaseApp({super.key});

  /// Today's pressure reading, then the home-screen widget that shows it.
  ///
  /// In that order, not side by side: the widget reads the row the recorder
  /// writes, so racing the two leaves it drawing yesterday's number until the
  /// next launch.
  Future<void> _recordPressureThenRedraw(WidgetRef ref) async {
    await ref.read(dailyPressureRecorderProvider).recordToday();
    await _redrawHomeWidget(ref);
  }

  /// The home-screen widget, best-effort.
  ///
  /// Swallowed rather than rethrown, unlike the controller it calls: every
  /// caller here runs unawaited from the app root, where a throw has no
  /// screen to land on and would take app start with it. The controller has
  /// already logged whatever went wrong.
  Future<void> _redrawHomeWidget(WidgetRef ref) async {
    try {
      await ref.read(homeWidgetControllerProvider.notifier).refresh();
    } catch (_) {
      // Already logged where it happened.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeControllerProvider);

    // One backfill pass per app start: attacks logged offline get their weather snapshot once back online.
    useEffect(() {
      unawaited(ref.read(weatherAttachServiceProvider).backfillMissing());
      return null;
    }, const []);

    // One pressure reading per day, attack or not — the denominator the
    // correlation compares against. Fetches at most once per local day.
    useEffect(() {
      unawaited(_recordPressureThenRedraw(ref));
      return null;
    }, const []);

    // - Reminder notifications are derived, not recorded as they fire, so
    //   this catches up the ones that came round while the app was closed.
    // - Needs no account: reminders are on-device, so it works signed out.
    useEffect(() {
      unawaited(ref.read(notificationsControllerProvider).materialise());
      return null;
    }, const []);

    // The alert half of the same catch-up: the push handler below only runs
    // with the app open, so an alert the user never tapped would otherwise
    // never reach this device's list.
    useEffect(() {
      unawaited(ref.read(notificationsControllerProvider).reconcileLastAlert());
      return null;
    }, const []);

    // A pressure alert arriving while the app is open: record it now, so the
    // list has it before the user looks. One arriving while the app is shut
    // comes from whichever device did see it (hard rule 16).
    useEffect(() {
      final StreamSubscription<RemoteMessage> messages = FirebaseMessaging
          .onMessage
          .listen(
            (RemoteMessage message) => unawaited(
              ref
                  .read(notificationsControllerProvider)
                  .recordPush(message.data),
            ),
          );
      return messages.cancel;
    }, const []);

    // Coming back from the background counts as entering the app: another
    // device may have logged something while this one was away, and
    // reminders will have come round while it slept.
    useEffect(() {
      final AppLifecycleListener listener = AppLifecycleListener(
        onResume: () {
          unawaited(ref.read(syncControllerProvider.notifier).sync());
          unawaited(ref.read(notificationsControllerProvider).materialise());
          unawaited(
            ref.read(notificationsControllerProvider).reconcileLastAlert(),
          );
          // Covers the app left open across midnight.
          unawaited(_recordPressureThenRedraw(ref));
          // A location permission granted in the Settings app is answered
          // while the app is not running, so only a re-read finds out.
          ref.invalidate(locationPermissionProvider);
        },
      );
      return listener.dispose;
    }, const []);

    // - The widget's week count comes from the attack list, so it redraws
    //   whenever that list moves — a fresh log, an edit, a sync pull.
    // - The language too: it is native and cannot reach the ARB files.
    ref.listen<AsyncValue<List<Attack>>>(
      attacksStreamProvider,
      (previous, next) => unawaited(_redrawHomeWidget(ref)),
    );
    ref.listen<Locale?>(
      localeControllerProvider,
      (previous, next) => unawaited(_redrawHomeWidget(ref)),
    );

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
      // - Anonymous sessions stay unbound, and buy under RevenueCat's own anonymous id — signing in later carries the purchase over.
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
        // - Outermost, so a tap on nothing puts the keyboard away everywhere.
        // - Then: is this build still allowed to run (ForceUpdateWrapper), and
        //   a notification tap wherever the user is (NotificationTapListener).
        builder: (context, child) => DismissKeyboardOnTap(
          child: NotificationTapListener(
            child: HomeWidgetTapListener(
              child: ForceUpdateWrapper(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
