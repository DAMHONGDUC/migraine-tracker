import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/core/db/database_provider.dart';
import 'package:migraine_tracker/core/storage/secure_store.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/exertion_level.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/attacks/presentation/controllers/log_controller.dart';
import 'package:migraine_tracker/features/attacks/providers.dart';
import 'package:migraine_tracker/features/weather/domain/entities/pressure_forecast.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_report.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';
import 'package:migraine_tracker/features/weather/domain/repositories/weather_repository.dart';
import 'package:migraine_tracker/features/weather/providers.dart';

class _NoWeather implements WeatherRepository {
  @override
  Future<WeatherSnapshot?> snapshotAt(DateTime instant) async => null;

  @override
  Future<PressureForecast?> pressureForecast() async => null;

  // The weather card's payload. No widget test draws it, and no non-UI test needs it, so every fake answers "no weather".
  @override
  Future<WeatherReport?> report() async => null;
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    // The save path reads the locale to word the Live Activity's strings, and the locale controller reads the secure store — which throws by design until something overrides it. Without this the failure is "secureStoreProvider must be overridden at app start" inside `_save`'s catch, which reports as "the attack was not persisted".
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final SecureStore prefs = await SecureStore.open();

    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        weatherRepositoryProvider.overrideWithValue(_NoWeather()),
        secureStoreProvider.overrideWithValue(prefs),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  LogController controller() => container.read(logControllerProvider.notifier);
  LogFlowState state() => container.read(logControllerProvider);

  test('starts at the intensity step with no data', () {
    expect(state().step, LogStep.intensity);
    expect(state().intensity, isNull);
    expect(state().hasDraft, isFalse);
  });

  test('selectIntensity advances immediately, no confirm step', () {
    controller().selectIntensity(7);
    expect(state().step, LogStep.location);
    expect(state().intensity, 7);
    expect(state().hasDraft, isFalse);
  });

  test('picking a location arms the draft without advancing', () {
    controller().selectIntensity(7);
    controller().updateDraft(const <HeadRegion>[HeadRegion.templeR]);
    expect(state().step, LogStep.location);
    expect(state().hasDraft, isTrue);
    expect(state().regions, isNull);
  });

  test('confirmStep commits the location draft and advances', () async {
    controller().selectIntensity(7);

    controller().updateDraft(const <HeadRegion>[HeadRegion.templeR]);
    await controller().confirmStep();
    expect(state().step, LogStep.medication);
    expect(state().regions, const <HeadRegion>[HeadRegion.templeR]);
    // Armed on arrival now: the medication step defaults to "No medication".
    expect(state().hasDraft, isTrue);
  });

  test('confirmStep on the exertion step persists the attack', () async {
    controller().selectIntensity(8);
    controller().updateDraft(const <HeadRegion>[HeadRegion.templeL]);
    await controller().confirmStep();
    controller().updateDraft('Sumatriptan');
    await controller().confirmStep();
    expect(state().step, LogStep.exertion, reason: 'medication commits first');
    controller().updateDraft(ExertionLevel.severe);
    await controller().confirmStep();

    expect(state().step, LogStep.saved);
    expect(state().savedId, isNotNull);

    final rows = await db.select(db.attacks).get();
    expect(rows, hasLength(1));
    expect(rows.single.intensity, 8);
    expect(rows.single.regions, const <HeadRegion>[HeadRegion.templeL]);
    expect(rows.single.medicationName, 'Sumatriptan');
    expect(rows.single.exertionLevel, ExertionLevel.severe);
  });

  test('medication and exertion arrive on their defaults, Next armed', () async {
    controller().selectIntensity(4);
    controller().updateDraft(const <HeadRegion>[HeadRegion.foreheadL]);
    await controller().confirmStep();

    // "No medication" is the default: armed before the user picks anything.
    expect(state().step, LogStep.medication);
    expect(state().hasDraft, isTrue);
    expect(state().draft, isNull);

    await controller().confirmStep();
    expect(state().step, LogStep.exertion);
    expect(state().hasDraft, isTrue);
    expect(state().draft, ExertionLevel.none);

    // Straight through both without touching either: neither step may hold an attack hostage (hard rule 5).
    await controller().confirmStep();

    expect(state().step, LogStep.saved);
    final rows = await db.select(db.attacks).get();
    expect(rows.single.medicationName, isNull);
    expect(rows.single.exertionLevel, ExertionLevel.none);
  });

  test('confirming "No medication" is a valid pick (null draft)', () async {
    controller().selectIntensity(3);
    controller().updateDraft(const <HeadRegion>[HeadRegion.crown]);
    await controller().confirmStep();
    controller().updateDraft(null);
    expect(state().hasDraft, isTrue, reason: 'null is a valid medication pick');
    await controller().confirmStep();
    await controller().confirmStep();

    expect(state().step, LogStep.saved);
    final rows = await db.select(db.attacks).get();
    expect(rows.single.medicationName, isNull);
  });

  test('back from exertion re-arms the confirmed medication pick', () async {
    controller().selectIntensity(5);
    controller().updateDraft(const <HeadRegion>[HeadRegion.templeL]);
    await controller().confirmStep();
    controller().updateDraft('Ibuprofen');
    await controller().confirmStep();
    controller().back();

    expect(state().step, LogStep.medication);
    expect(state().draft, 'Ibuprofen');
    expect(state().hasDraft, isTrue);
  });

  test('back steps to the previous screen, keeping its value pre-filled', () {
    controller().selectIntensity(5);
    controller().updateDraft(const <HeadRegion>[HeadRegion.crown]);
    controller().back();

    expect(state().step, LogStep.intensity);
    expect(state().intensity, 5, reason: 'value kept so it can be re-picked');
  });

  test('back from medication pre-fills the location draft', () async {
    controller().selectIntensity(5);
    controller().updateDraft(const <HeadRegion>[HeadRegion.templeL]);
    await controller().confirmStep();
    controller().back();

    expect(state().step, LogStep.location);
    expect(state().regions, const <HeadRegion>[HeadRegion.templeL], reason: 'kept on record');
    expect(state().hasDraft, isTrue);
    expect(state().draft, const <HeadRegion>[HeadRegion.templeL]);
  });

  test('reset clears everything back to the start', () async {
    controller().selectIntensity(6);
    controller().updateDraft(const <HeadRegion>[HeadRegion.crown]);
    await controller().confirmStep();
    controller().updateDraft(null);
    await controller().confirmStep();
    await controller().confirmStep();
    controller().reset();

    expect(state().step, LogStep.intensity);
    expect(state().intensity, isNull);
    expect(state().regions, isNull);
    expect(state().savedId, isNull);
    expect(state().hasDraft, isFalse);
  });
}
