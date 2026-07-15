import '../entities/pressure_forecast.dart';
import '../entities/weather_snapshot.dart';

/// Provides weather snapshots for the user's current location.
///
/// Implementations must be best-effort: any failure (offline, permission
/// denied, instant outside the provider's data window) returns null rather
/// than throwing — logging an attack never depends on the network.
abstract interface class WeatherRepository {
  /// The weather at the user's location at [instant] (hour resolution).
  /// Used both when logging (instant ≈ now) and when backfilling attacks
  /// that were logged offline (instant = the attack's start time).
  Future<WeatherSnapshot?> snapshotAt(DateTime instant);

  /// Hourly pressure for the forecast chart: ~12h behind and 48h ahead of
  /// now at the user's location.
  Future<PressureForecast?> pressureForecast();
}
