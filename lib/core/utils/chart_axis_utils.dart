import 'dart:math';

/// Axis arithmetic for the plotted charts: bounds and gridline spacing. The
/// time half of an axis lives in [DateTimeUtils], where all date maths does.
///
/// Out of the chart widgets because it is the one part of them that can be
/// wrong rather than merely ugly, and because two call sites in the same
/// build asking for the same interval used to compute it twice.
final class ChartAxisUtils {
  /// Headroom above and below the series, so a line never touches the frame.
  static const double bounds = 2;

  /// Roughly how many gridlines to draw between the bounds.
  static const int targetGridLines = 3;

  static double minBound(Iterable<double> values) =>
      (values.reduce(min) - bounds).floorToDouble();

  static double maxBound(Iterable<double> values) =>
      (values.reduce(max) + bounds).ceilToDouble();

  /// Gridline spacing, never below 1 — a flat series would otherwise ask for
  /// an interval of 0 and fl_chart would draw forever.
  static double interval(double minY, double maxY) =>
      max(((maxY - minY) / targetGridLines).ceilToDouble(), 1);
}
