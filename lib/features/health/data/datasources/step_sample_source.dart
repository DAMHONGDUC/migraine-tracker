import 'dart:io';

import 'package:health/health.dart';

import '../../domain/entities/step_sample.dart';

/// Abstracts the `health` plugin so the repository is testable without HealthKit — same role [SleepSampleSource] plays for sleep.
abstract interface class StepSampleSource {
  bool get isAvailable;

  Future<List<StepSample>> stepSamples({
    required DateTime from,
    required DateTime to,
  });
}

/// Apple HealthKit, via the `health` plugin.
class HealthKitStepSampleSource implements StepSampleSource {
  HealthKitStepSampleSource();

  static const List<HealthDataType> types = <HealthDataType>[
    HealthDataType.STEPS,
  ];

  final Health _health = Health();

  @override
  bool get isAvailable => Platform.isIOS;

  @override
  Future<List<StepSample>> stepSamples({
    required DateTime from,
    required DateTime to,
  }) async {
    if (!isAvailable) return const <StepSample>[];

    final List<HealthDataPoint> points = await _health.getHealthDataFromTypes(
      types: types,
      startTime: from,
      endTime: to,
    );

    return <StepSample>[
      for (final HealthDataPoint point in points)
        StepSample(
          start: point.dateFrom,
          end: point.dateTo,
          // The plugin hands every reading over as a typed value now; a step count is always numeric, and anything else is a sample this app did not ask for.
          count: point.value is NumericHealthValue
              ? (point.value as NumericHealthValue).numericValue.round()
              : 0,
        ),
    ];
  }
}
