import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../domain/entities/medication_reminder.dart';
import '../../domain/repositories/medication_reminder_repository.dart';

class DriftMedicationReminderRepository
    implements MedicationReminderRepository {
  const DriftMedicationReminderRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<MedicationReminderView>> watchAll() {
    final query =
        _db.select(_db.medicationReminders).join([
            innerJoin(
              _db.medications,
              _db.medications.id.equalsExp(
                _db.medicationReminders.medicationId,
              ),
            ),
          ])
          ..orderBy([OrderingTerm.asc(_db.medicationReminders.minuteOfDay)]);

    return query.watch().map(
      (rows) => rows.map((row) {
        final r = row.readTable(_db.medicationReminders);
        return MedicationReminderView(
          reminder: _toDomain(r),
          medicationName: row.readTable(_db.medications).name,
        );
      }).toList(),
    );
  }

  @override
  Future<List<MedicationReminder>> getAllEnabled() async {
    final rows = await (_db.select(_db.medicationReminders)
          ..where((t) => t.enabled.equals(true)))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> upsert(MedicationReminder reminder) => _db
      .into(_db.medicationReminders)
      .insertOnConflictUpdate(
        MedicationRemindersCompanion.insert(
          id: reminder.id,
          medicationId: reminder.medicationId,
          minuteOfDay: reminder.minuteOfDay,
          enabled: Value(reminder.enabled),
        ),
      );

  @override
  Future<void> deleteById(String id) => (_db.delete(
    _db.medicationReminders,
  )..where((t) => t.id.equals(id))).go();

  @override
  Future<void> deleteAll() => _db.delete(_db.medicationReminders).go();

  MedicationReminder _toDomain(MedicationReminderRow row) => MedicationReminder(
    id: row.id,
    medicationId: row.medicationId,
    minuteOfDay: row.minuteOfDay,
    enabled: row.enabled,
  );
}
