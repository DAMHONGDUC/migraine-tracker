import 'package:meta/meta.dart';

/// How many steps the user took in one hour of one day.
///
/// Exists for the step chart's Day range alone: a day holds one [StepDay],
/// and a single bar is not a chart. Everything wider than a day still counts
/// in days.
@immutable
class StepHour {
  const StepHour({required this.hour, required this.count});

  /// Local time, truncated to the hour it starts.
  final DateTime hour;

  final int count;
}
