import 'package:meta/meta.dart';

/// One raw sleep sample, exactly as HealthKit stores it: a local-time interval.
@immutable
class SleepInterval {
  SleepInterval({required this.start, required this.end})
    : assert(!end.isBefore(start), 'end must not precede start');

  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);
}
