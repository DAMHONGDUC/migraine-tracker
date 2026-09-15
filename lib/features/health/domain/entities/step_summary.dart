import 'package:meta/meta.dart';

import 'step_day.dart';

/// The recent days as the activity screen shows them back: what was counted, not what it correlates with.
@immutable
class StepSummary {
  const StepSummary({required this.days, required this.average});

  /// Nothing read — either the source is disconnected, or it has no samples in the window.
  static const StepSummary empty = StepSummary(days: <StepDay>[], average: 0);

  /// Oldest first, exactly as the repository serves them. Days with no samples are absent rather than zero, so a gap is a gap.
  final List<StepDay> days;

  /// Mean over [days] — over the days that were counted, not over the window, or a phone left at home would read as a day without a single step.
  final int average;

  /// The most recent day, or null when nothing was read.
  StepDay? get latest => days.isEmpty ? null : days.last;

  bool get isEmpty => days.isEmpty;
}
