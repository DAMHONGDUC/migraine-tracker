import '../entities/pressure_forecast.dart';
import '../entities/weather_report.dart';
import '../entities/weather_snapshot.dart';

/// Provides weather snapshots for the user's current location.
abstract interface class WeatherRepository {
  /// The weather at the user's location at [instant] (hour resolution).
  Future<WeatherSnapshot?> snapshotAt(DateTime instant);

  /// Hourly pressure for the forecast chart: ~12h behind and 48h ahead of now at the user's location.
  Future<PressureForecast?> pressureForecast();

  /// Everything the weather card shows — conditions now, the hours ahead and the days after — for the user's current location.
  Future<WeatherReport?> report();
}
