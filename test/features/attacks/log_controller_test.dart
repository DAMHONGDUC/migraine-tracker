import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/core/db/database_provider.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/exertion_level.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/attacks/presentation/controllers/log_controller.dart';
import 'package:migraine_tracker/features/attacks/providers.dart';
import 'package:migraine_tracker/features/weather/domain/entities/pressure_forecast.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';
import 'package:migraine_tracker/features/weather/domain/repositories/weather_repository.dart';
import 'package:migraine_tracker/features/weather/providers.dart';

class _NoWeather implements WeatherRepository {
  @override
  Future<WeatherSnapshot?> snapshotAt(DateTime instant) async => null;

  @override
  Future<PressureForecast?> pressureForecast() async => null;
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        weatherRepositoryProvider.overrideWithValue(_NoWeather()),
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
    controller().updateDraft(HeadLocation.right);
    expect(state().step, LogStep.location);
    expect(state().hasDraft, isTrue);
    expect(state().location, isNull);
  });

  test('confirmStep commits the location draft and advances', () async {
    controller().selectIntensity(7);

    controller().updateDraft(HeadLocation.right);
    await controller().confirmStep();
    expect(state().step, LogStep.medication);
    expect(state().location, HeadLocation.right);
    expect(state().hasDraft, isFalse);
  });

  test('confirmStep on the exertion step persists the attack', () async {
    controller().selectIntensity(8);
    controller().updateDraft(HeadLocation.left);
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
    expect(rows.single.location, HeadLocation.left);
    expect(rows.single.medicationName, 'Sumatriptan');
    expect(rows.single.exertionLevel, ExertionLevel.severe);
  });

  test('the exertion step can be passed without an answer', () async {
    controller().selectIntensity(4);
    controller().updateDraft(HeadLocation.front);
    await controller().confirmStep();
    controller().updateDraft(null);
    await controller().confirmStep();

    // Nothing picked, straight to Next: the flow must never hold an attack
    // hostage to an optional field (hard rule 5).
    expect(state().step, LogStep.exertion);
    expect(state().hasDraft, isFalse);
    await controller().confirmStep();

    expect(state().step, LogStep.saved);
    final rows = await db.select(db.attacks).get();
    expect(rows.single.exertionLevel, isNull);
  });

  test('confirming "No medication" is a valid pick (null draft)', () async {
    controller().selectIntensity(3);
    controller().updateDraft(HeadLocation.whole);
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
    controller().updateDraft(HeadLocation.left);
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
    controller().updateDraft(HeadLocation.whole);
    controller().back();

    expect(state().step, LogStep.intensity);
    expect(state().intensity, 5, reason: 'value kept so it can be re-picked');
  });

  test('back from medication pre-fills the location draft', () async {
    controller().selectIntensity(5);
    controller().updateDraft(HeadLocation.left);
    await controller().confirmStep();
    controller().back();

    expect(state().step, LogStep.location);
    expect(state().location, HeadLocation.left, reason: 'kept on record');
    expect(state().hasDraft, isTrue);
    expect(state().draft, HeadLocation.left);
  });

  test('reset clears everything back to the start', () async {
    controller().selectIntensity(6);
    controller().updateDraft(HeadLocation.whole);
    await controller().confirmStep();
    controller().updateDraft(null);
    await controller().confirmStep();
    await controller().confirmStep();
    controller().reset();

    expect(state().step, LogStep.intensity);
    expect(state().intensity, isNull);
    expect(state().location, isNull);
    expect(state().savedId, isNull);
    expect(state().hasDraft, isFalse);
  });
}
