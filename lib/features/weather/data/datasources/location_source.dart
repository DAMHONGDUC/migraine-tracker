import 'package:geolocator/geolocator.dart';

import '../../domain/entities/geo_point.dart';

/// Abstracts geolocator so repositories are testable without the plugin.
///
/// **Reading a position and asking for permission are separate calls, on
/// purpose.** They used to be one, and every weather read — launch, resume,
/// logging an attack, opening the forecast — could raise the OS prompt. The
/// app asks once, where the ask is explained: the onboarding location step.
abstract interface class LocationSource {
  /// The device's coarse position, or null when unavailable (services off,
  /// permission not granted, timeout). Never throws, and **never prompts**.
  Future<GeoPoint?> currentPosition();

  /// Raises the While-Using prompt if it can still be shown. Returns whether
  /// location is usable afterwards. Never throws.
  Future<bool> requestPermission();
}

/// Hard rule 2: While-Using permission + reduced accuracy only, never Always.
class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource();

  @override
  Future<GeoPoint?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      // Read-only: an undecided permission means no position, not a prompt.
      // Whoever wants the prompt calls requestPermission.
      if (!_granted(await Geolocator.checkPermission())) return null;

      final Position position = await Geolocator.getCurrentPosition(
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

  @override
  Future<bool> requestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      // Only `denied` can still produce a dialog — `deniedForever` needs the
      // Settings app, and asking again there is a no-op the user never sees.
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return _granted(permission);
    } on Exception {
      return false;
    }
  }

  bool _granted(LocationPermission permission) =>
      permission != LocationPermission.denied &&
      permission != LocationPermission.deniedForever;
}
