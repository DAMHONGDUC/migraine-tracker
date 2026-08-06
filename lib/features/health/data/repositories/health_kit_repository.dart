import 'package:health/health.dart';

import '../../domain/entities/sleep_interval.dart';
import '../../domain/entities/sleep_night.dart';
import '../../domain/entities/step_day.dart';
import '../../domain/entities/step_sample.dart';
import '../../domain/repositories/health_repository.dart';
import '../../domain/services/sleep_night_aggregator.dart';
import '../../domain/services/step_day_aggregator.dart';
import '../datasources/sleep_sample_source.dart';
import '../datasources/step_sample_source.dart';

/// HealthKit-backed [HealthRepository]: each plugin source fetches raw
/// samples, its aggregator turns them into days/nights. Nothing is cached and
/// nothing is written to the app's own database — HealthKit is already
/// on-device storage, and a second copy here would be one more pile of health
/// data the "delete everything" wipe has to chase (hard rule 8).
///
/// Owns the one `HealthFactory` authorization call for every source it
/// composes, so connecting Apple Health is a single sheet covering sleep AND
/// steps together, not one prompt per data type.
class HealthKitRepository implements HealthRepository {
  HealthKitRepository(
    this._sleepSource,
    this._sleepAggregator,
    this._stepSource,
    this._stepAggregator,
  );

  final SleepSampleSource _sleepSource;
  final SleepNightAggregator _sleepAggregator;
  final StepSampleSource _stepSource;
  final StepDayAggregator _stepAggregator;

  final HealthFactory _health = HealthFactory();

  @override
  bool get isAvailable => _sleepSource.isAvailable;

  @override
  Future<bool> requestAuthorization() {
    if (!isAvailable) return Future.value(false);

    return _health.requestAuthorization(<HealthDataType>[
      ...HealthKitSleepSampleSource.types,
      ...HealthKitStepSampleSource.types,
    ]);
  }

  @override
  Future<List<SleepNight>> sleepNights({
    required DateTime from,
    required DateTime to,
  }) async {
    final List<SleepInterval> samples = await _sleepSource.sleepSamples(
      from: from,
      to: to,
    );

    return _sleepAggregator.aggregate(samples);
  }

  @override
  Future<List<StepDay>> stepDays({
    required DateTime from,
    required DateTime to,
  }) async {
    final List<StepSample> samples = await _stepSource.stepSamples(
      from: from,
      to: to,
    );

    return _stepAggregator.aggregate(samples);
  }
}
