import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/bare_ease_app.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/core/db/database_provider.dart';
import 'package:migraine_tracker/core/l10n/locale_provider.dart';
import 'package:migraine_tracker/core/permissions/app_permission.dart';
import 'package:migraine_tracker/core/permissions/app_permission_gateway.dart';
import 'package:migraine_tracker/features/auth/domain/entities/auth_user.dart';
import 'package:migraine_tracker/features/auth/domain/enums/auth_error.dart';
import 'package:migraine_tracker/features/auth/domain/enums/auth_provider_kind.dart';
import 'package:migraine_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:migraine_tracker/features/auth/providers.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication_reminder.dart';
import 'package:migraine_tracker/features/medications/domain/services/notification_scheduler.dart';
import 'package:migraine_tracker/features/medications/providers.dart';
import 'package:migraine_tracker/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:migraine_tracker/features/premium/data/repositories/debug_premium_repository.dart';
import 'package:migraine_tracker/features/settings/domain/services/export_sink.dart';
import 'package:migraine_tracker/features/settings/providers.dart';
import 'package:migraine_tracker/features/weather/domain/entities/pressure_forecast.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';
import 'package:migraine_tracker/features/weather/domain/repositories/weather_repository.dart';
import 'package:migraine_tracker/features/weather/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-behaving weather stub: widget tests never touch geolocator or
/// the network.
class FakeWeatherRepository implements WeatherRepository {
  FakeWeatherRepository({this.snapshot});

  /// Returned for every request; null simulates offline/no permission.
  WeatherSnapshot? snapshot;

  /// Returned by [pressureForecast]; null simulates offline.
  PressureForecast? forecast;

  @override
  Future<WeatherSnapshot?> snapshotAt(DateTime instant) async => snapshot;

  @override
  Future<PressureForecast?> pressureForecast() async => forecast;
}

/// No-op scheduler so widget tests never touch the notifications plugin.
class FakeNotificationScheduler implements NotificationScheduler {
  /// Set when [scheduleTest] is called, so a test can assert the debug
  /// "test notification" action reached the scheduler.
  bool testScheduled = false;

  @override
  Future<bool> ensurePermission() async => true;

  @override
  Future<void> schedule(
    MedicationReminder reminder, {
    required String medicationName,
    required String title,
    required String bodyTemplate,
  }) async {}

  @override
  Future<void> cancel(String reminderId) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> scheduleTest({
    required String title,
    required String body,
    Duration delay = const Duration(seconds: 10),
  }) async {
    testScheduled = true;
  }
}

/// In-memory account. Not optional like the other fakes: `authUserProvider`
/// is watched at build time, so a real one drags Firebase into the tree.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({bool signedIn = false})
    : _user = signedIn
          ? const AuthUser(
              uid: 'test-uid',
              isAnonymous: false,
              email: 'tester@example.com',
            )
          : const AuthUser(uid: 'test-uid', isAnonymous: true);

  /// Set to make [signIn] fail with this error instead of succeeding.
  AuthError? failWith;

  /// Whether the login screen should offer the Apple button.
  bool appleAvailable = true;

  /// Providers [signIn] was called with, in order.
  final List<AuthProviderKind> signInCalls = <AuthProviderKind>[];
  int signOutCalls = 0;

  AuthUser _user;
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> watchUser() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<bool> isAppleAvailable() async => appleAvailable;

  @override
  Future<AuthUser> signIn(AuthProviderKind provider) async {
    signInCalls.add(provider);
    final AuthError? error = failWith;

    if (error != null) throw AuthException(error);

    // Mirrors linkWithCredential: same UID, no longer anonymous.
    _user = AuthUser(
      uid: _user.uid,
      isAnonymous: false,
      email: 'tester@example.com',
    );
    _controller.add(_user);
    return _user;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _user = AuthUser(uid: _user.uid, isAnonymous: true);
    _controller.add(_user);
  }

  void dispose() => _controller.close();
}

/// Grants permissions by default; a test can flip [statusFor] to exercise the
/// permanently-denied → settings-sheet path. Never touches the OS.
class FakeAppPermissionGateway implements AppPermissionGateway {
  AppPermissionStatus statusFor = AppPermissionStatus.granted;
  int openSettingsCalls = 0;

  @override
  Future<AppPermissionStatus> status(AppPermissionType type) async => statusFor;

  @override
  Future<AppPermissionStatus> request(AppPermissionType type) async =>
      statusFor;

  @override
  Future<void> openAppSettings() async => openSettingsCalls++;
}

class PumpedApp {
  PumpedApp({
    required this.db,
    required this.prefs,
    required this.weather,
    required this.scheduler,
    required this.permissions,
    required this.auth,
  });

