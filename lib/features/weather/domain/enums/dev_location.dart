import '../entities/geo_point.dart';

/// Dev-only: a fixed position to read the weather at, instead of the device's.
enum DevLocation {
  /// The real device position. The default, and what a prod build always is.
  off(null, null),

  // Four cities, picked to disagree with each other on the readings the weather card draws: rain and humidity, UV, and visibility.
  hanoi(21.0278, 105.8342),
  tokyo(35.6762, 139.6503),
  london(51.5074, -0.1278),
  sanFrancisco(37.7749, -122.4194);

  const DevLocation(this._latitude, this._longitude);

  final double? _latitude;
  final double? _longitude;

  /// The point to read at, or null for [off] — which is what tells the wiring to keep the real source.
  GeoPoint? get point => _latitude == null || _longitude == null
      ? null
      : GeoPoint(latitude: _latitude, longitude: _longitude);

  /// The stored name back to a value, defaulting to [off].
  static DevLocation fromName(String? name) => values.firstWhere(
    (DevLocation location) => location.name == name,
    orElse: () => off,
  );
}
