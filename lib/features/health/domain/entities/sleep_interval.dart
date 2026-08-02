import 'package:meta/meta.dart';

/// One raw sleep sample, exactly as HealthKit stores it: a local-time
/// interval. A single night usually produces several of these — the phone
/// writes "in bed" while the watch writes one sample per REM/core/deep block
/// on top of it — so they overlap and must be merged before they mean
/// anything. See [SleepNightAggregator].
@immutable
class SleepInterval {
  SleepInterval({required this.start, required this.end})
    : assert(!end.isBefore(start), 'end must not precede start');

  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);
}
