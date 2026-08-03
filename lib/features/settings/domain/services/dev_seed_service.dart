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
/// all have something to chew on.
///
/// **Every run produces a different data set.** Nothing is derived from the
/// row index — not the medication a row gets, not whether an attack has
/// weather, not which kind an export is — because a fixture that always looks
/// the same only ever exercises one shape of screen, and the layout bugs live
/// in the shapes you did not seed.
///
/// Two things stay deliberate rather than random: medication names are drawn
/// without replacement so no two rows collide, and pressure still sags as
/// intensity climbs so the correlation engine has a signal to find.
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

  /// How far back rows are scattered, in hours — a little over three months,
  /// which is enough for the weekly charts and the 90-day filters to have
  /// something in every bucket.
  static const int _windowHours = 2200;

  static const Uuid _uuid = Uuid();

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

  /// Clears the database, then writes a fresh data set into it. Unseeded
  /// [Random] on purpose — see the class doc.
  Future<void> seed() async {
    final Random random = Random();
    final DateTime now = DateTime.now().toUtc();
    final List<Medication> medications = _buildMedications(random, now);
    final List<Attack> attacks = _buildAttacks(random, now, medications);

    await _wipe.wipeAll();
    for (final Medication medication in medications) {
      await _medications.upsert(medication);
    }
    for (final Attack attack in attacks) {
      await _attacks.insert(attack);
    }
    await _seedExports(random, attacks, medications, now);
  }

  /// Names are drawn without replacement: the 30 names crossed with the 5
  /// doses give 150 combinations, shuffled, of which [seedCount] are kept.
  /// Duplicates would be indistinguishable rows in the medications list.
  List<Medication> _buildMedications(Random random, DateTime now) {
    final List<String> names = <String>[
      for (final String dose in _doses)
        for (final String name in _medicationNames) '$name$dose',
    ]..shuffle(random);

    // Without this, raising seedCount past the pool silently seeds fewer
    // medications than it claims and every count in the app looks wrong.
    assert(
      names.length >= seedCount,
      'seedCount ($seedCount) exceeds the ${names.length} name/dose '
      'combinations available — add names or doses.',
    );

    return <Medication>[
      for (final String name in names.take(seedCount))
        Medication(
          id: _uuid.v4(),
          name: name,
          createdAt: now.subtract(
            Duration(hours: random.nextInt(_windowHours)),
          ),
        ),
    ];
  }

  List<Attack> _buildAttacks(
    Random random,
    DateTime now,
    List<Medication> medications,
  ) => <Attack>[
    for (final int hoursAgo in _scatteredHours(random))
      _buildAttack(random, now.subtract(Duration(hours: hoursAgo)), medications),
  ];

  /// [seedCount] distinct hour offsets inside the window. Distinct so no two
  /// attacks land in the same hour — the history list groups by day and the
  /// charts bucket by hour, and a pile-up hides both.
  List<int> _scatteredHours(Random random) {
    final Set<int> hours = <int>{};

    while (hours.length < seedCount) {
      hours.add(random.nextInt(_windowHours));
    }

    return hours.toList();
  }

  Attack _buildAttack(
    Random random,
    DateTime startedAt,
    List<Medication> medications,
  ) {
    final int intensity = 1 + random.nextInt(10);
    // Roughly one in seven stays weatherless — that is the offline-log case
    // the backfill queue has to pick up. A chance, not every seventh row, so
    // the gaps land somewhere different each run.
    final bool offline = random.nextInt(7) == 0;
    final bool untreated = random.nextInt(5) == 0;
    final bool annotated = random.nextInt(4) == 0;

    return Attack(
      id: _uuid.v4(),
      startedAt: startedAt,
      intensity: intensity,
      location: HeadLocation.values[random.nextInt(HeadLocation.values.length)],
      medicationName: untreated
          ? null
          : medications[random.nextInt(medications.length)].name,
      symptoms: _pick(_symptoms, random),
      triggers: _pick(_triggers, random),
      notes: annotated ? _buildNote(random) : null,
      weather: offline ? null : _buildWeather(startedAt, intensity, random),
    );
  }

  /// Notes vary in length as well as content: a one-word note and a rambling
  /// one lay out differently everywhere they appear, and only seeding both
  /// shows it.
  String _buildNote(Random random) {
    final List<String> sentences = <String>[
      'Came on suddenly.',
      'Woke up with it.',
      'Eased off after lying down in the dark.',
      'Painkillers barely touched it.',
      'Weather turned that afternoon.',
      'Second one this week.',
      'Had to leave work early.',
    ]..shuffle(random);

    return sentences.take(1 + random.nextInt(3)).join(' ');
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
    Random random,
    List<Attack> attacks,
    List<Medication> medications,
    DateTime now,
  ) async {
    final Uint8List jsonBytes = utf8.encode(
      _export.toJson(attacks, medications, exportedAt: now),
    );
    final Uint8List csvBytes = utf8.encode(_export.toCsv(attacks));

    // Distinct hours again: the filename carries the timestamp, and two
    // exports of the same kind in the same second would collide on it.
    for (final int hoursAgo in _scatteredHours(random)) {
      final ExportKind kind = random.nextBool()
          ? ExportKind.json
          : ExportKind.csv;
      final DateTime createdAt = now.subtract(Duration(hours: hoursAgo));
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
