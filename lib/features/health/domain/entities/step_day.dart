import 'package:meta/meta.dart';

/// How many steps the user took on one calendar day.
@immutable
class StepDay {
  const StepDay({required this.date, required this.count});

  /// Local calendar date (midnight) the steps were taken on — the same day
  /// an attack the step correlation joins on, unlike sleep's "night before".
  final DateTime date;

  final int count;
}