  final AppDatabase db;
  final SharedPreferences prefs;
  final FakeWeatherRepository weather;
  final FakeNotificationScheduler scheduler;
  final FakeAppPermissionGateway permissions;
  final FakeAuthRepository auth;
}

/// Boots the full app with an in-memory database, mock prefs, and stubbed
/// weather. Uses bounded pumps — see the Drift/pumpAndSettle note below.
Future<PumpedApp> pumpApp(
  WidgetTester tester, {
  Map<String, Object> initialPrefs = const {},
  WeatherSnapshot? weatherSnapshot,
  // Riverpod 3 no longer exports the `Override` type, so the helper takes
  // the concrete fakes it knows about instead of a generic override list.
  ExportSink? exportSink,
  /// Default free — gating tests must opt in to premium explicitly.
  bool premium = false,

  /// Follows [premium]: an entitlement without an account unlocks nothing,
  /// so a signed-out premium test would silently test the locked branch.
  bool? signedIn,

  /// Off, as shipped: the Apple button shows but its flow is not wired up.
  /// True covers the real path, which must work before submission.
  bool appleSignIn = false,
}) async {
  // Pin the test view to the 393×852 design size (an iPhone-class screen,
  // DPR 3 = 1179×2556 physical). The default 800×600 surface makes
  // screenutil scale `.sp`/`.w`/`.h` by ~2×, which distorts layout and
  // pushes tap targets off-screen.
  tester.view.physicalSize = const Size(393 * 3, 852 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  // Onboarding is considered done by default so existing tests land on the
  // dashboard; pass onboarding_completed: false to exercise onboarding.
  SharedPreferences.setMockInitialValues({
    OnboardingController.completedKey: true,
    if (premium) DebugPremiumRepository.prefsKey: true,
    ...initialPrefs,
  });
  final prefs = await SharedPreferences.getInstance();
  final weather = FakeWeatherRepository(snapshot: weatherSnapshot);
  final scheduler = FakeNotificationScheduler();
  final permissions = FakeAppPermissionGateway();
  final auth = FakeAuthRepository(signedIn: signedIn ?? premium);
  addTearDown(auth.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        weatherRepositoryProvider.overrideWithValue(weather),
        notificationSchedulerProvider.overrideWithValue(scheduler),
        appPermissionGatewayProvider.overrideWithValue(permissions),
        authRepositoryProvider.overrideWithValue(auth),
        appleSignInImplementedProvider.overrideWithValue(appleSignIn),
        if (exportSink != null)
          exportSinkProvider.overrideWithValue(exportSink),
      ],
      child: const BaroEaseApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  return PumpedApp(
    db: db,
    prefs: prefs,
    weather: weather,
    scheduler: scheduler,
    permissions: permissions,
    auth: auth,
  );
}

/// Must be the last statement of every test that used [pumpApp].
///
/// Flutter's end-of-test "no pending timers" check runs the instant the
/// test body returns — before addTearDown callbacks. Disposing the tree
/// here lets Drift's zero-duration stream-cancellation Timer (scheduled
/// when a Drift-backed StreamProvider is torn down) fire first.
Future<void> finishTest(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 500));
}

/// Taps a target below the fold. A plain `tap()` on an off-screen widget
/// only warns and taps nothing, failing some later assertion instead.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Tab switches from the shell's bottom nav. Every widget test that leaves
/// the dashboard goes through these rather than re-tapping the icons.
Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> openMedications(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.medication_outlined));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> openHistory(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.calendar_month_outlined));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Pumps real frames so the correlation count-up (700ms) can run — one big
/// jump skips its start frame.
Future<void> openInsights(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.insights_outlined));
  for (int i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Opens the log flow from the dashboard's hero button (the flow is a pushed
/// route now, not a tab). Leaves the tester on the intensity step.
Future<void> openLog(WidgetTester tester) async {
  await tester.tap(find.text('Log an attack'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

/// Taps through the sacred flow with sensible defaults, starting from the
/// dashboard. Intensity advances immediately; location and medication are
/// pick-then-confirm — each pick is followed by a tap on the app bar's Next
/// (see LogScreen/LogController). By default it also taps "Done" on the
/// saved screen to return to the dashboard; pass finish: false to stay on the
/// saved step (e.g. to open "Add details").
Future<void> logAttack(
  WidgetTester tester, {
  String intensity = '7',
  String location = 'Right side',
  String medication = 'No medication',
  bool finish = true,
}) async {
  await openLog(tester);

  await tester.tap(find.text(intensity));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  await tester.tap(find.text(location));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.text('Next'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  // The medication step keeps both an expanded and a collapsed copy of the
  // action rows mounted (they cross-fade on scroll), so the label matches
  // twice — .first is the visible, tappable expanded one.
  await tester.tap(find.text(medication).first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.text('Next'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  if (finish) {
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }
}
