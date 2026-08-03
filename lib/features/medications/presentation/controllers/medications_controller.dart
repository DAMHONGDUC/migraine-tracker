import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/logging/app_logger.dart';
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
  ///
  /// Everything after [name] comes from the details form — quick add passes
  /// none of it, and null stays null rather than becoming an empty string.
  Future<void> add(
    String name, {
    String? description,
    String? ingredients,
    String? strength,
    String? dosage,
    String? instructions,
  }) async {
    AppLogger.action('Add medication', name);
    // No medication name: what someone takes is health data.
    AppAnalytics.logMedicationAdded();
    try {
      await _ref
          .read(medicationRepositoryProvider)
          .upsert(
            Medication(
              id: _uuid.v4(),
              name: name,
              createdAt: DateTime.now().toUtc(),
              description: description,
              ingredients: ingredients,
              strength: strength,
              dosage: dosage,
              instructions: instructions,
            ),
          );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Add medication failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Renames [medication] without disturbing its `createdAt` — the caller
  /// already holds the existing entity, so its creation date just passes
  /// through untouched.
  Future<void> rename(Medication medication, String newName) async {
    AppLogger.action('Rename medication', '${medication.name} → $newName');
    AppAnalytics.logMedicationRenamed();
    try {
      await _ref
          .read(medicationRepositoryProvider)
          .upsert(
            Medication(
              id: medication.id,
              name: newName,
              createdAt: medication.createdAt,
            ),
          );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Rename medication failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Deletes the medication. Its reminders cascade at the DB level, but that
  /// cascade doesn't reach the OS — every enabled reminder's scheduled
  /// notification is cancelled first, or it would keep firing for a
  /// medication that no longer exists.
  Future<void> delete(String medicationId) async {
    try {
      final enabledReminders = await _ref
          .read(medicationReminderRepositoryProvider)
          .getAllEnabled();
      final scheduler = _ref.read(notificationSchedulerProvider);

      AppLogger.action('Delete medication', medicationId);
      AppAnalytics.logMedicationDeleted();
      for (final reminder in enabledReminders) {
        if (reminder.medicationId == medicationId) {
          await scheduler.cancel(reminder.id);
        }
      }
      await _ref.read(medicationRepositoryProvider).deleteById(medicationId);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Delete medication failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
