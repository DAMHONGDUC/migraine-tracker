import 'dart:io';

import 'package:health/health.dart';

import '../../domain/entities/sleep_interval.dart';

/// Abstracts the `health` plugin so the repository is testable without
/// HealthKit — same role `LocationSource` plays for geolocator.
abstract interface class SleepSampleSource {
  bool get isAvailable;

  Future<bool> requestAuthorization();

  Future<List<SleepInterval>> sleepSamples({
    required DateTime from,
    required DateTime to,
  });
}

/// Apple HealthKit, via the `health` plugin.
class HealthKitSleepSampleSource implements SleepSampleSource {
  HealthKitSleepSampleSource();

  /// One sleep type, not three. This version of the plugin maps
  /// SLEEP_IN_BED / SLEEP_ASLEEP / SLEEP_AWAKE onto the same
  /// `HKCategoryType.sleepAnalysis` and drops the category value before
  /// Dart sees it, so asking for all three returns the same samples three
  /// times over and none of them can be told apart. Asking for one and
  /// taking the union (see `SleepNightAggregator`) is the honest reading:
  /// total time the device recorded as sleep.
  static const List<HealthDataType> _sleepTypes = <HealthDataType>[
    HealthDataType.SLEEP_IN_BED,
  ];

  final HealthFactory _health = HealthFactory();

  @override
  bool get isAvailable => Platform.isIOS;

  @override
  Future<bool> requestAuthorization() async {
    if (!isAvailable) return false;

    return _health.requestAuthorization(_sleepTypes);
  }

  @override
  Future<List<SleepInterval>> sleepSamples({
    required DateTime from,
    required DateTime to,
  }) async {
    if (!isAvailable) return const <SleepInterval>[];

    final List<HealthDataPoint> points = await _health.getHealthDataFromTypes(
      from,
      to,
      _sleepTypes,
    );

    return <SleepInterval>[
      for (final HealthDataPoint point in points)
        SleepInterval(start: point.dateFrom, end: point.dateTo),
    ];
  }
}
