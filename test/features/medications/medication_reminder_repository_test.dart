import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_reminder_repository.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication_reminder.dart';

void main() {
  late AppDatabase db;
  late DriftMedicationReminderRepository reminders;
  late DriftMedicationRepository medications;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    reminders = DriftMedicationReminderRepository(db);
    medications = DriftMedicationRepository(db);
    await medications.upsert(const Medication(id: 'm1', name: 'Sumatriptan'));
  });

  tearDown(() => db.close());

  MedicationReminder reminder(String id, int minute, {bool enabled = true}) =>
      MedicationReminder(
        id: id,
        medicationId: 'm1',
        minuteOfDay: minute,
        enabled: enabled,
      );

  test(
    'upsert + watchAll joins the medication name, ordered by time',
    () async {
      await reminders.upsert(reminder('r1', 9 * 60)); // 09:00
      await reminders.upsert(reminder('r2', 8 * 60)); // 08:00

      final list = await reminders.watchAll().first;
      expect(list.map((v) => v.reminder.id), ['r2', 'r1']); // earliest first
      expect(list.first.medicationName, 'Sumatriptan');
      expect(list.first.reminder.hour, 8);
    },
  );

  test('getAllEnabled excludes disabled reminders', () async {
    await reminders.upsert(reminder('r1', 540));
    await reminders.upsert(reminder('r2', 600, enabled: false));

    final enabled = await reminders.getAllEnabled();
    expect(enabled.map((r) => r.id), ['r1']);
  });

  test('deleting a medication cascades to its reminders', () async {
    await reminders.upsert(reminder('r1', 540));
    await medications.deleteById('m1');

    expect(await reminders.watchAll().first, isEmpty);
  });

  test('deleteById removes a single reminder', () async {
    await reminders.upsert(reminder('r1', 540));
    await reminders.upsert(reminder('r2', 600));
    await reminders.deleteById('r1');

    final list = await reminders.watchAll().first;
    expect(list.map((v) => v.reminder.id), ['r2']);
  });
}
