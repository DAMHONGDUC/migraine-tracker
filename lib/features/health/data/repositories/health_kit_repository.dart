import '../../domain/entities/sleep_interval.dart';
import '../../domain/entities/sleep_night.dart';
import '../../domain/repositories/health_repository.dart';
import '../../domain/services/sleep_night_aggregator.dart';
import '../datasources/sleep_sample_source.dart';

/// HealthKit-backed [HealthRepository]: the plugin fetches raw samples, the
/// aggregator turns them into nights. Nothing is cached and nothing is
/// written to the app's own database — HealthKit is already on-device
/// storage, and a second copy here would be one more pile of health data the
/// "delete everything" wipe has to chase (hard rule 8).
class HealthKitRepository implements HealthRepository {
  const HealthKitRepository(this._source, this._aggregator);

  final SleepSampleSource _source;
  final SleepNightAggregator _aggregator;

  @override
  bool get isAvailable => _source.isAvailable;

  @override
  Future<bool> requestAuthorization() => _source.requestAuthorization();

  @override
  Future<List<SleepNight>> sleepNights({
    required DateTime from,
    required DateTime to,
  }) async {
    final List<SleepInterval> samples = await _source.sleepSamples(
      from: from,
      to: to,
    );

    return _aggregator.aggregate(samples);
  }
}
