import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/enums/health_range.dart';

/// Which range a health chart is showing.
///
/// Notifiers rather than local widget state, so the pick survives the card
/// rebuilding when a pull-to-refresh invalidates the data under it.
///
/// [HealthRange.week] to start: it is the window the summary figures already
/// use, so the card opens agreeing with the average printed above it.
class StepRangeController extends Notifier<HealthRange> {
  @override
  HealthRange build() => HealthRange.week;

  void set(HealthRange range) => state = range;
}

class SleepRangeController extends Notifier<HealthRange> {
  @override
  HealthRange build() => HealthRange.week;

  void set(HealthRange range) => state = range;
}
