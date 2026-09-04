import 'dart:io';

import 'package:health/health.dart';

import '../../domain/entities/cycle_sample.dart';

/// Abstracts the `health` plugin so the repository is testable without HealthKit — same role [SleepSampleSource] plays for sleep.
abstract interface class CycleSampleSource {
  bool get isAvailable;

  Future<List<CycleSample>> cycleSamples({
    required DateTime from,
    required DateTime to,
  });
}

/// Apple HealthKit, via the `health` plugin.
class HealthKitCycleSampleSource implements CycleSampleSource {
  HealthKitCycleSampleSource();

  static const List<HealthDataType> types = <HealthDataType>[
    HealthDataType.MENSTRUATION_FLOW,
  ];

  final Health _health = Health();

  @override
  bool get isAvailable => Platform.isIOS;

  @override
  Future<List<CycleSample>> cycleSamples({
    required DateTime from,
    required DateTime to,
  }) async {
    if (!isAvailable) return const <CycleSample>[];

    final List<HealthDataPoint> points = await _health.getHealthDataFromTypes(
      types: types,
      startTime: from,
      endTime: to,
    );

    return <CycleSample>[
      for (final HealthDataPoint point in points)
        if (point.value case final MenstruationFlowHealthValue flow)
          CycleSample(
            start: point.dateFrom,
            // "none" is a day the user logged as having no bleeding, which is a fact and not a period day.
            hasFlow:
                flow.flow != null &&
                flow.flow != MenstrualFlow.none &&
                flow.flow != MenstrualFlow.unspecified,
            isPeriodStart: flow.isStartOfCycle ?? false,
          ),
    ];
  }
}
