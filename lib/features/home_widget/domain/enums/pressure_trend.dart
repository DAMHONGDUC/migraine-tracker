/// Which way pressure moved over the last 24 hours, as the home-screen
/// widget draws it.
///
/// A direction rather than a number, because the widget has one glyph's worth
/// of room to say it. [unknown] is "no usable reading", which is a different
/// thing from [steady].
enum PressureTrend {
  falling,
  rising,
  steady,
  unknown;

  /// The token written to the App Group. The Swift side switches on this
  /// string, so the names are a contract with `BaroEaseWidget` — renaming a
  /// value here means renaming it there.
  String get token => name;
}
