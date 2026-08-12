import 'package:geolocator/geolocator.dart';

import '../../../../core/logging/app_logger.dart';
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

/// Dev-only: answers a fixed point and never touches the plugin.
///
/// **It reports permission as granted, because there is nothing to ask.** The
/// point is already known, so raising the OS prompt would be theatre — and on
/// the Simulator the prompt is answered by a device that then still has no
/// position to give.
///
/// Only ever built by `locationSourceProvider`, and only when the dev-only
/// `DevLocation` preference is set — a prod flavour cannot reach the row that
/// writes it.
class FakeLocationSource implements LocationSource {
  const FakeLocationSource(this.point);

  final GeoPoint point;

  @override
  Future<GeoPoint?> currentPosition() async {
    // Loud on purpose: every weather number downstream is from somewhere the
    // device is not, and that must be obvious in the log rather than deduced.
    AppLogger.warning('Faked position', <String, Object?>{
      'latitude': point.latitude,
      'longitude': point.longitude,
    });

    return point;
  }

  @override
  Future<bool> requestPermission() async => true;
}

/// Hard rule 2: While-Using permission + reduced accuracy only, never Always.
class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource();

  @override
  Future<GeoPoint?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        AppLogger.warning('No position: location services are off');

        return null;
      }

      // Read-only: an undecided permission means no position, not a prompt.
      // Whoever wants the prompt calls requestPermission.
      final LocationPermission permission = await Geolocator.checkPermission();

      if (!_granted(permission)) {
        // Every weather read starts here, so the reason there is no weather
        // is usually this line rather than anything the backend did.
        AppLogger.warning('No position: permission', permission.name);

        return null;
      }

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
    } catch (error, stackTrace) {
      AppLogger.error(
        'Reading position failed',
        error: error,
        stackTrace: stackTrace,
      );

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

      AppLogger.info('Location permission', permission.name);

      return _granted(permission);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Requesting location permission failed',
        error: error,
        stackTrace: stackTrace,
      );

      return false;
    }
  }

  bool _granted(LocationPermission permission) =>
      permission != LocationPermission.denied &&
      permission != LocationPermission.deniedForever;
}
