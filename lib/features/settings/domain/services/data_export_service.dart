import 'dart:convert';

import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/domain/enums/head_region.dart';
import '../../../medications/domain/entities/medication.dart';

/// Serializes the user's data for GDPR export. Pure Dart — file writing and the share sheet live in the data layer.
class DataExportService {
  const DataExportService();

  /// Bumped to 2 when the single `location` became a list of `regions`.
  static const int formatVersion = 2;

  String toJson(
    List<Attack> attacks,
    List<Medication> medications, {
    required DateTime exportedAt,
  }) {
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'baroease-export',
      'version': formatVersion,
      'exportedAtUtc': exportedAt.toUtc().toIso8601String(),
      'attacks': [
        for (final a in attacks)
          {
            'id': a.id,
            'startedAtUtc': a.startedAt.toIso8601String(),
            'intensity': a.intensity,
            'regions': <String>[for (final HeadRegion r in a.regions) r.name],
            'medication': a.medicationName,
            'symptoms': a.symptoms,
            'triggers': a.triggers,
            'notes': a.notes,
            'exertionLevel': a.exertionLevel?.name,
            'weather': a.weather == null
                ? null
                : {
                    'capturedAtUtc': a.weather!.capturedAt.toIso8601String(),
                    'pressureHpa': a.weather!.pressureHpa,
                    'pressureDelta24hHpa': a.weather!.pressureDelta24hHpa,
                    'humidityPercent': a.weather!.humidityPercent,
                    'temperatureCelsius': a.weather!.temperatureCelsius,
                  },
          },
      ],
      'medications': [
        for (final m in medications)
          {
            'id': m.id,
            'name': m.name,
            'createdAtUtc': m.createdAt?.toUtc().toIso8601String(),
          },
      ],
    });
  }

  String toCsv(List<Attack> attacks) {
    const header =
        'id,started_at_utc,intensity,regions,medication,symptoms,triggers,'
        'notes,exertion_level,pressure_hpa,pressure_delta_24h_hpa,humidity_percent,'
        'temperature_c,weather_captured_at_utc';
    final rows = [
      header,
      for (final a in attacks)
        [
          a.id,
          a.startedAt.toIso8601String(),
          '${a.intensity}',
          a.regions.map((HeadRegion r) => r.name).join('|'),
          a.medicationName ?? '',
          a.symptoms.join('|'),
          a.triggers.join('|'),
          a.notes ?? '',
          a.exertionLevel?.name ?? '',
          '${a.weather?.pressureHpa ?? ''}',
          '${a.weather?.pressureDelta24hHpa ?? ''}',
          '${a.weather?.humidityPercent ?? ''}',
          '${a.weather?.temperatureCelsius ?? ''}',
          a.weather?.capturedAt.toIso8601String() ?? '',
        ].map(_escape).join(','),
    ];

    return rows.join('\r\n');
  }

  String _escape(String field) {
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
