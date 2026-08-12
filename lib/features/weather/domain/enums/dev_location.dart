import '../entities/geo_point.dart';

/// Dev-only: a fixed position to read the weather at, instead of the device's.
///
/// **This exists because the Simulator has no location.** A fresh Simulator
/// reports none at all, so every weather read stops at "no location" before it
/// ever reaches the backend — which looks exactly like a backend that is
/// broken. Pinning a city separates the two questions.
///
/// It lives in `weather/` rather than in `settings/`, because what it replaces
/// is this feature's `LocationSource`; Settings only owns the row that picks
/// it.
///
/// **Never reachable in a prod flavour** — the Settings section that offers it
/// is behind `!AppEnv.isProd`, and nothing else writes the preference.
enum DevLocation {
  /// The real device position. The default, and what a prod build always is.
  off(null, null),

  // Four cities, picked to disagree with each other on the readings the
  // weather card draws: rain and humidity, UV, and visibility.
  hanoi(21.0278, 105.8342),
  tokyo(35.6762, 139.6503),
  london(51.5074, -0.1278),
  sanFrancisco(37.7749, -122.4194);

  const DevLocation(this._latitude, this._longitude);

  final double? _latitude;
  final double? _longitude;

  /// The point to read at, or null for [off] — which is what tells the wiring
  /// to keep the real source.
  GeoPoint? get point => _latitude == null || _longitude == null
      ? null
      : GeoPoint(latitude: _latitude, longitude: _longitude);

  /// The stored name back to a value, defaulting to [off].
  ///
  /// Unknown names fall back rather than throw: the preference outlives the
  /// build that wrote it, and a city dropped from this list must not brick
  /// Settings for whoever had it selected.
  static DevLocation fromName(String? name) => values.firstWhere(
    (DevLocation location) => location.name == name,
    orElse: () => off,
  );
}
