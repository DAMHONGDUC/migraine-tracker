import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/bare_ease_app.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/core/db/database_provider.dart';
import 'package:migraine_tracker/core/l10n/locale_provider.dart';
import 'package:migraine_tracker/features/onboarding/presentation/controllers/onboarding_controller.dart';
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
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  // Onboarding is considered done by default so existing tests land on the
  // log tab; pass onboarding_completed: false to exercise onboarding.
  SharedPreferences.setMockInitialValues({
    OnboardingController.completedKey: true,
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

/// Taps through the sacred 3-tap flow with sensible defaults.
Future<void> logAttack(
  WidgetTester tester, {
  String intensity = '7',
  String location = 'Right side',
  String medication = 'No medication',
}) async {
  await tester.tap(find.text(intensity));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.text(location));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.text(medication));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}
