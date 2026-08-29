import 'package:meta/meta.dart';

/// One raw step sample, exactly as HealthKit stores it: a step count over a local-time interval.
@immutable
class StepSample {
  StepSample({required this.start, required this.end, required this.count})
    : assert(!end.isBefore(start), 'end must not precede start');

  final DateTime start;
  final DateTime end;
  final int count;
}
