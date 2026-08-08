/// Numbers the 3-tap log flow's option grids and dials run by.
final class LogFlowConstant {
  /// Tiles per row in the exertion and medication grids.
  ///
  /// Two, so the two adjacent steps read as one component — four exertion
  /// tiles across a single row left every label a cramped two-line scrap.
  /// `LocationGrid` stays three-up: five tiles, each labelled with one short
  /// word.
  static const int optionsPerRow = 2;

  /// Fill opacity of the intensity disc's tinted body.
  static const double intensityDiscFillAlpha = 0.45;

  /// Hairline around the intensity disc.
  static const double intensityDiscBorderWidth = 1.5;

  /// Top of the pain scale. The same 1–10 the `Attack.intensity` assert
  /// enforces, and what History's trend chart draws its axis to — one number,
  /// so the chart cannot outgrow the scale it plots.
  static const double intensityMax = 10;

  /// Gridline spacing on that axis.
  static const double intensityGridInterval = 2;
}
