import 'package:meta/meta.dart';

/// One local day of the user's cycle, as Apple Health knows it.
@immutable
class CycleDay {
  CycleDay({
    required DateTime day,
    required this.hasFlow,
    required this.isPeriodStart,
  }) : day = DateTime(day.year, day.month, day.day);

  /// The local day, at midnight.
  final DateTime day;

  final bool hasFlow;
  final bool isPeriodStart;
}
