import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/attacks/presentation/screens/attack_detail_screen/attack_detail_screen.dart';
import '../../features/attacks/presentation/screens/log_screen/log_screen.dart';
import '../../features/auth/presentation/screens/account_screen/account_screen.dart';
import '../../features/auth/presentation/screens/login_screen/login_screen.dart';
import '../../features/auth/providers.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen/dashboard_screen.dart';
import '../../features/history/presentation/screens/history_screen/history_screen.dart';
import '../../features/insights/presentation/screens/insights_screen/insights_screen.dart';
import '../../features/medications/presentation/screens/medications_screen/medications_screen.dart';
import '../../features/onboarding/presentation/controllers/onboarding_controller.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen/onboarding_screen.dart';
import '../../features/premium/presentation/screens/paywall_screen/paywall_screen.dart';
import '../../features/premium/presentation/screens/premium_screen/premium_screen.dart';
import '../../features/settings/presentation/screens/settings_screen/settings_screen.dart';
import '../analytics/app_analytics.dart';
import '../l10n/locale_provider.dart';
import 'app_shell.dart';

/// One route's identity: go_router [name] and URL [path] defined together so
/// they can never drift apart. Navigate by name (`context.pushNamed(
/// AppRoutes.x.name, ...)`) — the URL shape stays an implementation detail
/// of this file.
class AppRoute {
  const AppRoute({required this.name, required this.path});

  final String name;
  final String path;
}

abstract final class AppRoutes {
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

  /// Detail of one logged attack, pushed from History.
  /// Path parameter: [attackIdParam].
  static const attack = AppRoute(name: 'attackDetail', path: '/attack/:id');
  static const attackIdParam = 'id';

  static const paywall = AppRoute(name: 'paywall', path: '/paywall');

  /// Optional sign-in, pushed from Settings and from any premium gate.
  /// Pops `true` once an account exists (see [LoginScreen]).
  static const login = AppRoute(name: 'login', path: '/login');

  /// The signed-in user's own record, pushed from Settings. Guarded by the
  /// redirect below — there is no account to look at while signed out.
  static const account = AppRoute(name: 'account', path: '/account');

  /// Subscription detail, pushed from Settings. [paywall] is the purchase
  /// sheet; this is the status page that leads to it.
  static const premium = AppRoute(name: 'premium', path: '/premium');
}

/// The router's own navigator. Anything that has to present over the whole
/// app from OUTSIDE the router — `ForceUpdateWrapper`, which lives in
/// `MaterialApp.builder` and so sits above this navigator — pushes onto
/// this key's context. Provider-scoped, not a global: two app instances in
/// the same test process would otherwise share (and duplicate) one key.
final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(debugLabel: 'root'),
);

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: ref.watch(rootNavigatorKeyProvider),
    initialLocation: AppRoutes.dashboard.path,
    // `screen_view` for pushed routes (log, login, paywall, attack detail).
    // Empty outside a Firebase build — the shell's tabs are logged by hand
    // in AppShell, since switching branches pushes nothing.
    observers: AppAnalytics.navigatorObservers,
    // First launch lands on onboarding until it's completed; afterwards
    // /onboarding is never reachable again.
    redirect: (context, state) {
      final done =
          ref
              .read(sharedPreferencesProvider)
              .getBool(OnboardingController.completedKey) ??
          false;
      final onOnboarding = state.matchedLocation == AppRoutes.onboarding.path;
      if (!done && !onOnboarding) return AppRoutes.onboarding.path;
      if (done && onOnboarding) return AppRoutes.dashboard.path;
      // Signing out (or a deep link without an account) must not land on a
      // tab that has nothing to show.
      if (state.matchedLocation == AppRoutes.account.path &&
          !ref.read(isSignedInProvider)) {
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
      // The 3-tap log flow is a full-screen pushed route (opened from the
      // dashboard's log button), not a tab: it takes over the screen so the
      // sacred flow has no distractions, and its own step progress lives in
      // the screen. Popping it (Cancel / Done) returns to wherever it was
      // launched from.
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
      // Both are pushed from Settings, so they cover the tab bar and come
      // back to where they were opened from.
      GoRoute(
        name: AppRoutes.account.name,
        path: AppRoutes.account.path,
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        name: AppRoutes.premium.name,
        path: AppRoutes.premium.path,
        builder: (context, state) => const PremiumScreen(),
      ),
      // A routed page that PRESENTS as a modal bottom sheet: transparent
      // route with a dim barrier, content slides up from the bottom and
      // covers ~80% (see PaywallScreen). Tap above the sheet dismisses.
      GoRoute(
        name: AppRoutes.paywall.name,
        path: AppRoutes.paywall.path,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          opaque: false,
          barrierColor: Colors.black54,
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
