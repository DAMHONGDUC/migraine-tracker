import 'package:meta/meta.dart';

/// One raw step sample, exactly as HealthKit stores it: a step count over a
/// local-time interval. Several of these usually cover one day — the phone
/// and the watch each write their own chunks — so they must be grouped by
/// calendar date before they mean anything. See [StepDayAggregator].
@immutable
class StepSample {
  StepSample({required this.start, required this.end, required this.count})
    : assert(!end.isBefore(start), 'end must not precede start');

  final DateTime start;
  final DateTime end;
  final int count;
}
