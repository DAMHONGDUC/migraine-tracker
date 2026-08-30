import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../features/attacks/presentation/screens/attack_detail_screen/attack_detail_screen.dart';
import '../../features/attacks/presentation/screens/log_screen/log_screen.dart';
import '../../features/auth/presentation/screens/account_screen/account_screen.dart';
import '../../features/auth/presentation/screens/login_screen/login_screen.dart';
import '../../features/auth/providers.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen/dashboard_screen.dart';
import '../../features/history/presentation/screens/history_screen/history_screen.dart';
import '../../features/insights/presentation/screens/activity_screen/activity_screen.dart';
import '../../features/insights/presentation/screens/insights_screen/insights_screen.dart';
import '../../features/insights/presentation/screens/sleep_screen/sleep_screen.dart';
import '../../features/medications/presentation/screens/medication_detail_screen/medication_detail_screen.dart';
import '../../features/medications/presentation/screens/medications_screen/medications_screen.dart';
import '../../features/notifications/presentation/screens/notification_detail_screen/notification_detail_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen/onboarding_screen.dart';
import '../../features/premium/presentation/screens/paywall_screen/paywall_screen.dart';
import '../../features/premium/presentation/screens/subscription_screen/subscription_screen.dart';
import '../../features/settings/presentation/screens/about_screen/about_screen.dart';
import '../../features/settings/presentation/screens/contact_screen/contact_screen.dart';
import '../../features/settings/presentation/screens/export_preview_screen/export_preview_screen.dart';
import '../../features/settings/presentation/screens/export_screen/export_screen.dart';
import '../../features/settings/presentation/screens/settings_screen/settings_screen.dart';
import '../../features/sync/presentation/screens/sync_screen/sync_screen.dart';
import '../analytics/app_analytics.dart';
import '../constants/prefs_key_constant.dart';
import '../storage/secure_store.dart';
import '../widgets/weather/weather_card.dart';
import 'app_shell.dart';

/// One route's identity: go_router [name] and URL [path] defined together so they can never drift apart.
class AppRoute {
  const AppRoute({required this.name, required this.path});

  final String name;
  final String path;
}

final class AppRoutes {
  static const onboarding = AppRoute(name: 'onboarding', path: '/onboarding');
  static const dashboard = AppRoute(name: 'dashboard', path: '/dashboard');
  static const log = AppRoute(name: 'log', path: '/log');
  static const history = AppRoute(name: 'history', path: '/history');
  static const insights = AppRoute(name: 'insights', path: '/insights');
  static const settings = AppRoute(name: 'settings', path: '/settings');
  static const medications = AppRoute(
    name: 'medications',
    path: '/medications',
  );

  /// The notification list, pushed from the dashboard's app bar.
  static const notifications = AppRoute(
    name: 'notifications',
    path: '/notifications',
  );

  /// One notification in full, pushed from the list. Path parameter: [notificationIdParam].
  static const notification = AppRoute(
    name: 'notificationDetail',
    path: '/notification/:id',
  );
  static const notificationIdParam = 'id';

  /// Detail of one logged attack, pushed from History. Path parameter: [attackIdParam].
  static const attack = AppRoute(name: 'attackDetail', path: '/attack/:id');
  static const attackIdParam = 'id';

  /// One medication and its reminders, pushed from the medications list and from the dashboard's next-reminder banner. Path parameter: [medicationIdParam].
  static const medication = AppRoute(
    name: 'medicationDetail',
    path: '/medication/:id',
  );
  static const medicationIdParam = 'id';

  /// Every weather reading named, and the ten-day rainfall forecast.
  static const weather = AppRoute(name: 'weatherDetail', path: '/weather');

  static const paywall = AppRoute(name: 'paywall', path: '/paywall');

  /// Optional sign-in, pushed from Settings and from any premium gate. Pops `true` once an account exists (see [LoginScreen]).
  static const login = AppRoute(name: 'login', path: '/login');

  /// The signed-in user's own record, pushed from Settings. Guarded by the redirect below — there is no account to look at while signed out.
  static const account = AppRoute(name: 'account', path: '/account');

  /// Subscription detail, pushed from Settings. [paywall] is the purchase sheet; this is the status page that leads to it.
  static const premium = AppRoute(name: 'premium', path: '/premium');

  /// Sync status and the manual run, pushed from Settings. Guarded by the redirect below, like [account]: there is nowhere to sync to without one.
  static const sync = AppRoute(name: 'sync', path: '/sync');

  /// Export data and the history of past exports, pushed from Settings.
  static const export = AppRoute(name: 'export', path: '/export');

  /// What is inside one past export, pushed from the history's actions sheet. Path parameter: [exportIdParam].
  static const exportPreview = AppRoute(
    name: 'exportPreview',
    path: '/export/:id',
  );
  static const exportIdParam = 'id';

  /// Forecast, correlation and the alert controls together. Pushed from Insights' pressure card and from the Settings row.

  /// Exertion, steps and the step connect switch. Pushed from Insights' activity card and from the Settings row.
  static const activity = AppRoute(name: 'activity', path: '/activity');

  /// The sleep insight and its connect switch. Pushed from Insights' sleep card and from the Settings row.
  static const sleep = AppRoute(name: 'sleep', path: '/sleep');

  /// Support email, pushed from Settings' About section.
  static const contact = AppRoute(name: 'contact', path: '/contact');

