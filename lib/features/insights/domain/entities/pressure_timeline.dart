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

/// The pressure line with the user's attacks marked on it.
@immutable
class PressureTimeline {
  const PressureTimeline({
    required this.days,
    required this.attacksWithoutReading,
  });

  const PressureTimeline.empty()
    : days = const <PressureTimelineDay>[],
      attacksWithoutReading = 0;

  /// Oldest first.
  final List<PressureTimelineDay> days;

  /// Attacks inside the window that fall on days with no reading, so they could not be plotted.
  final int attacksWithoutReading;

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
