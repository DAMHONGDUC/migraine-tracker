import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/domain/enums/head_location.dart';
import '../../../attacks/domain/repositories/attack_repository.dart';
import '../../../medications/domain/entities/medication.dart';
import '../../../medications/domain/repositories/medication_repository.dart';
import '../../../weather/domain/entities/weather_snapshot.dart';
import '../entities/export_record.dart';
import '../enums/export_kind.dart';
import '../repositories/export_record_repository.dart';
import 'data_export_service.dart';
import 'data_wipe_service.dart';
import 'export_file_store.dart';

/// Dev-only fixture generator: wipes whatever is on the device, then refills
/// it with [seedCount] medications, [seedCount] attacks and [seedCount] past
/// exports so charts, filters, the export history and the correlation engine
/// all have something to chew on. The seed is fixed, so two runs produce the
/// same data set.
///
/// Never reachable in a prod flavour — the settings row that calls it is
/// hidden behind `!AppEnv.isProd`.
class DevSeedService {
  const DevSeedService(
    this._wipe,
    this._attacks,
    this._medications,
    this._export,
    this._exportFiles,
    this._exportRecords,
  );

  final DataWipeService _wipe;
  final AttackRepository _attacks;
  final MedicationRepository _medications;
  final DataExportService _export;
  final ExportFileStore _exportFiles;
  final ExportRecordRepository _exportRecords;

  /// How many rows of each kind a seed produces.
  static const int seedCount = 100;

  static const Uuid _uuid = Uuid();

  /// Fixed so a seeded database is reproducible between runs.
  static const int _randomSeed = 42;

  static const List<String> _medicationNames = <String>[
    'Ibuprofen',
    'Paracetamol',
    'Aspirin',
    'Naproxen',
    'Diclofenac',
    'Sumatriptan',
    'Rizatriptan',
    'Zolmitriptan',
    'Eletriptan',
    'Naratriptan',
    'Frovatriptan',
    'Almotriptan',
    'Topiramate',
    'Propranolol',
    'Metoprolol',
    'Amitriptyline',
    'Candesartan',
    'Valproate',
    'Flunarizine',
    'Metoclopramide',
    'Domperidone',
    'Ondansetron',
    'Riboflavin',
    'Magnesium',
    'Coenzyme Q10',
    'Melatonin',
    'Erenumab',
    'Galcanezumab',
    'Rimegepant',
    'Atogepant',
  ];

  /// Suffixes that turn the 30 names above into [seedCount] distinct rows.
  static const List<String> _doses = <String>[
    '',
    ' 50mg',
    ' 100mg',
    ' 200mg',
    ' 400mg',
  ];

  static const List<String> _symptoms = <String>[
    'nausea',
    'aura',
    'light sensitivity',
    'sound sensitivity',
    'dizziness',
    'neck pain',
  ];

  static const List<String> _triggers = <String>[
    'pressure drop',
    'poor sleep',
    'stress',
    'skipped meal',
    'screen time',
    'dehydration',
  ];

  /// Clears the database, then writes a fresh data set into it.
  Future<void> seed() async {
    final Random random = Random(_randomSeed);
    final DateTime now = DateTime.now().toUtc();
    final List<Medication> medications = _buildMedications(now);
    final List<Attack> attacks = _buildAttacks(random, now, medications);

    await _wipe.wipeAll();
    for (final Medication medication in medications) {
      await _medications.upsert(medication);
    }
    for (final Attack attack in attacks) {
      await _attacks.insert(attack);
    }
    await _seedExports(attacks, medications, now);
  }

  List<Medication> _buildMedications(DateTime now) => List<Medication>.generate(
    seedCount,
    (int index) => Medication(
      id: _uuid.v4(),
      name:
          '${_medicationNames[index % _medicationNames.length]}'
          '${_doses[index ~/ _medicationNames.length]}',
      createdAt: now.subtract(Duration(days: seedCount - index)),
    ),
  );

  List<Attack> _buildAttacks(
    Random random,
    DateTime now,
    List<Medication> medications,
  ) => List<Attack>.generate(
    seedCount,
    (int index) => _buildAttack(index, random, now, medications),
  );

  Attack _buildAttack(
    int index,
    Random random,
    DateTime now,
    List<Medication> medications,
  ) {
    // ~20h apart plus jitter: roughly three months back, never two per hour.
    final DateTime startedAt = now.subtract(
      Duration(hours: index * 20 + random.nextInt(8)),
    );
    final int intensity = 1 + random.nextInt(10);
    final bool offline = index % 7 == 0;

    return Attack(
      id: _uuid.v4(),
      startedAt: startedAt,
      intensity: intensity,
      location: HeadLocation.values[random.nextInt(HeadLocation.values.length)],
      medicationName: index % 5 == 0
          ? null
          : medications[random.nextInt(medications.length)].name,
      symptoms: _pick(_symptoms, random),
      triggers: _pick(_triggers, random),
      notes: index % 4 == 0 ? 'Seeded sample attack #$index' : null,
      // Every seventh one stays weatherless — that is the offline-log case
      // the backfill queue has to pick up.
      weather: offline ? null : _buildWeather(startedAt, intensity, random),
    );
  }

  /// Pressure sags as intensity climbs, so the correlation engine sees a
  /// real (if invented) signal instead of noise.
  WeatherSnapshot _buildWeather(
    DateTime capturedAt,
    int intensity,
    Random random,
  ) {
    final double delta = -1.5 * intensity + random.nextDouble() * 6 - 3;

    return WeatherSnapshot(
      capturedAt: capturedAt,
      pressureHpa: 1013 + delta + random.nextDouble() * 8 - 4,
      pressureDelta24hHpa: delta,
      humidityPercent: 45 + random.nextDouble() * 45,
      temperatureCelsius: 8 + random.nextDouble() * 22,
    );
  }

  /// Real files with real content, exactly like [ExportKind.json] and
  /// [ExportKind.csv] exports produced by hand — the history screen can
  /// share and save these. No PDF row: a fake one would point at a file no
  /// viewer could open.
  Future<void> _seedExports(
    List<Attack> attacks,
    List<Medication> medications,
    DateTime now,
  ) async {
    final Uint8List jsonBytes = utf8.encode(
      _export.toJson(attacks, medications, exportedAt: now),
    );
    final Uint8List csvBytes = utf8.encode(_export.toCsv(attacks));

    for (int index = 0; index < seedCount; index++) {
      final ExportKind kind = index.isEven ? ExportKind.json : ExportKind.csv;
      final DateTime createdAt = now.subtract(Duration(hours: index * 19 + 3));
      final String filename =
          'baroease_export_${_stamp(createdAt)}.${kind.fileExtension}';
      final StoredExportFile stored = await _exportFiles.write(
        filename: filename,
        bytes: kind == ExportKind.json ? jsonBytes : csvBytes,
      );

      await _exportRecords.insert(
        ExportRecord(
          id: _uuid.v4(),
          kind: kind,
          filename: filename,
          filePath: stored.path,
          sizeBytes: stored.sizeBytes,
          createdAt: createdAt,
        ),
      );
    }
  }

  /// `yyyy-MM-dd_HHmmss`, matching the filenames `ExportController` writes.
  String _stamp(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    final String second = date.second.toString().padLeft(2, '0');

    return '${date.year}-$month-${day}_$hour$minute$second';
  }

  List<String> _pick(List<String> source, Random random) {
    final List<String> shuffled = List<String>.of(source)..shuffle(random);

    return shuffled.take(random.nextInt(3)).toList();
  }
}
