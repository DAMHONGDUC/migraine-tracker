import 'package:meta/meta.dart';

/// One day on the timeline: what the pressure did, and whether it ended in an attack.
@immutable
class PressureTimelineDay {
  const PressureTimelineDay({
    required this.day,
    required this.pressureHpa,
    required this.delta24hHpa,
    required this.attacks,
    this.peakIntensity,
  });

  /// Local midnight — the identity of a day as the user lived it.
  final DateTime day;

  final double pressureHpa;

  /// Change over the 24 hours before the reading; negative means falling.
  final double delta24hHpa;

  /// Attacks that started on this local day.
  final int attacks;

  /// The worst of them, or null on a day with none. It sizes the marker, so a bad day reads as one at a glance rather than after a tap.
  final int? peakIntensity;

  bool get hasAttack => attacks > 0;

  bool isDrop(double thresholdHpa) => delta24hHpa <= -thresholdHpa;
}

/// One attack placed on the line at the hour it started.
///
/// The x is the day's own position plus the fraction of the day that had passed
/// — which is what turns a dot on a date into a dot on the curve, and is only
/// possible because every attack carries the pressure at its own hour.
@immutable
class PressureTimelineMoment {
  const PressureTimelineMoment({
    required this.at,
    required this.x,
    required this.pressureHpa,
    required this.intensity,
  });

  /// Local time the attack started.
  final DateTime at;

  /// Position along the day axis: the day's index plus the hour as a fraction.
  final double x;

  /// The reading taken at that hour, from the attack's own snapshot.
  final double pressureHpa;

  final int intensity;
}

/// The pressure line with the user's attacks marked on it.
@immutable
class PressureTimeline {
  const PressureTimeline({
    required this.days,
    required this.attacksWithoutReading,
    this.moments = const <PressureTimelineMoment>[],
  });

  const PressureTimeline.empty()
    : days = const <PressureTimelineDay>[],
      attacksWithoutReading = 0,
      moments = const <PressureTimelineMoment>[];

  /// Oldest first.
  final List<PressureTimelineDay> days;

  /// Attacks inside the window that fall on days with no reading, so they could not be plotted.
  final int attacksWithoutReading;

  /// Every attack that carries its own hourly snapshot, placed on the curve at the hour it happened. Oldest first.
  final List<PressureTimelineMoment> moments;

  bool get isEmpty => days.isEmpty;

  int get attacksPlotted =>
      days.fold(0, (sum, PressureTimelineDay day) => sum + day.attacks);

  /// More attacks are missing from the line than are on it.
  bool get strandedOutweighsPlotted => attacksWithoutReading > attacksPlotted;

  /// Lowest reading in the window, or null when there are none.
  double? get minPressureHpa => days.isEmpty
      ? null
      : days
            .map((PressureTimelineDay d) => d.pressureHpa)
            .reduce((a, b) => a < b ? a : b);

  double? get maxPressureHpa => days.isEmpty
      ? null
      : days
            .map((PressureTimelineDay d) => d.pressureHpa)
            .reduce((a, b) => a > b ? a : b);
}
