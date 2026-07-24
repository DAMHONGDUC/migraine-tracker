import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/bare_ease_app.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/core/db/database_provider.dart';
import 'package:migraine_tracker/core/l10n/locale_provider.dart';
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
}

class PumpedApp {
  PumpedApp({required this.db, required this.prefs, required this.weather});

  final AppDatabase db;
  final SharedPreferences prefs;
  final FakeWeatherRepository weather;
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

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        weatherRepositoryProvider.overrideWithValue(weather),
        notificationSchedulerProvider.overrideWithValue(
          FakeNotificationScheduler(),
        ),
        if (exportSink != null)
          exportSinkProvider.overrideWithValue(exportSink),
      ],
      child: const BaroEaseApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  return PumpedApp(db: db, prefs: prefs, weather: weather);
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
