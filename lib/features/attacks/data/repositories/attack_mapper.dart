import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../../weather/domain/entities/weather_snapshot.dart';
import '../../domain/entities/attack.dart';

/// Row ↔ domain translation for attacks, shared by the plain repository and
/// the sync one so the two can never disagree about a field.
final class AttackMapper {
  const AttackMapper._();

  static Attack toDomain(AttackRow row, WeatherSnapshotRow? weather) => Attack(
    id: row.id,
    startedAt: row.startedAt,
    intensity: row.intensity,
    regions: row.regions,
    medicationName: row.medicationName,
    symptoms: row.symptoms,
    triggers: row.triggers,
    notes: row.notes,
    exertionLevel: row.exertionLevel,
    medicationEffect: row.medicationEffect,
    endedAt: row.endedAt,
    weather: weather == null ? null : toWeatherDomain(weather),
  );

  static WeatherSnapshot toWeatherDomain(WeatherSnapshotRow row) =>
      WeatherSnapshot(
        capturedAt: row.capturedAt,
        pressureHpa: row.pressureHpa,
        pressureDelta24hHpa: row.pressureDelta24hHpa,
        humidityPercent: row.humidityPercent,
        temperatureCelsius: row.temperatureCelsius,
      );

  /// [syncedRevision] is set only for a row arriving from the server, which is
  /// in step by definition; a locally logged attack starts dirty.
  static AttacksCompanion toRow(
    Attack attack, {
    required DateTime updatedAt,
    required int revision,
    int? syncedRevision,
  }) => AttacksCompanion.insert(
    id: attack.id,
    startedAt: attack.startedAt,
    intensity: attack.intensity,
    regions: Value(attack.regions),
    medicationName: Value(attack.medicationName),
    symptoms: Value(attack.symptoms),
    triggers: Value(attack.triggers),
    notes: Value(attack.notes),
    exertionLevel: Value(attack.exertionLevel),
    medicationEffect: Value(attack.medicationEffect),
    endedAt: Value(attack.endedAt),
    updatedAt: Value(updatedAt),
    revision: Value(revision),
    syncedRevision: Value(syncedRevision),
  );

  static WeatherSnapshotsCompanion toWeatherRow(
    String attackId,
    WeatherSnapshot weather,
  ) => WeatherSnapshotsCompanion.insert(
    attackId: attackId,
    capturedAt: weather.capturedAt,
    pressureHpa: weather.pressureHpa,
    pressureDelta24hHpa: weather.pressureDelta24hHpa,
    humidityPercent: Value(weather.humidityPercent),
    temperatureCelsius: Value(weather.temperatureCelsius),
  );
}
