/// Which way pressure moved over the last 24 hours, as the home-screen widget draws it.
enum PressureTrend {
  falling,
  rising,
  steady,
  unknown;

  /// The token written to the App Group.
  String get token => name;
}
