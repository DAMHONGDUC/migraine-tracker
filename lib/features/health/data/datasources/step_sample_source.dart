import 'dart:io';

import 'package:health/health.dart';

import '../../domain/entities/step_sample.dart';

/// Abstracts the `health` plugin so the repository is testable without
/// HealthKit — same role [SleepSampleSource] plays for sleep.
///
/// Authorization is NOT part of this interface: it lives on
/// `HealthRepository` so one sheet covers every source together ("one
/// switch, one sheet").
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

  final HealthFactory _health = HealthFactory();

  @override
  bool get isAvailable => Platform.isIOS;

  @override
  Future<List<StepSample>> stepSamples({
    required DateTime from,
    required DateTime to,
  }) async {
    if (!isAvailable) return const <StepSample>[];

    final List<HealthDataPoint> points = await _health.getHealthDataFromTypes(
      from,
      to,
      types,
    );

    return <StepSample>[
      for (final HealthDataPoint point in points)
        StepSample(
          start: point.dateFrom,
          end: point.dateTo,
          count: point.value.round(),
        ),
    ];
  }
}
