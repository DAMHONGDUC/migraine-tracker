import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/db/database_provider.dart';
import '../attacks/domain/entities/attack.dart';
import '../attacks/providers.dart';
import 'data/repositories/drift_medication_reminder_repository.dart';
import 'data/repositories/drift_medication_repository.dart';
import 'data/services/local_notification_scheduler.dart';
import 'domain/entities/medication.dart';
import 'domain/entities/next_reminder.dart';
import 'domain/enums/medication_filters.dart';
import 'domain/repositories/medication_reminder_repository.dart';
import 'domain/repositories/medication_repository.dart';
import 'domain/services/medication_filterer.dart';
import 'domain/services/medication_ranking.dart';
import 'domain/services/next_reminder_calculator.dart';
import 'domain/services/notification_scheduler.dart';
import 'presentation/controllers/medication_filters_controller.dart';
import 'presentation/controllers/medications_controller.dart';
import 'presentation/controllers/reminders_controller.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>(
  (ref) => DriftMedicationRepository(ref.watch(databaseProvider)),
);

final medicationsStreamProvider = StreamProvider<List<Medication>>(
  (ref) => ref.watch(medicationRepositoryProvider).watchAll(),
);

/// The medication list as the log flow's picker wants it: most recently
/// taken first, never-taken ones alphabetically after. Ordering follows real
/// use so the usual med sits under the thumb mid-attack — see
/// [rankByRecentUse]. Everywhere else (settings, reminders) keeps the plain
/// alphabetical [medicationsStreamProvider].
final medicationsByRecentUseProvider = Provider<List<Medication>>((ref) {
  final medications =
      ref.watch(medicationsStreamProvider).value ?? const <Medication>[];
  final attacks =
      ref.watch(attacksStreamProvider).value ?? const <Attack>[];
  return rankByRecentUse(
    medications,
    attacks.map((attack) => attack.medicationName),
  );
});

/// The medications tab's filter state (date added / reminder / usage). See
/// [MedicationFiltersController].
final medicationFiltersProvider =
    NotifierProvider<MedicationFiltersController, MedicationFilters>(
      MedicationFiltersController.new,
    );

/// Orchestrates the medications tab's add/rename/delete. See
/// [MedicationsController].
final medicationsControllerProvider = Provider<MedicationsController>(
  MedicationsController.new,
);

/// One-shot request to open the "add medication" dialog, set by the dashboard
/// shortcut and consumed by the medications tab once it becomes active (it
/// listens for this and, on first mount, checks it). Kept out of the widget
/// tree so the request survives the branch switch that follows it.
class MedicationAddRequestController extends Notifier<bool> {
  @override
  bool build() => false;

  void request() => state = true;

  void consume() => state = false;
}

final medicationAddRequestProvider =
    NotifierProvider<MedicationAddRequestController, bool>(
      MedicationAddRequestController.new,
    );

/// Medication ids with at least one reminder configured (any enabled
/// state) — feeds [MedicationReminderFilter].
final _medicationIdsWithRemindersProvider = Provider<Set<String>>((ref) {
  final reminders =
      ref.watch(medicationRemindersStreamProvider).value ??
      const <MedicationReminderView>[];
  return {for (final view in reminders) view.reminder.medicationId};
});

/// Medication names that appear at least once in logged attack history —
/// feeds [MedicationUsageFilter]. Matched by name, same join key as
/// [rankByRecentUse]: attacks keep an immutable name snapshot, not a
/// foreign key to [Medication.id].
final _everUsedMedicationNamesProvider = Provider<Set<String>>((ref) {
  final attacks = ref.watch(attacksStreamProvider).value ?? const <Attack>[];
  return {
    for (final attack in attacks)
      if (attack.medicationName != null) attack.medicationName!,
  };
});

/// The medications tab's list: [medicationsStreamProvider] filtered by
/// [medicationFiltersProvider] and sorted most-recently-added first. See
/// [MedicationFilterer] — independent from [medicationsByRecentUseProvider],
/// the log flow's own ordering.
final filteredMedicationsProvider = Provider<List<Medication>>((ref) {
  final medications =
      ref.watch(medicationsStreamProvider).value ?? const <Medication>[];
  final filters = ref.watch(medicationFiltersProvider);
  return const MedicationFilterer().apply(
    medications,
    filters,
    now: DateTime.now(),
    reminderMedicationIds: ref.watch(_medicationIdsWithRemindersProvider),
    everUsedNames: ref.watch(_everUsedMedicationNamesProvider),
  );
});

final medicationReminderRepositoryProvider =
    Provider<MedicationReminderRepository>(
      (ref) => DriftMedicationReminderRepository(ref.watch(databaseProvider)),
    );

final medicationRemindersStreamProvider =
    StreamProvider<List<MedicationReminderView>>(
      (ref) => ref.watch(medicationReminderRepositoryProvider).watchAll(),
    );

/// One medication's reminders, for the medications tab's nested reminder
/// list per card.
final remindersForMedicationProvider =
    Provider.family<List<MedicationReminderView>, String>((ref, medicationId) {
      final all =
          ref.watch(medicationRemindersStreamProvider).value ??
          const <MedicationReminderView>[];
      return all
          .where((view) => view.reminder.medicationId == medicationId)
          .toList();
    });

/// The flutter_local_notifications plugin, initialized once (timezone setup
/// happens in main()). Override in tests with a fake NotificationScheduler.
final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  final plugin = FlutterLocalNotificationsPlugin();
  plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
      ),
    ),
  );
  return LocalNotificationScheduler(plugin);
});

/// Orchestrates reminders (see [RemindersController]).
final remindersControllerProvider = Provider<RemindersController>(
  RemindersController.new,
);

/// The soonest upcoming enabled reminder relative to now, for the dashboard's
/// next-reminder banner; null when nothing is scheduled. Recomputes when the
/// reminders change. The dashboard uses this to decide whether to show the
/// banner; the banner itself re-ticks the live countdown on a widget-owned
/// timer (a stream-driven clock here would invalidate this during layout and
/// crash — see NextReminderBanner).
final nextReminderProvider = Provider<NextReminder?>((ref) {
  final views =
      ref.watch(medicationRemindersStreamProvider).value ??
      const <MedicationReminderView>[];
  return const NextReminderCalculator().compute(views, now: DateTime.now());
});
