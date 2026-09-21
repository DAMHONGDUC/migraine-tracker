import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_tracker/core/constants/splash_constant.dart';
import 'package:migraine_tracker/core/router/app_router.dart';
import 'package:migraine_tracker/features/dashboard/presentation/screens/dashboard_screen/dashboard_screen.dart';
import 'package:migraine_tracker/features/notifications/presentation/screens/notification_detail_screen/notification_detail_screen.dart';
import 'package:migraine_tracker/features/splash/presentation/widgets/splash_dots.dart';

import '../../helpers/pump_app.dart';

/// What the splash does when its work finishes, and what it must not do.
///
/// The bug: a reminder tapped while the app was killed pushed its detail on
/// top of the splash, and the splash then `go`'d to the dashboard — which
/// REPLACES the stack — so the user watched the notification open and the
/// dashboard take its place a second later.
void main() {
  /// Past `SplashConstant.minimumVisible` and the startup work behind it.
  /// Bounded pumps, never `pumpAndSettle`: the dots animate forever.
  Future<void> pumpPastSplash(WidgetTester tester) async {
    await tester.pump(SplashConstant.minimumVisible + const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('it hands over to the dashboard on its own', (tester) async {
    await pumpApp(tester, startAtSplash: true);

    expect(find.byType(DashboardScreen), findsNothing);

    await pumpPastSplash(tester);

    expect(find.byType(DashboardScreen), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('it leaves a screen pushed over it alone', (tester) async {
    await pumpApp(tester, startAtSplash: true);
    // Taken from under the router rather than from a provider container: the
    // `InheritedGoRouter` lives inside `MaterialApp.router`, and the dots are
    // what is on screen at this moment.
    final GoRouter router = GoRouter.of(tester.element(find.byType(SplashDots)));

    // What a launch tap does, at the one moment it used to be undone: the
    // splash is still on screen and its work has not returned yet.
    unawaited(
      router.pushNamed<void>(
        AppRoutes.notification.name,
        pathParameters: <String, String>{AppRoutes.notificationIdParam: 'n1'},
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(NotificationDetailScreen), findsOneWidget);

    await pumpPastSplash(tester);

    // Still there, and the dashboard did not replace the stack under it.
    expect(find.byType(NotificationDetailScreen), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);

    await finishTest(tester);
  });
}
