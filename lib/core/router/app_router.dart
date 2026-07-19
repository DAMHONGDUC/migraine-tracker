import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/attacks/presentation/screens/attack_detail_screen.dart';
import '../../features/attacks/presentation/screens/log_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/insights/presentation/screens/insights_screen.dart';
import '../../features/medications/presentation/screens/reminders_screen.dart';
import '../../features/onboarding/presentation/controllers/onboarding_controller.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/premium/presentation/screens/paywall_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
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
  static const log = AppRoute(name: 'log', path: '/log');
  static const history = AppRoute(name: 'history', path: '/history');
  static const insights = AppRoute(name: 'insights', path: '/insights');
  static const settings = AppRoute(name: 'settings', path: '/settings');
  static const reminders = AppRoute(name: 'reminders', path: '/reminders');

  /// Detail of one logged attack, pushed from History.
  /// Path parameter: [attackIdParam].
  static const attack = AppRoute(name: 'attackDetail', path: '/attack/:id');
  static const attackIdParam = 'id';

  static const paywall = AppRoute(name: 'paywall', path: '/paywall');
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.log.path,
    // First launch lands on onboarding until it's completed; afterwards
    // /onboarding is never reachable again.
    redirect: (context, state) {
      final done =
          ref
              .read(sharedPreferencesProvider)
              .getBool(OnboardingController.completedKey) ??
          false;
      final onOnboarding =
          state.matchedLocation == AppRoutes.onboarding.path;
      if (!done && !onOnboarding) return AppRoutes.onboarding.path;
      if (done && onOnboarding) return AppRoutes.log.path;
      return null;
    },
    routes: [
      GoRoute(
        name: AppRoutes.onboarding.name,
        path: AppRoutes.onboarding.path,
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Full-screen, pushed above the shell (no bottom nav).
      GoRoute(
        name: AppRoutes.reminders.name,
        path: AppRoutes.reminders.path,
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        name: AppRoutes.attack.name,
        path: AppRoutes.attack.path,
        builder: (context, state) => AttackDetailScreen(
          attackId: state.pathParameters[AppRoutes.attackIdParam]!,
        ),
      ),
      GoRoute(
        name: AppRoutes.paywall.name,
        path: AppRoutes.paywall.path,
        builder: (context, state) => const PaywallScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.log.name,
                path: AppRoutes.log.path,
                builder: (context, state) => const LogScreen(),
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
