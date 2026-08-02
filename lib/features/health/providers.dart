import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'data/datasources/sleep_sample_source.dart';
import 'data/repositories/health_kit_repository.dart';
import 'domain/repositories/health_repository.dart';
import 'domain/services/sleep_night_aggregator.dart';
import 'presentation/controllers/health_controller.dart';

final sleepSampleSourceProvider = Provider<SleepSampleSource>(
  (ref) => HealthKitSleepSampleSource(),
);

final healthRepositoryProvider = Provider<HealthRepository>(
  (ref) => HealthKitRepository(
    ref.watch(sleepSampleSourceProvider),
    const SleepNightAggregator(),
  ),
);

/// Whether to offer the feature at all — false off iOS, where the plugin
/// would talk to Google Fit. Every health surface checks this first.
final healthAvailableProvider = Provider<bool>(
  (ref) => ref.watch(healthRepositoryProvider).isAvailable,
);

/// Whether the user connected Apple Health (see [HealthController]).
final healthControllerProvider = NotifierProvider<HealthController, bool>(
  HealthController.new,
);
