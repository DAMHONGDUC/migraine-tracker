import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/daily_log/data/repositories/drift_daily_log_repository.dart';
import 'package:migraine_tracker/features/insights/data/repositories/drift_midas_repository.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_reminder_repository.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication_reminder.dart';
import 'package:migraine_tracker/features/medications/domain/repositories/medication_reminder_repository.dart';
import 'package:migraine_tracker/features/notifications/data/repositories/drift_notification_repository.dart';
import 'package:migraine_tracker/features/notifications/domain/entities/app_notification.dart';
import 'package:migraine_tracker/features/notifications/domain/enums/notification_type.dart';
import 'package:migraine_tracker/features/notifications/domain/services/notification_scheduler.dart';
import 'package:migraine_tracker/features/settings/data/repositories/drift_export_record_repository.dart';
import 'package:migraine_tracker/features/settings/domain/entities/export_record.dart';
import 'package:migraine_tracker/features/settings/domain/services/data_export_service.dart';
import 'package:migraine_tracker/features/settings/domain/services/data_wipe_service.dart';
import 'package:migraine_tracker/features/settings/domain/services/dev_seed_service.dart';
import 'package:migraine_tracker/features/weather/data/repositories/drift_daily_pressure_repository.dart';
import 'package:migraine_tracker/features/weather/domain/entities/daily_pressure.dart';

import '../../helpers/alert_fakes.dart';
import '../../helpers/attack_fakes.dart';
import '../../helpers/export_fakes.dart';
import '../../helpers/home_widget_fakes.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/sync_fakes.dart';

class _SilentScheduler implements NotificationScheduler {
  @override
  Future<void> scheduleCheckIn({
    required DateTime when,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancelCheckIn() async {}

  @override
  Stream<String> get reminderTaps => const Stream<String>.empty();

  @override
  Future<String?> takeLaunchReminderId() async => null;

  @override
  Future<bool> ensurePermission() async => true;

  @override
  Future<void> schedule(
    MedicationReminder reminder, {
    required String medicationName,
    required String title,
    required String bodyTemplate,
  }) async {}

  @override
  Future<void> cancel(String reminderId) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> scheduleTest({
    required String title,
    required String body,
    Duration delay = Duration.zero,
  }) async {}
}

/// The dev fixture is the only data most screens are ever developed against, so what it guarantees matters.
void main() {
  late AppDatabase db;
  late FakeExportFileStore files;
  late DevSeedService seeder;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    files = FakeExportFileStore();
    seeder = DevSeedService(
      DataWipeService(
        DriftAttackRepository(db),
        DriftMedicationRepository(db),
        _SilentScheduler(),
        DriftNotificationRepository(db),
        DriftExportRecordRepository(db),
        files,
        FakeAuthRepository(),
        syncServiceOver(db),
        RecordingAlertRegistration(),
        DriftDailyPressureRepository(db),
        DriftDailyLogRepository(db),
        DriftMidasRepository(db),
        RecordingShareFileStore(),
        RecordingHomeWidgetRepository(),
        RecordingLiveActivity(),
      ),
      DriftAttackRepository(db),
      DriftMedicationRepository(db),
      DriftMedicationReminderRepository(db),
      const DataExportService(),
      files,
      DriftExportRecordRepository(db),
      DriftNotificationRepository(db),
      DriftDailyPressureRepository(db),
      DriftDailyLogRepository(db),
    );
  });

  tearDown(() => db.close());

  Future<List<Attack>> attacks() => DriftAttackRepository(db).watchAll().first;
  Future<List<Medication>> medications() =>
      DriftMedicationRepository(db).watchAll().first;
  Future<List<ExportRecord>> exports() =>
      DriftExportRecordRepository(db).watchAll().first;
  Future<List<MedicationReminderView>> reminders() =>
      DriftMedicationReminderRepository(db).watchAll().first;
  Future<List<AppNotification>> notifications() =>
      DriftNotificationRepository(db).watchAll().first;

  test('seeds exactly the promised number of rows of each kind', () async {
    await seeder.seed();

    // Exact, tombstones included: the surplus rows the seed deletes again are written ON TOP of these counts, so a list is never left a row short.
    expect((await attacks()).length, DevSeedService.attackCount);
    expect((await medications()).length, DevSeedService.medicationCount);
    expect((await reminders()).length, DevSeedService.reminderCount);
    expect((await exports()).length, DevSeedService.exportCount);
  });

  test('medication names are drawn without replacement', () async {
    await seeder.seed();

    final List<String> names = <String>[
      for (final Medication m in await medications()) m.name,
    ];

    expect(names.toSet().length, names.length);
  });

