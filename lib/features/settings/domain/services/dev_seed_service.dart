import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:system_design/common.dart';

import '../../../../core/constants/premium_limit_constant.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/domain/enums/exertion_level.dart';
import '../../../attacks/domain/enums/head_region.dart';
import '../../../attacks/domain/repositories/attack_repository.dart';
import '../../../daily_log/domain/entities/daily_log.dart';
import '../../../daily_log/domain/enums/daily_factor.dart';
import '../../../daily_log/domain/repositories/daily_log_repository.dart';
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

/// Dev-only fixture generator: wipes whatever is on the device, then refills it with a handful of rows — [medicationCount] medications, [attackCount].
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
    this._dailyLogs,
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
  final DailyLogRepository _dailyLogs;

  /// How many rows each list is left holding. Owner's numbers.
  static const int attackCount = 5;
  static const int medicationCount = 5;

  /// Reminders in total, one per medication — not per medication, and no crowded row any more: the counts above are the whole data set now.
  static const int reminderCount = 2;

  static const int exportCount = 5;

  /// Notifications of each kind. Alerts stay rarer than reminder firings, because the cron sends at most one a day per user.
  static const int notificationCount = 5;
  static const int pressureAlertCount = 1;

  /// Attacks written deliberately BEHIND the free plan's readable window, so a
  /// dev build always has History's blurred rows on it (owner's rule,
  /// 2026-09-21).
  ///
  /// **Forced, not rolled, for the reason the weatherless attack is.** The
  /// scatter window is 2200h — a hair over ninety days — so a run landed a
  /// locked row perhaps one time in ten, and a state that appears one run in
  /// ten is a state nobody reviews. Two rather than one: one blurred row reads
  /// as a glitch on that row, two read as a rule.
  ///
  /// **On top of [attackCount], not carved out of it.** The readable list still
  /// holds the owner's five, exactly as the tombstone surplus is written on top
  /// rather than taken out — every other screen is sized against those five.
  static const int lockedAttackCount = 2;

  /// Attacks on the device once a seed has run: [attackCount] inside the window
  /// and [lockedAttackCount] behind it. What a test counts.
  static const int seededAttackCount = attackCount + lockedAttackCount;

  /// How far behind the window a locked attack lands, in days. Far enough that
  /// no rounding of a day or a timezone could put it back inside; near enough
  /// that the row still reads as the recent past rather than as another year.
  static const int _lockedDaysPastWindow = 5;
  static const int _lockedSpreadDays = 30;

  /// Adds then deletes fixtures so tombstones exist without reducing visible counts.
  static const int _tombstoneAttacks = 1;
  static const int _tombstoneMedications = 1;

  /// What is actually written, surplus included — the lists keep the counts above once [_seedTombstones] has taken the rest.
  static const int _attacksToWrite = attackCount + _tombstoneAttacks;
  static const int _medicationsToWrite =
      medicationCount + _tombstoneMedications;

  /// Days of check-ins, back from today. Four weeks is what the trigger map asks for before it will render, so the fixture clears that bar by a day.
  static const int dailyLogDays = 29;

  /// How far back rows are scattered, in hours.
  static const int _windowHours = 2200;

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

  /// Suffixes, so the pool is 30 names crossed with 5 doses rather than 30.
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

  /// Clears the database, then writes a fresh data set into it. Unseeded [Random] on purpose — see the class doc.
  Future<void> seed() async {
    final Random random = Random();
    final DateTime now = DateTime.now().toUtc();
    final List<Medication> medications = _buildMedications(random, now);
    final List<Attack> attacks = _buildAttacks(random, now, medications);
    // Kept apart from [attacks] for one reason: `_seedTombstones` deletes the
    // tail of the list it is handed, and a locked row deleted again is the
    // whole point of seeding it gone.
    final List<Attack> locked = _buildLockedAttacks(random, now, medications);
    final List<Attack> allAttacks = <Attack>[...attacks, ...locked];

    await _wipe.wipeAll();
    for (final Medication medication in medications) {
      await _medications.upsert(medication);
    }
    // After the medications exist: a reminder is a foreign key onto one.
    final List<MedicationReminder> reminders = await _seedReminders(
      random,
      medications,
    );

    for (final Attack attack in allAttacks) {
      await _attacks.insert(attack);
    }

    // The whole record, locked rows included: an export IS the whole record,
    // and the pressure readings have to reach the oldest attack so buying
    // premium reveals an attack with its weather rather than a gap.
    await _seedExports(random, allAttacks, medications, now);
    await _seedDailyPressure(random, allAttacks, now);
    await _seedDailyLogs(random, allAttacks, now);
    await _seedNotifications(random, reminders, now);
    // Last, and only over [attacks]: it deletes the tail of what it is handed.
    await _seedTombstones(attacks, medications);
  }

  /// One reading per local day across the window, attacks or no attacks.
  Future<void> _seedDailyPressure(
    Random random,
    List<Attack> attacks,
    DateTime now,
  ) async {
    final Set<DateTime> attackDays = <DateTime>{
      for (final Attack attack in attacks) _dayOf(attack.startedAt.toLocal()),
    };
    final int days = _dayReach(attacks, now);

    for (int back = 0; back < days; back++) {
      final DateTime day = _dayOf(now.toLocal().subtract(Duration(days: back)));
      // A drop on ~65% of attack days against ~25% of the rest — a signal that is strong enough to read and weak enough to stay believable.
      final bool drops =
          random.nextInt(100) < (attackDays.contains(day) ? 65 : 25);
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

  /// One check-in per day, worse sleep and more factors on the days an attack landed — the fixture has to carry a signal, or every analysis built on it reads as broken.
  Future<void> _seedDailyLogs(
    Random random,
    List<Attack> attacks,
    DateTime now,
  ) async {
    final Set<DateTime> attackDays = <DateTime>{
      for (final Attack attack in attacks) _dayOf(attack.startedAt.toLocal()),
    };

    for (int back = 0; back < dailyLogDays; back++) {
      final DateTime day = _dayOf(now.toLocal().subtract(Duration(days: back)));
      final bool hurt = attackDays.contains(day);
      final List<DailyFactor> factors = <DailyFactor>[
        for (final DailyFactor factor in DailyFactor.values)
          if (random.nextInt(100) < (hurt ? 40 : 15)) factor,
      ];

      await _dailyLogs.save(
        DailyLog(
          day: day,
          // Worse nights before the days that hurt: 1-3 against 3-5.
          sleepQuality: hurt ? 1 + random.nextInt(3) : 3 + random.nextInt(3),
          stressLevel: hurt ? 3 + random.nextInt(3) : 1 + random.nextInt(3),
          factors: factors,
        ),
      );
    }
  }

  /// Both kinds of notification, most read and some not, so the bell carries a count and the two tabs each have rows.
  Future<void> _seedNotifications(
    Random random,
    List<MedicationReminder> reminders,
    DateTime now,
  ) async {
    final List<AppNotification> rows = <AppNotification>[];

    // Reminder occurrences: past firings of reminders that actually exist.
    for (int i = 0; i < notificationCount && reminders.isNotEmpty; i++) {
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

    // Pressure alerts, rarer than reminders — the cron sends at most one a day per user, so a list with as many alerts as reminders would lie.
    for (int i = 0; i < pressureAlertCount; i++) {
      final DateTime at = now.subtract(
        Duration(hours: random.nextInt(_windowHours)),
      );

      rows.add(
        AppNotification(
          id: AppNotification.pressureAlertId('seed-${SdId.unique()}'),
          type: NotificationType.pressureAlert,
          occurredAt: at,
          readAt: _maybeRead(random, at),
          pressureDropHpa: 5 + random.nextDouble() * 10,
        ),
      );
    }

    await _notifications.addMissing(rows);
  }

  /// Read a little after it arrived, or not at all. Roughly a third stay unread so the bell has a count and the rows have their dot.
  DateTime? _maybeRead(Random random, DateTime occurredAt) =>
      random.nextInt(3) == 0
      ? null
      : occurredAt.add(Duration(minutes: 1 + random.nextInt(600)));

  /// Deletes the extra rows written for exactly this,.
  Future<void> _seedTombstones(
    List<Attack> attacks,
    List<Medication> medications,
  ) async {
    for (final Attack attack in attacks.reversed.take(_tombstoneAttacks)) {
      await _attacks.deleteById(attack.id);
    }
    // Cascades its one reminder away too, which is the case the pull path has to handle and the one nothing else in the seed produces.
    for (final Medication medication in medications.reversed.take(
      _tombstoneMedications,
    )) {
      await _medications.deleteById(medication.id);
    }
  }

  DateTime _dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// One reminder on each of the first [reminderCount] medications, and one more on each doomed one.
  Future<List<MedicationReminder>> _seedReminders(
    Random random,
    List<Medication> medications,
  ) async {
    final List<int> minutes = _distinctMinutes(
      random,
      reminderCount + _tombstoneMedications,
    ).toList();
    final List<Medication> hosts = <Medication>[
      ...medications.take(reminderCount),
      ...medications.reversed.take(_tombstoneMedications),
    ];
    final List<MedicationReminder> created = <MedicationReminder>[];

    for (int i = 0; i < hosts.length; i++) {
      final MedicationReminder reminder = MedicationReminder(
        id: SdId.unique(),
        medicationId: hosts[i].id,
        minuteOfDay: minutes[i],
        // One in five is off — exercises the disabled row style and the filter count.
        enabled: random.nextInt(5) != 0,
      );

      await _reminders.upsert(reminder);
      if (i < reminderCount) created.add(reminder);
    }

    return created;
  }

  /// [count] distinct times of day.
  Set<int> _distinctMinutes(Random random, int count) {
    final Set<int> minutes = <int>{};

    while (minutes.length < count) {
      minutes.add(random.nextInt(24 * 60));
    }

    return minutes;
  }

  /// Names are drawn without replacement: the 30 names crossed with the 5 doses give 150 combinations, shuffled, of which as many as the seed needs are kept.
  List<Medication> _buildMedications(Random random, DateTime now) {
    final List<String> names = <String>[
      for (final String dose in _doses)
        for (final String name in _medicationNames) '$name$dose',
    ]..shuffle(random);

    // Without this, raising the count past the pool silently under-seeds.
    assert(
      names.length >= _medicationsToWrite,
      '$_medicationsToWrite medications exceed the ${names.length} name/dose '
      'combinations available — add names or doses.',
    );

    return <Medication>[
      for (final String name in names.take(_medicationsToWrite))
        Medication(
          id: SdId.unique(),
          name: name,
          createdAt: now.subtract(
            Duration(hours: random.nextInt(_windowHours)),
          ),
        ),
    ];
  }

  /// Exactly one of them has no weather, and which one is random.
  List<Attack> _buildAttacks(
    Random random,
    DateTime now,
    List<Medication> medications,
  ) {
    final List<int> hours = _scatteredHours(random, _attacksToWrite);
    final int weatherless = random.nextInt(hours.length);

    return <Attack>[
      for (int i = 0; i < hours.length; i++)
        _buildAttack(
          random,
          now.subtract(Duration(hours: hours[i])),
          medications,
          offline: i == weatherless,
        ),
    ];
  }

  /// The locked half: [lockedAttackCount] attacks behind the free plan's
  /// window, on distinct days so two blurred rows never share one.
  ///
  /// None of them is the offline one — that shape belongs on a row a free user
  /// can actually read, and a blurred row says nothing about its weather.
  List<Attack> _buildLockedAttacks(
    Random random,
    DateTime now,
    List<Medication> medications,
  ) {
    final int windowDays = PremiumLimitConstant.freeHistoryWindow.inDays;
    final Set<int> daysBack = <int>{};

    while (daysBack.length < lockedAttackCount) {
      daysBack.add(
        windowDays + _lockedDaysPastWindow + random.nextInt(_lockedSpreadDays),
      );
    }

    return <Attack>[
      for (final int back in daysBack)
        _buildAttack(
          random,
          now.subtract(Duration(days: back, hours: random.nextInt(24))),
          medications,
          offline: false,
        ),
    ];
  }

  /// How many days of readings [_seedDailyPressure] writes: the scatter window,
  /// or back to the oldest attack when a locked row reaches further.
  int _dayReach(List<Attack> attacks, DateTime now) {
    final int scatter = (_windowHours / 24).ceil();
    final DateTime today = _dayOf(now.toLocal());
    int oldest = 0;

    for (final Attack attack in attacks) {
      oldest = max(
        oldest,
        today.difference(_dayOf(attack.startedAt.toLocal())).inDays,
      );
    }

    return max(scatter, oldest + 1);
  }

  /// [count] distinct hour offsets inside the window.
  List<int> _scatteredHours(Random random, int count) {
    final Set<int> hours = <int>{};

    while (hours.length < count) {
      hours.add(random.nextInt(_windowHours));
    }

    return hours.toList();
  }

  Attack _buildAttack(
    Random random,
    DateTime startedAt,
    List<Medication> medications, {
    required bool offline,
  }) {
    final int intensity = 1 + random.nextInt(10);
    final bool untreated = random.nextInt(5) == 0;
    final bool annotated = random.nextInt(4) == 0;

    return Attack(
      id: SdId.unique(),
      startedAt: startedAt,
      intensity: intensity,
      regions: _pickRegions(random),
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

  /// Exertion tracks intensity the way the seeded weather does, so the exertion engine sees a signal rather than noise.
  ExertionLevel? _buildExertion(Random random, int intensity) {
    if (random.nextInt(8) == 0) return null;

    final int roll = random.nextInt(10) + intensity;

    if (roll >= 14) return ExertionLevel.severe;
    if (roll >= 10) return ExertionLevel.moderate;
    if (roll >= 6) return ExertionLevel.light;

    return ExertionLevel.none;
  }

  /// Notes vary in length as well as content: a one-word note and a rambling one lay out differently everywhere they appear, and only seeding both shows it.
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

  /// Pressure sags as intensity climbs, so the correlation engine sees a real (if invented) signal instead of noise.
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

  /// Real files with real content, exactly like [ExportKind.json] and [ExportKind.csv] exports produced by hand.
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
    for (final int hoursAgo in _scatteredHours(random, exportCount)) {
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
          id: SdId.unique(),
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

  /// One to three areas, in enum order — the shape a real pick has.
  List<HeadRegion> _pickRegions(Random random) {
    final List<HeadRegion> shuffled = List<HeadRegion>.of(HeadRegion.values)
      ..shuffle(random);
    final Set<HeadRegion> picked = shuffled.take(1 + random.nextInt(3)).toSet();

    return <HeadRegion>[
      for (final HeadRegion region in HeadRegion.values)
        if (picked.contains(region)) region,
    ];
  }

  List<String> _pick(List<String> source, Random random) {
    final List<String> shuffled = List<String>.of(source)..shuffle(random);

    return shuffled.take(random.nextInt(3)).toList();
  }
}
