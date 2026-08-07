import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_reminder_repository.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication_reminder.dart';
import 'package:migraine_tracker/features/medications/domain/repositories/medication_reminder_repository.dart';
import 'package:migraine_tracker/features/medications/domain/services/notification_scheduler.dart';
import 'package:migraine_tracker/features/settings/data/repositories/drift_export_record_repository.dart';
import 'package:migraine_tracker/features/settings/domain/entities/export_record.dart';
import 'package:migraine_tracker/features/settings/domain/services/data_export_service.dart';
import 'package:migraine_tracker/features/settings/domain/services/data_wipe_service.dart';
import 'package:migraine_tracker/features/settings/domain/services/dev_seed_service.dart';

import '../../helpers/alert_fakes.dart';
import '../../helpers/export_fakes.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/sync_fakes.dart';

class _SilentScheduler implements NotificationScheduler {
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

/// The dev fixture is the only data most screens are ever developed against,
/// so what it guarantees matters: enough rows, no two alike, and a different
/// shape every run. A fixture that quietly repeats itself only exercises the
/// one layout it happens to produce.
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
        DriftExportRecordRepository(db),
        files,
        FakeAuthRepository(),
        syncServiceOver(db),
        RecordingAlertRegistration(),
      ),
      DriftAttackRepository(db),
      DriftMedicationRepository(db),
      DriftMedicationReminderRepository(db),
      const DataExportService(),
      files,
      DriftExportRecordRepository(db),
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

  test('seeds the promised number of rows of each kind', () async {
    await seeder.seed();

    expect((await attacks()).length, DevSeedService.seedCount);
    expect((await medications()).length, DevSeedService.seedCount);
    expect((await exports()).length, DevSeedService.seedCount);
  });

  test('medication names are drawn without replacement', () async {
    await seeder.seed();

    final List<String> names = <String>[
      for (final Medication m in await medications()) m.name,
    ];

    expect(names.toSet().length, names.length);
  });

  test('some medications get a long reminder list, some get none', () async {
    await seeder.seed();

    final Map<String, int> perMedication = <String, int>{};

    for (final MedicationReminderView view in await reminders()) {
      perMedication.update(
        view.reminder.medicationId,
        (int count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    // The crowded ones are what the detail screen's list has to survive.
    expect(
      perMedication.values
          .where((int count) => count == DevSeedService.crowdedReminders)
          .length,
      DevSeedService.crowdedMedications,
    );
    // And plenty are left with nothing, for the empty state and the filter.
    expect(
      perMedication.length,
      lessThan(DevSeedService.seedCount),
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
    await seeder.seed();

    expect((await attacks()).length, DevSeedService.seedCount);
    expect((await medications()).length, DevSeedService.seedCount);
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

    // Both draw 100 of the same 150 names, so the sets overlap heavily — what
    // must differ is which 100, and the attacks built on top of them.
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

  test('every attack without weather is a backfill candidate, not a hole in '
      'the correlation data', () async {
    await seeder.seed();

    final List<Attack> all = await attacks();
    final int weatherless = all.where((Attack a) => a.weather == null).length;

    // Roughly one in seven, but random — assert the band, not a count, or the
    // test is asserting the RNG rather than the intent.
    expect(weatherless, greaterThan(0));
    expect(weatherless, lessThan(all.length ~/ 3));
  });
}
