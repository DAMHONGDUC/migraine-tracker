import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/core/db/database_provider.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/attacks/presentation/controllers/log_controller.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';
import 'package:migraine_tracker/features/weather/domain/repositories/weather_repository.dart';
import 'package:migraine_tracker/features/weather/providers.dart';

class _NoWeather implements WeatherRepository {
  @override
  Future<WeatherSnapshot?> snapshotAt(DateTime instant) async => null;
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

  LogController controller() =>
      container.read(logControllerProvider.notifier);
  LogFlowState state() => container.read(logControllerProvider);

  test('starts at the intensity step with no data', () {
    expect(state().step, LogStep.intensity);
    expect(state().intensity, isNull);
  });

  test('each tap advances the flow and records its value', () {
    controller().selectIntensity(7);
    expect(state().step, LogStep.location);
    expect(state().intensity, 7);

    controller().selectLocation(HeadLocation.right);
    expect(state().step, LogStep.medication);
    expect(state().location, HeadLocation.right);
  });

  test('save persists the attack and moves to the saved step', () async {
    controller()
      ..selectIntensity(8)
      ..selectLocation(HeadLocation.left);
    await controller().save('Sumatriptan');

    expect(state().step, LogStep.saved);
    expect(state().savedId, isNotNull);

    final rows = await db.select(db.attacks).get();
    expect(rows, hasLength(1));
    expect(rows.single.intensity, 8);
    expect(rows.single.location, HeadLocation.left);
    expect(rows.single.medicationName, 'Sumatriptan');
  });

  test('back steps to the previous screen', () {
    controller().selectIntensity(5);
    controller().back();
    expect(state().step, LogStep.intensity);
    expect(state().intensity, 5, reason: 'value kept so it can be re-picked');
  });

  test('reset clears everything back to the start', () async {
    controller()
      ..selectIntensity(6)
      ..selectLocation(HeadLocation.whole);
    await controller().save(null);
    controller().reset();

    expect(state().step, LogStep.intensity);
    expect(state().intensity, isNull);
    expect(state().location, isNull);
    expect(state().savedId, isNull);
  });
}
