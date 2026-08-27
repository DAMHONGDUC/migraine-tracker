import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/exertion_level.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:migraine_tracker/features/settings/domain/services/data_export_service.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

void main() {
  const service = DataExportService();

  final full = Attack(
    id: 'a1',
    startedAt: DateTime.utc(2026, 7, 1, 8, 30),
    intensity: 7,
    regions: const <HeadRegion>[HeadRegion.templeR],
    medicationName: 'Sumatriptan',
    symptoms: const ['aura', 'nausea'],
    triggers: const ['stress'],
    notes: 'notes with, comma and "quotes"\nand a newline',
    exertionLevel: ExertionLevel.moderate,
    weather: WeatherSnapshot(
      capturedAt: DateTime.utc(2026, 7, 1, 8),
      pressureHpa: 1008.2,
      pressureDelta24hHpa: -6.4,
      humidityPercent: 71.5,
      temperatureCelsius: 19.3,
    ),
  );
  final bare = Attack(
    id: 'a2',
    startedAt: DateTime.utc(2026, 7, 2),
    intensity: 3,
    regions: const <HeadRegion>[HeadRegion.foreheadL],
  );

  group('toJson', () {
    test('roundtrips every field including weather', () {
      final json =
          jsonDecode(
                service.toJson(
                  [full, bare],
                  [
                    Medication(
                      id: 'm1',
                      name: 'Ibuprofen',
                      createdAt: DateTime.utc(2026, 6, 1),
                    ),
                    const Medication(id: 'm2', name: 'Unknown creation date'),
                  ],
                  exportedAt: DateTime.utc(2026, 7, 8, 12),
                ),
              )
              as Map<String, dynamic>;

      expect(json['format'], 'baroease-export');
      expect(json['version'], DataExportService.formatVersion);
      expect(json['exportedAtUtc'], '2026-07-08T12:00:00.000Z');

      final attacks = json['attacks'] as List<dynamic>;
      final a1 = attacks[0] as Map<String, dynamic>;
      expect(a1['id'], 'a1');
      expect(a1['startedAtUtc'], '2026-07-01T08:30:00.000Z');
      expect(a1['intensity'], 7);
      expect(a1['regions'], <String>['templeR']);
      expect(a1['medication'], 'Sumatriptan');
      expect(a1['symptoms'], ['aura', 'nausea']);
      expect(a1['exertionLevel'], 'moderate');
      final weather = a1['weather'] as Map<String, dynamic>;
      expect(weather['pressureDelta24hHpa'], -6.4);

      final a2 = attacks[1] as Map<String, dynamic>;
      expect(a2['weather'], isNull);
      expect(a2['medication'], isNull);
      expect(a2['exertionLevel'], isNull);

      final meds = json['medications'] as List<dynamic>;
      final m1 = meds[0] as Map<String, dynamic>;
      expect(m1['name'], 'Ibuprofen');
      expect(m1['createdAtUtc'], '2026-06-01T00:00:00.000Z');
      final m2 = meds[1] as Map<String, dynamic>;
      expect(m2['createdAtUtc'], isNull);
    });
  });

  group('toCsv', () {
    test('escapes commas, quotes, and newlines per RFC 4180', () {
      final csv = service.toCsv([full]);
      final lines = csv.split('\r\n');
      expect(lines.first, startsWith('id,started_at_utc,intensity'));
      // The notes field must be quoted with doubled inner quotes; the
      // embedded newline stays inside the quoted field.
      expect(
        csv,
        contains('"notes with, comma and ""quotes""\nand a newline"'),
      );
      expect(csv, contains('aura|nausea'));
      expect(csv, contains(',moderate,'));
      expect(csv, contains('-6.4'));
    });

    test('missing weather, medication and exertion become empty fields', () {
      final csv = service.toCsv([bare]);
      final row = csv.split('\r\n')[1];
      expect(row, 'a2,2026-07-02T00:00:00.000Z,3,foreheadL,,,,,,,,,,');
    });

    test('empty export is just the header', () {
      expect(service.toCsv([]).split('\r\n'), hasLength(1));
    });
  });
}