  test('one reminder each, and medications left with none', () async {
    await seeder.seed();

    final Map<String, int> perMedication = <String, int>{};

    for (final MedicationReminderView view in await reminders()) {
      perMedication.update(
        view.reminder.medicationId,
        (int count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    expect(perMedication.values, everyElement(1));
    // The rest have nothing, which is the empty state and the filter count.
    expect(
      perMedication.length,
      lessThan(DevSeedService.medicationCount),
      reason: 'every medication got a reminder, so the empty case is unseeded',
    );
  });

  test('no two reminders on one medication share a time', () async {
    await seeder.seed();

    final Map<String, Set<int>> minutes = <String, Set<int>>{};
    int total = 0;

    for (final MedicationReminderView view in await reminders()) {
      total++;
      minutes
          .putIfAbsent(view.reminder.medicationId, () => <int>{})
          .add(view.reminder.minuteOfDay);
    }

    expect(
      minutes.values.fold<int>(0, (int sum, Set<int> set) => sum + set.length),
      total,
    );
  });

  test('re-seeding does not pile reminders onto the old medications', () async {
    await seeder.seed();
    final int first = (await reminders()).length;

    await seeder.seed();

    // The wipe cascades the old reminders away; only the new run's survive.
    expect((await reminders()).length, lessThan(first * 2));
    final Set<String> medicationIds = <String>{
      for (final Medication m in await medications()) m.id,
    };
    for (final MedicationReminderView view in await reminders()) {
      expect(medicationIds, contains(view.reminder.medicationId));
    }
  });

  test('no two attacks land in the same hour', () async {
    await seeder.seed();

    final List<DateTime> starts = <DateTime>[
      for (final Attack a in await attacks()) a.startedAt,
    ];

    expect(starts.toSet().length, starts.length);
  });

  test('re-seeding replaces the data rather than adding to it', () async {
    await seeder.seed();
    final int afterFirst = (await attacks()).length;

    await seeder.seed();

    // Equal, not doubled.
    expect((await attacks()).length, afterFirst);
    expect(afterFirst, DevSeedService.attackCount);
  });

  test('two runs produce different data', () async {
    await seeder.seed();
    final Set<String> firstNames = <String>{
      for (final Medication m in await medications()) m.name,
    };
    final List<int> firstIntensities = <int>[
      for (final Attack a in await attacks()) a.intensity,
    ];

    await seeder.seed();
    final Set<String> secondNames = <String>{
      for (final Medication m in await medications()) m.name,
    };
    final List<int> secondIntensities = <int>[
      for (final Attack a in await attacks()) a.intensity,
    ];

    // Both draw from the same 150 names — what must differ is which ones, and the attacks built on top of them.
    expect(
      firstNames.difference(secondNames),
      isNotEmpty,
      reason: 'the medication draw repeated itself between runs',
    );
    expect(
      firstIntensities,
      isNot(equals(secondIntensities)),
      reason: 'the attack data repeated itself between runs',
    );
  });

  test('one attack is left weatherless, for the backfill queue', () async {
    await seeder.seed();

    final List<Attack> all = await attacks();

    // At most one, and at least one: a chance per attack would seed the offline-log case in some runs and not others at this size.
    expect(all.where((Attack a) => a.weather == null).length, lessThan(2));
  });

  test('fills the tables the charts and the list read, not just attacks', () async {
    await seeder.seed();

    // One reading per day across the window: the correlation's denominator, without which the pressure card can only talk about attacks.
    final List<DailyPressure> days = await DriftDailyPressureRepository(
      db,
    ).since(DateTime(2000));

    expect(days, isNotEmpty);
    expect(
      days.map((DailyPressure d) => d.day).toSet().length,
      days.length,
      reason: 'one row per day, never two',
    );

    final List<AppNotification> rows = await notifications();

    expect(rows, isNotEmpty);
    // Both tabs of the list have something, and the bell has a count.
    expect(
      rows.any(
        (AppNotification n) => n.type == NotificationType.medicationReminder,
      ),
      isTrue,
    );
    expect(
      rows.any((AppNotification n) => n.type == NotificationType.pressureAlert),
      isTrue,
    );
    // No read/unread assertion: whether a row was read is a roll per row, and over this few rows the test would be checking the RNG.
  });

  test('a pressure alert row carries how far it fell', () async {
    await seeder.seed();

    final Iterable<AppNotification> alerts = (await notifications()).where(
      (AppNotification n) => n.type == NotificationType.pressureAlert,
    );

    // Without it a reconciled row cannot say what the alert was about.
    expect(
      alerts.every((AppNotification n) => n.pressureDropHpa != null),
      isTrue,
    );
  });
}
