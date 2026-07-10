import 'package:geolocator/geolocator.dart';

import '../../domain/entities/geo_point.dart';

/// Abstracts geolocator so repositories are testable without the plugin.
abstract interface class LocationSource {
  /// The device's coarse position, or null when unavailable (services off,
  /// permission denied, timeout). Never throws.
  Future<GeoPoint?> currentPosition();
}

/// Hard rule: While-Using permission + reduced accuracy only, never Always.
class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource();

  @override
  Future<GeoPoint?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.reduced,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on Exception {
      return null;
    }
  }
}
