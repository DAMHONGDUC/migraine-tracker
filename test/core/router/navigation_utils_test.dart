import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_tracker/core/router/app_router.dart';
import 'package:migraine_tracker/core/router/navigation_utils.dart';

/// The gate every deep link waits on.
///
/// The bug it exists for: a notification tapped while the app was killed
/// pushed its detail on top of the splash, and the splash's own hand-over
/// (`go` to the dashboard, which REPLACES the stack) threw that screen away a
/// second later — the user watched the notification open and the dashboard
/// take its place.
void main() {
  /// The two routes this is about, and nothing else.
  GoRouter routerAt(String location) => GoRouter(
    initialLocation: location,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash.path,
        builder: (_, _) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: AppRoutes.dashboard.path,
        builder: (_, _) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: AppRoutes.notification.path,
        builder: (_, _) => const SizedBox.shrink(),
      ),
    ],
  );

  /// Pumps [router] so its delegate has a configuration to report.
  Future<void> mount(WidgetTester tester, GoRouter router) async {
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router),
    );
    addTearDown(router.dispose);
  }

  testWidgets('it holds while the splash is up and resolves on the hand-over', (
    tester,
  ) async {
    final GoRouter router = routerAt(AppRoutes.splash.path);
    await mount(tester, router);

    bool arrived = false;
    // ignore: unawaited_futures — the whole point is that it has NOT resolved.
    NavigationUtils.whenPastSplash(router).then((_) => arrived = true);
    await tester.pump();

    expect(arrived, isFalse, reason: 'still on the splash');

    router.go(AppRoutes.dashboard.path);
    await tester.pump();
    await tester.pump();

    expect(arrived, isTrue);
  });

  testWidgets('a launch that skips the splash never waits', (tester) async {
    // `pumpApp` overrides `initialLocationProvider`, and any future route
    // could too: a gate waiting on a signal nobody sends would hold every
    // deep link forever.
    final GoRouter router = routerAt(AppRoutes.dashboard.path);
    await mount(tester, router);

    bool arrived = false;
    // ignore: unawaited_futures
    NavigationUtils.whenPastSplash(router).then((_) => arrived = true);
    await tester.pump();

    expect(arrived, isTrue);
  });

  // A push on top of the splash is exactly what the bug did, and it counts as
  // past: the deep link already won, and the splash must not take it back.
  testWidgets('a screen pushed over the splash counts as past it', (
    tester,
  ) async {
    final GoRouter router = routerAt(AppRoutes.splash.path);
    await mount(tester, router);

    unawaited(router.push('/notification/n1'));
    await tester.pump();
    await tester.pump();

    bool arrived = false;
    // ignore: unawaited_futures
    NavigationUtils.whenPastSplash(router).then((_) => arrived = true);
    await tester.pump();

    expect(arrived, isTrue);
  });
}