  /// What the app is and everything it does, pushed from the same section.
  static const about = AppRoute(name: 'about', path: '/about');
}

/// The router's own navigator.
final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(debugLabel: 'root'),
);

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: ref.watch(rootNavigatorKeyProvider),
    initialLocation: AppRoutes.dashboard.path,
    // - `screen_view` for pushed routes (log, login, paywall, attack detail). - Empty outside a Firebase build — tabs are logged by hand in AppShell instead.
    observers: AppAnalytics.navigatorObservers,
    // First launch lands on onboarding until completed; afterwards /onboarding is never reachable again.
    redirect: (context, state) {
      final done =
          ref
              .read(secureStoreProvider)
              .getBool(PrefsKeyConstant.onboardingCompleted) ??
          false;
      final onOnboarding = state.matchedLocation == AppRoutes.onboarding.path;
      if (!done && !onOnboarding) return AppRoutes.onboarding.path;
      if (done && onOnboarding) return AppRoutes.dashboard.path;
      // Signing out (or a deep link without an account) must not land on a screen with nothing to show.
      final needsAccount =
          state.matchedLocation == AppRoutes.account.path ||
          state.matchedLocation == AppRoutes.sync.path;
      if (needsAccount && !ref.read(isSignedInProvider)) {
        return AppRoutes.dashboard.path;
      }
      return null;
    },
    routes: [
      GoRoute(
        name: AppRoutes.onboarding.name,
        path: AppRoutes.onboarding.path,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        name: AppRoutes.attack.name,
        path: AppRoutes.attack.path,
        builder: (context, state) => AttackDetailScreen(
          attackId: state.pathParameters[AppRoutes.attackIdParam]!,
        ),
      ),
      GoRoute(
        name: AppRoutes.weather.name,
        path: AppRoutes.weather.path,
        builder: (context, state) =>
            WeatherDetailScreen(args: state.extra! as WeatherDetailArgs),
      ),
      GoRoute(
        name: AppRoutes.medication.name,
        path: AppRoutes.medication.path,
        builder: (context, state) => MedicationDetailScreen(
          medicationId: state.pathParameters[AppRoutes.medicationIdParam]!,
        ),
      ),
      // - Full-screen pushed route (opened from the dashboard's log button), not a tab — no distractions, own step progress lives in the screen.
      GoRoute(
        name: AppRoutes.log.name,
        path: AppRoutes.log.path,
        builder: (context, state) => const LogScreen(),
      ),
      GoRoute(
        name: AppRoutes.login.name,
        path: AppRoutes.login.path,
        builder: (context, state) => const LoginScreen(),
      ),
      // Both pushed from Settings, so they cover the tab bar and return to where they opened from.
      GoRoute(
        name: AppRoutes.account.name,
        path: AppRoutes.account.path,
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        name: AppRoutes.sync.name,
        path: AppRoutes.sync.path,
        builder: (context, state) => const SyncScreen(),
      ),
      GoRoute(
        name: AppRoutes.premium.name,
        path: AppRoutes.premium.path,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        name: AppRoutes.export.name,
        path: AppRoutes.export.path,
        builder: (context, state) => const ExportScreen(),
      ),
      GoRoute(
        name: AppRoutes.exportPreview.name,
        path: AppRoutes.exportPreview.path,
        builder: (context, state) => ExportPreviewScreen(
          exportId: state.pathParameters[AppRoutes.exportIdParam]!,
        ),
      ),
      GoRoute(
        name: AppRoutes.activity.name,
        path: AppRoutes.activity.path,
        builder: (context, state) => const ActivityScreen(),
      ),
      GoRoute(
        name: AppRoutes.sleep.name,
        path: AppRoutes.sleep.path,
        builder: (context, state) => const SleepScreen(),
      ),
      GoRoute(
        name: AppRoutes.notifications.name,
        path: AppRoutes.notifications.path,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        name: AppRoutes.notification.name,
        path: AppRoutes.notification.path,
        builder: (context, state) => NotificationDetailScreen(
          notificationId: state.pathParameters[AppRoutes.notificationIdParam]!,
        ),
      ),
      GoRoute(
        name: AppRoutes.contact.name,
        path: AppRoutes.contact.path,
        builder: (context, state) => const ContactScreen(),
      ),
      GoRoute(
        name: AppRoutes.about.name,
        path: AppRoutes.about.path,
        builder: (context, state) => const AboutScreen(),
      ),
      // - Presents as a modal bottom sheet: transparent route, dim barrier, content covers ~80% (see PaywallScreen). - Tap above the sheet dismisses.
      GoRoute(
        name: AppRoutes.paywall.name,
        path: AppRoutes.paywall.path,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          opaque: false,
          barrierColor: AppColors.barrier,
          barrierDismissible: true,
          barrierLabel: MaterialLocalizations.of(
            context,
          ).modalBarrierDismissLabel,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
                position: animation.drive(
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeOutCubic)),
                ),
                child: child,
              ),
          child: const PaywallScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.dashboard.name,
                path: AppRoutes.dashboard.path,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.history.name,
                path: AppRoutes.history.path,
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.medications.name,
                path: AppRoutes.medications.path,
                builder: (context, state) => const MedicationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.insights.name,
                path: AppRoutes.insights.path,
                builder: (context, state) => const InsightsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.settings.name,
                path: AppRoutes.settings.path,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
