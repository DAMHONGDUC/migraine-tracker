import 'package:meta/meta.dart';

import 'sleep_night.dart';

/// The recent nights as the sleep screen shows them back: what was measured,
/// not what it correlates with.
@immutable
class SleepSummary {
  const SleepSummary({required this.nights, required this.average});

  /// Nothing read — either the source is disconnected, or it has no samples
  /// in the window.
  static const SleepSummary empty = SleepSummary(
    nights: <SleepNight>[],
    average: Duration.zero,
  );

  /// Oldest first, exactly as the repository serves them. Nights with no
  /// samples are absent rather than zero, so a gap is a gap.
  final List<SleepNight> nights;

  /// Mean over [nights] — over the nights that were measured, not over the
  /// window, or a missing night would read as a sleepless one.
  final Duration average;

  /// The most recent night, or null when nothing was read.
  SleepNight? get latest => nights.isEmpty ? null : nights.last;

  bool get isEmpty => nights.isEmpty;
}
