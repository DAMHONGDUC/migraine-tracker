import 'package:meta/meta.dart';

/// One menstruation record as HealthKit hands it over, before it is grouped into days.
@immutable
class CycleSample {
  const CycleSample({
    required this.start,
    required this.hasFlow,
    required this.isPeriodStart,
  });

  final DateTime start;

  /// Whether there was any bleeding. HealthKit records "none" days too, and those are not period days.
  final bool hasFlow;

  /// HealthKit's own `HKMenstrualCycleStart`, never inferred here. Guessing the start from a gap in the samples would invent a cycle out of a week the user simply did not log.
  final bool isPeriodStart;
}
