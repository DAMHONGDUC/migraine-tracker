import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'data/datasources/sleep_sample_source.dart';
import 'data/datasources/step_sample_source.dart';
import 'data/repositories/health_kit_repository.dart';
import 'domain/entities/health_connections.dart';
import 'domain/repositories/health_repository.dart';
import 'domain/services/sleep_night_aggregator.dart';
import 'domain/services/step_day_aggregator.dart';
import 'presentation/controllers/health_controller.dart';

final sleepSampleSourceProvider = Provider<SleepSampleSource>(
  (ref) => HealthKitSleepSampleSource(),
);

final stepSampleSourceProvider = Provider<StepSampleSource>(
  (ref) => HealthKitStepSampleSource(),
);

final healthRepositoryProvider = Provider<HealthRepository>(
  (ref) => HealthKitRepository(
    ref.watch(sleepSampleSourceProvider),
    const SleepNightAggregator(),
    ref.watch(stepSampleSourceProvider),
    const StepDayAggregator(),
  ),
);

/// Whether to offer the feature at all — false off iOS, where the plugin
/// would talk to Google Fit. Every health surface checks this first.
final healthAvailableProvider = Provider<bool>(
  (ref) => ref.watch(healthRepositoryProvider).isAvailable,
);

/// Which Apple Health sources the user connected (see [HealthController]).
final healthControllerProvider =
    NotifierProvider<HealthController, HealthConnections>(
      HealthController.new,
    );
