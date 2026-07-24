import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/medication.dart';
import '../../providers.dart';

/// Orchestrates the medications tab's CRUD actions. Adding/picking a
/// medication mid-attack (the log flow) stays in `MedicationStep` — this is
/// for the management tab.
class MedicationsController {
  const MedicationsController(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  /// Adds a brand-new medication, stamping `createdAt` now.
  Future<void> add(String name) => _ref
      .read(medicationRepositoryProvider)
      .upsert(
        Medication(id: _uuid.v4(), name: name, createdAt: DateTime.now().toUtc()),
      );

  /// Renames [medication] without disturbing its `createdAt` — the caller
  /// already holds the existing entity, so its creation date just passes
  /// through untouched.
  Future<void> rename(Medication medication, String newName) => _ref
      .read(medicationRepositoryProvider)
      .upsert(
        Medication(
          id: medication.id,
          name: newName,
          createdAt: medication.createdAt,
        ),
      );

  /// Deletes the medication. Its reminders cascade at the DB level, but that
  /// cascade doesn't reach the OS — every enabled reminder's scheduled
  /// notification is cancelled first, or it would keep firing for a
  /// medication that no longer exists.
  Future<void> delete(String medicationId) async {
    final enabledReminders = await _ref
        .read(medicationReminderRepositoryProvider)
        .getAllEnabled();
    final scheduler = _ref.read(notificationSchedulerProvider);
    for (final reminder in enabledReminders) {
      if (reminder.medicationId == medicationId) {
        await scheduler.cancel(reminder.id);
      }
    }
    await _ref.read(medicationRepositoryProvider).deleteById(medicationId);
  }
}
