import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../entities/daily_pressure.dart';
import '../entities/weather_snapshot.dart';
import '../repositories/daily_pressure_repository.dart';
import '../repositories/weather_repository.dart';

/// Records one pressure reading per day, so the correlation has days without an attack to compare against.
class DailyPressureRecorder {
  const DailyPressureRecorder(this._readings, this._weather);

  final DailyPressureRepository _readings;
  final WeatherRepository _weather;

  /// Called on launch and on resume.
  Future<void> recordToday({DateTime? now}) async {
    final DateTime today = now ?? DateTime.now();

    try {
      if (await _readings.hasDay(today)) return;

      final WeatherSnapshot? snapshot = await _weather.snapshotAt(today);

      if (snapshot == null) {
        SdLogger.info(
          LogTagConstant.pressureRecord,
          'No daily pressure reading yet (offline or no location)',
        );
        return;
      }
      await _readings.upsert(
        DailyPressure(
          day: today,
          pressureHpa: snapshot.pressureHpa,
          pressureDelta24hHpa: snapshot.pressureDelta24hHpa,
          // Free: the snapshot the pressure came from already carried both.
          humidityPercent: snapshot.humidityPercent,
          temperatureCelsius: snapshot.temperatureCelsius,
        ),
      );
      SdLogger.debug(
        LogTagConstant.pressureRecord,
        'Daily pressure recorded',
        snapshot.pressureHpa,
      );
    } on Exception catch (error, stackTrace) {
      // Swallow: a missing day costs a little precision in the baseline and nothing else. It runs unawaited at launch, where a throw is worse.
      SdLogger.warning(
        LogTagConstant.pressureRecord,
        'Daily pressure recording failed',
        error,
      );
      SdLogger.debug(
        LogTagConstant.pressureRecord,
        'Daily pressure stack',
        stackTrace,
      );
    }
  }
}
