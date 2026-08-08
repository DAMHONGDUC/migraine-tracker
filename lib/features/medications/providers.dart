import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/db/database_provider.dart';
import '../attacks/domain/entities/attack.dart';
import '../attacks/providers.dart';
import '../premium/providers.dart';
import 'data/repositories/drift_medication_reminder_repository.dart';
import 'data/repositories/drift_medication_repository.dart';
import 'data/services/local_notification_scheduler.dart';
import 'domain/entities/medication.dart';
import 'domain/entities/medication_reminder.dart';
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
import 'presentation/controllers/reminder_sound_controller.dart';
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
/// [MedicationRanking.byRecentUse]. Everywhere else (settings, reminders) keeps the plain
/// alphabetical [medicationsStreamProvider].
final medicationsByRecentUseProvider = Provider<List<Medication>>((ref) {
  final medications =
      ref.watch(medicationsStreamProvider).value ?? const <Medication>[];
  final attacks = ref.watch(attacksStreamProvider).value ?? const <Attack>[];
  return MedicationRanking.byRecentUse(
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

/// Free-text search over medication names, driven by the search field in the
/// medications tab app bar. Narrows [filteredMedicationsProvider] on top of the
/// three filter axes. Empty string = not searching.
class MedicationSearchController extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;

  void clear() => state = '';
}

final medicationSearchProvider =
    NotifierProvider<MedicationSearchController, String>(
      MedicationSearchController.new,
    );

/// One medication by id, for [MedicationDetailScreen]. Null once it is
/// deleted — the screen pops itself rather than showing a stale name.
final medicationByIdProvider = Provider.family<Medication?, String>((
  ref,
  medicationId,
) {
  final List<Medication> medications =
      ref.watch(medicationsStreamProvider).value ?? const <Medication>[];

  for (final Medication medication in medications) {
    if (medication.id == medicationId) return medication;
  }
  return null;
});

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
/// [MedicationRanking.byRecentUse]: attacks keep an immutable name snapshot, not a
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
  final filtered = const MedicationFilterer().apply(
    medications,
    filters,
    now: DateTime.now(),
    reminderMedicationIds: ref.watch(_medicationIdsWithRemindersProvider),
    everUsedNames: ref.watch(_everUsedMedicationNamesProvider),
  );
  // Free-text search narrows further, on top of the enum filters, so the
  // filterer stays a pure enum-axis engine.
  final query = ref.watch(medicationSearchProvider).trim().toLowerCase();
  if (query.isEmpty) return filtered;
  return filtered
      .where((medication) => medication.name.toLowerCase().contains(query))
      .toList();
});

final medicationReminderRepositoryProvider =
    Provider<MedicationReminderRepository>(
      (ref) => DriftMedicationReminderRepository(ref.watch(databaseProvider)),
    );

final medicationRemindersStreamProvider =
    StreamProvider<List<MedicationReminderView>>(
      (ref) => ref.watch(medicationReminderRepositoryProvider).watchAll(),
    );

/// One medication's reminders: the detail screen's list, and the count the
/// medications tab shows on its card.
final remindersForMedicationProvider =
    Provider.family<List<MedicationReminderView>, String>((ref, medicationId) {
      final all =
          ref.watch(medicationRemindersStreamProvider).value ??
          const <MedicationReminderView>[];
      return all
          .where((view) => view.reminder.medicationId == medicationId)
          .toList();
    });

/// Whether another reminder may be created.
///
/// Free users get [MedicationReminder.freeLimit] across every medication,
/// not one each. **Only the add path asks.** A free user who already has
/// more — from before this limit existed, or pulled down by a sync from a
/// device that had premium — keeps every one of them: taking back a reminder
/// someone relies on to take medication is not a paywall, it is a regression.
final canAddReminderProvider = Provider<bool>((ref) {
  if (ref.watch(hasPremiumProvider)) return true;

  final List<MedicationReminderView> all =
      ref.watch(medicationRemindersStreamProvider).value ??
      const <MedicationReminderView>[];

  return all.length < MedicationReminder.freeLimit;
});

/// The flutter_local_notifications plugin, initialized once (timezone setup
/// happens in main()). Override in tests with a fake NotificationScheduler.
final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  final scheduler = LocalNotificationScheduler(
    FlutterLocalNotificationsPlugin(),
  );

  // Unawaited like the plugin call it replaced: nothing here waits on the
  // plugin being ready, and a scheduled reminder is queued behind it anyway.
  unawaited(scheduler.initialize());
  ref.onDispose(scheduler.dispose);

  return scheduler;
});

/// Whether reminders make a sound — the switch on the notification list
/// screen (see [ReminderSoundController]).
final reminderSoundProvider = NotifierProvider<ReminderSoundController, bool>(
  ReminderSoundController.new,
);

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
