import 'package:meta/meta.dart';

/// How many steps the user took in one hour of one day.
@immutable
class StepHour {
  const StepHour({required this.hour, required this.count});

  /// Local time, truncated to the hour it starts.
  final DateTime hour;

  final int count;
}
