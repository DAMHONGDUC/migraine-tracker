import 'dart:io';

import 'package:health/health.dart';

import '../../domain/entities/sleep_interval.dart';

/// Abstracts the `health` plugin so the repository is testable without HealthKit — same role `LocationSource` plays for geolocator.
abstract interface class SleepSampleSource {
  bool get isAvailable;

  Future<List<SleepInterval>> sleepSamples({
    required DateTime from,
    required DateTime to,
  });
}

/// Apple HealthKit, via the `health` plugin.
class HealthKitSleepSampleSource implements SleepSampleSource {
  HealthKitSleepSampleSource();

  /// One sleep type, not three.
  static const List<HealthDataType> types = <HealthDataType>[
    HealthDataType.SLEEP_IN_BED,
  ];

  final Health _health = Health();

  @override
  bool get isAvailable => Platform.isIOS;

  @override
  Future<List<SleepInterval>> sleepSamples({
    required DateTime from,
    required DateTime to,
  }) async {
    if (!isAvailable) return const <SleepInterval>[];

    final List<HealthDataPoint> points = await _health.getHealthDataFromTypes(
      types: types,
      startTime: from,
      endTime: to,
    );

    return <SleepInterval>[
      for (final HealthDataPoint point in points)
        SleepInterval(start: point.dateFrom, end: point.dateTo),
    ];
  }
}
