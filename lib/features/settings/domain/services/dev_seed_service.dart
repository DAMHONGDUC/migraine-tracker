import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/domain/enums/exertion_level.dart';
import '../../../attacks/domain/enums/head_location.dart';
import '../../../attacks/domain/repositories/attack_repository.dart';
import '../../../medications/domain/entities/medication.dart';
import '../../../medications/domain/entities/medication_reminder.dart';
import '../../../medications/domain/repositories/medication_reminder_repository.dart';
import '../../../medications/domain/repositories/medication_repository.dart';
import '../../../notifications/domain/entities/app_notification.dart';
import '../../../notifications/domain/enums/notification_type.dart';
import '../../../notifications/domain/repositories/notification_repository.dart';
import '../../../weather/domain/entities/daily_pressure.dart';
import '../../../weather/domain/entities/weather_snapshot.dart';
import '../../../weather/domain/repositories/daily_pressure_repository.dart';
import '../entities/export_record.dart';
import '../enums/export_kind.dart';
import '../repositories/export_record_repository.dart';
import 'data_export_service.dart';
import 'data_wipe_service.dart';
import 'export_file_store.dart';

/// Dev-only fixture generator: wipes whatever is on the device, then refills
/// it with [seedCount] medications (most carrying a reminder or three),
/// [seedCount] attacks and [seedCount] past exports so charts, filters, the
/// export history and the correlation engine all have something to chew on.
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
    this._reminders,
    this._export,
    this._exportFiles,
    this._exportRecords,
    this._notifications,
    this._dailyPressure,
  );

  final DataWipeService _wipe;
  final AttackRepository _attacks;
  final MedicationRepository _medications;
  final MedicationReminderRepository _reminders;
  final DataExportService _export;
  final ExportFileStore _exportFiles;
  final ExportRecordRepository _exportRecords;
  final NotificationRepository _notifications;
  final DailyPressureRepository _dailyPressure;

  /// How many rows of each kind a seed produces.
  static const int seedCount = 100;

  /// How many medications get [crowdedReminders] instead of a handful.
  static const int crowdedMedications = 3;

  /// The pile a crowded medication gets. Nobody types twenty reminders by
  /// hand, which is exactly why the detail screen has to be seeded with them
  /// — a list that only ever holds three never shows what scrolling costs.
  static const int crowdedReminders = 20;

  /// How many seeded rows are deleted again, to leave tombstones behind.
  static const int _tombstoneCount = 5;

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
    // After the medications exist: a reminder is a foreign key onto one.
    final List<MedicationReminder> reminders = await _seedReminders(
      random,
      medications,
    );

    for (final Attack attack in attacks) {
      await _attacks.insert(attack);
    }

    await _seedExports(random, attacks, medications, now);
    await _seedDailyPressure(random, attacks, now);
    await _seedNotifications(random, reminders, now);
    // Last: it deletes some of what the steps above wrote.
    await _seedTombstones(random, attacks, medications);
  }

  /// One reading per local day across the window, attacks or no attacks.
  ///
  /// This is the correlation's denominator (hard rule: `DailyPressure`), so
  /// without it the pressure card can only ever say "what share of MY attacks
  /// fell during drops" and never "am I more likely to attack when it drops".
  /// Seeding it is what makes the seeded correlation reach a real verdict.
  ///
  /// Days that ended in an attack are biased to drop, so the two sides differ
  /// and `PressureBaseline` has something to find.
  Future<void> _seedDailyPressure(
    Random random,
    List<Attack> attacks,
    DateTime now,
  ) async {
    final Set<DateTime> attackDays = <DateTime>{
      for (final Attack attack in attacks) _dayOf(attack.startedAt.toLocal()),
    };
    final int days = (_windowHours / 24).ceil();

    for (int back = 0; back < days; back++) {
      final DateTime day = _dayOf(
        now.toLocal().subtract(Duration(days: back)),
      );
      // A drop on ~65% of attack days against ~25% of the rest — a signal
      // that is strong enough to read and weak enough to stay believable.
      final bool drops = random.nextInt(100) <
          (attackDays.contains(day) ? 65 : 25);
      final double delta = drops
          ? -5 - random.nextDouble() * 9
          : -3 + random.nextDouble() * 7;

      await _dailyPressure.upsert(
        DailyPressure(
          day: day,
          pressureHpa: 1013 + random.nextDouble() * 16 - 8,
          pressureDelta24hHpa: delta,
        ),
      );
    }
  }

  /// Both kinds of notification, most read and some not, so the bell carries
  /// a count and the two tabs each have rows.
  ///
  /// Ids come from the same derivers the real writers use
  /// ([AppNotification.reminderOccurrenceId] / `.pressureAlertId`), never
  /// from a UUID — a random id here would be a row no real writer could ever
  /// match, which is exactly the idempotence the list depends on.
  Future<void> _seedNotifications(
    Random random,
    List<MedicationReminder> reminders,
    DateTime now,
  ) async {
    final List<AppNotification> rows = <AppNotification>[];

    // Reminder occurrences: past firings of reminders that actually exist.
    for (int i = 0; i < seedCount && reminders.isNotEmpty; i++) {
      final MedicationReminder reminder =
          reminders[random.nextInt(reminders.length)];
      final DateTime at = now.subtract(
        Duration(hours: random.nextInt(_windowHours)),
      );

      rows.add(
        AppNotification(
          id: AppNotification.reminderOccurrenceId(reminder.id, at),
          type: NotificationType.medicationReminder,
          occurredAt: at,
          readAt: _maybeRead(random, at),
          medicationId: reminder.medicationId,
          reminderId: reminder.id,
        ),
      );
    }

    // Pressure alerts, rarer than reminders — the cron sends at most one a
    // day per user, so a list with as many alerts as reminders would lie.
    for (int i = 0; i < seedCount ~/ 5; i++) {
      final DateTime at = now.subtract(
        Duration(hours: random.nextInt(_windowHours)),
      );

      rows.add(
        AppNotification(
          id: AppNotification.pressureAlertId('seed-${_uuid.v4()}'),
          type: NotificationType.pressureAlert,
          occurredAt: at,
          readAt: _maybeRead(random, at),
          pressureDropHpa: 5 + random.nextDouble() * 10,
        ),
      );
    }

    await _notifications.addMissing(rows);
  }

  /// Read a little after it arrived, or not at all. Roughly a third stay
  /// unread so the bell has a count and the rows have their dot.
  DateTime? _maybeRead(Random random, DateTime occurredAt) =>
      random.nextInt(3) == 0
      ? null
      : occurredAt.add(Duration(minutes: 1 + random.nextInt(600)));

  /// Deletes a few of the rows just written, which is the ONLY way a
  /// tombstone is made: the table is sync bookkeeping, written by the delete
  /// path, so seeding it by hand would fabricate rows no delete produced.
  ///
  /// The ids were never uploaded, so a sync issues deletes the server has
  /// nothing to match — the same no-op a real "created and deleted while
  /// offline" record produces.
  Future<void> _seedTombstones(
    Random random,
    List<Attack> attacks,
    List<Medication> medications,
  ) async {
    final List<Attack> doomedAttacks = List<Attack>.of(attacks)
      ..shuffle(random);
    final List<Medication> doomedMedications = List<Medication>.of(medications)
      ..shuffle(random);

    for (final Attack attack in doomedAttacks.take(_tombstoneCount)) {
      await _attacks.deleteById(attack.id);
    }
    // Cascades its reminders away too, which is the case the pull path has
    // to handle and the one nothing else in the seed produces.
    for (final Medication medication in doomedMedications.take(2)) {
      await _medications.deleteById(medication.id);
    }
  }

  DateTime _dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Reminder counts are lopsided on purpose. Most medications have none or
  /// a couple — that is what the reminder filter and the list's count line
  /// are for — and [crowdedMedications] of them get [crowdedReminders], so
  /// the detail screen is always seeded with one list long enough to scroll.
  ///
  /// Written straight to the repository, never through `RemindersController`:
  /// these are fixtures, and scheduling hundreds of real notifications on a
  /// dev device would be a genuinely unpleasant afternoon.
  Future<List<MedicationReminder>> _seedReminders(
    Random random,
    List<Medication> medications,
  ) async {
    final List<Medication> shuffled = List<Medication>.of(medications)
      ..shuffle(random);
    final List<MedicationReminder> created = <MedicationReminder>[];

    for (int i = 0; i < shuffled.length; i++) {
      final int count = i < crowdedMedications
          ? crowdedReminders
          : _casualReminderCount(random);

      for (final int minuteOfDay in _distinctMinutes(random, count)) {
        final MedicationReminder reminder = MedicationReminder(
          id: _uuid.v4(),
          medicationId: shuffled[i].id,
          minuteOfDay: minuteOfDay,
          // One in five is off — exercises the disabled row style and the filter count.
          enabled: random.nextInt(5) != 0,
        );

        await _reminders.upsert(reminder);
        created.add(reminder);
      }
    }

    return created;
  }

  /// 0–5, weighted low. The zeros matter as much as the rest — a medications
  /// list where every row has reminders never shows the empty case.
  int _casualReminderCount(Random random) {
    final int roll = random.nextInt(10);

    if (roll < 4) return 0;
    if (roll < 8) return 1 + random.nextInt(2);
    return 3 + random.nextInt(3);
  }

  /// [count] distinct times of day. Distinct because two reminders at the
  /// same minute are indistinguishable rows, and the user could not have
  /// created them either.
  Set<int> _distinctMinutes(Random random, int count) {
    final Set<int> minutes = <int>{};

    while (minutes.length < count) {
      minutes.add(random.nextInt(24 * 60));
    }

    return minutes;
  }

  /// Names are drawn without replacement: the 30 names crossed with the 5
  /// doses give 150 combinations, shuffled, of which [seedCount] are kept.
  /// Duplicates would be indistinguishable rows in the medications list.
  List<Medication> _buildMedications(Random random, DateTime now) {
    final List<String> names = <String>[
      for (final String dose in _doses)
        for (final String name in _medicationNames) '$name$dose',
    ]..shuffle(random);

    // Without this, raising seedCount past the pool silently under-seeds.
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
      _buildAttack(
        random,
        now.subtract(Duration(hours: hoursAgo)),
        medications,
      ),
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
    // - roughly one in seven stays weatherless, the offline-log case the backfill queue handles
    // - a chance, not exact, so the gaps land differently each run
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
      exertionLevel: _buildExertion(random, intensity),
      weather: offline ? null : _buildWeather(startedAt, intensity, random),
    );
  }

  /// Exertion tracks intensity the way the seeded weather does, so the
  /// exertion engine sees a signal rather than noise — and every level shows
  /// up, including [ExertionLevel.none].
  ///
  /// A few stay null on purpose: attacks logged before the step existed, a
  /// case the detail screen and the engine both still have to handle.
  ExertionLevel? _buildExertion(Random random, int intensity) {
    if (random.nextInt(8) == 0) return null;

    final int roll = random.nextInt(10) + intensity;

    if (roll >= 14) return ExertionLevel.severe;
    if (roll >= 10) return ExertionLevel.moderate;
    if (roll >= 6) return ExertionLevel.light;

    return ExertionLevel.none;
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

    // Distinct hours again: same-second exports of the same kind would collide on the filename.
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
