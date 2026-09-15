import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/constants/premium_limit_constant.dart';
import '../../core/db/database_provider.dart';
import '../attacks/domain/entities/attack.dart';
import '../attacks/providers.dart';
import '../premium/providers.dart';
import 'data/repositories/drift_medication_reminder_repository.dart';
import 'data/repositories/drift_medication_repository.dart';
import 'domain/entities/medication.dart';
import 'domain/enums/medication_filters.dart';
import 'domain/repositories/medication_reminder_repository.dart';
import 'domain/repositories/medication_repository.dart';
import 'domain/services/default_medication_seeder.dart';
import 'domain/services/medication_filterer.dart';
import 'domain/services/medication_ranking.dart';
import 'presentation/controllers/medication_filters_controller.dart';
import 'presentation/controllers/medications_controller.dart';
import 'presentation/controllers/reminders_controller.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>(
  (ref) => DriftMedicationRepository(ref.watch(databaseProvider)),
);

/// Seeds a brand-new account's first medication (see [DefaultMedicationSeeder]). Read from the app root's sign-in listener, never watched.
final defaultMedicationSeederProvider = Provider<DefaultMedicationSeeder>(
  (ref) => DefaultMedicationSeeder(ref.watch(medicationRepositoryProvider)),
);

final medicationsStreamProvider = StreamProvider<List<Medication>>(
  (ref) => ref.watch(medicationRepositoryProvider).watchAll(),
);

/// The medication list as the log flow's picker wants it: most recently taken first, never-taken ones alphabetically after.
final medicationsByRecentUseProvider = Provider<List<Medication>>((ref) {
  final medications =
      ref.watch(medicationsStreamProvider).value ?? const <Medication>[];
  final attacks = ref.watch(attacksStreamProvider).value ?? const <Attack>[];
  return MedicationRanking.byRecentUse(
    medications,
    attacks.map((attack) => attack.medicationName),
  );
});

/// The medications tab's filter state (date added / reminder / usage). See [MedicationFiltersController].
final medicationFiltersProvider =
    NotifierProvider<MedicationFiltersController, MedicationFilters>(
      MedicationFiltersController.new,
    );

/// Orchestrates the medications tab's add/rename/delete. See [MedicationsController].
final medicationsControllerProvider = Provider<MedicationsController>(
  MedicationsController.new,
);

/// One-shot request to open the "add medication" dialog, set by the dashboard shortcut and consumed by the medications tab once it becomes active (it.
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

/// Free-text search over medication names, driven by the search field in the medications tab app bar.
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

/// One medication by id, for [MedicationDetailScreen]. Null once it is deleted — the screen pops itself rather than showing a stale name.
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

/// Medication ids with at least one reminder configured (any enabled state) — feeds [MedicationReminderFilter].
final _medicationIdsWithRemindersProvider = Provider<Set<String>>((ref) {
  final reminders =
      ref.watch(medicationRemindersStreamProvider).value ??
      const <MedicationReminderView>[];
  return {for (final view in reminders) view.reminder.medicationId};
});

/// Medication names that appear at least once in logged attack history — feeds [MedicationUsageFilter].
final _everUsedMedicationNamesProvider = Provider<Set<String>>((ref) {
  final attacks = ref.watch(attacksStreamProvider).value ?? const <Attack>[];
  return {
    for (final attack in attacks)
      if (attack.medicationName != null) attack.medicationName!,
  };
});

/// The medications tab's list: [medicationsStreamProvider] filtered by [medicationFiltersProvider] and sorted most-recently-added first.
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
  // Free-text search narrows further, on top of the enum filters, so the filterer stays a pure enum-axis engine.
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

/// One medication's reminders: the detail screen's list, and the count the medications tab shows on its card.
final remindersForMedicationProvider =
    Provider.family<List<MedicationReminderView>, String>((ref, medicationId) {
      final all =
          ref.watch(medicationRemindersStreamProvider).value ??
          const <MedicationReminderView>[];
      return all
          .where((view) => view.reminder.medicationId == medicationId)
          .toList();
    });

/// Whether another medication may be added.
final canAddMedicationProvider = Provider<bool>((ref) {
  if (ref.watch(hasPremiumProvider)) return true;

  final List<Medication> medications =
      ref.watch(medicationsStreamProvider).value ?? const <Medication>[];

  return medications.length < PremiumLimitConstant.medications;
});

/// How many of the free plan's medications are spent, for [FreeLimitProgress].
final medicationsUsedProvider = Provider<int?>((ref) {
  if (ref.watch(hasPremiumProvider)) return null;

  return (ref.watch(medicationsStreamProvider).value ?? const <Medication>[])
      .length;
});

/// Whether another reminder may be created.
final canAddReminderProvider = Provider<bool>((ref) {
  if (ref.watch(hasPremiumProvider)) return true;

  final List<MedicationReminderView> all =
      ref.watch(medicationRemindersStreamProvider).value ??
      const <MedicationReminderView>[];

  return all.length < PremiumLimitConstant.reminders;
});

/// How many of the free plan's reminders are spent, for [FreeLimitProgress].
final remindersUsedProvider = Provider<int?>((ref) {
  if (ref.watch(hasPremiumProvider)) return null;

  return (ref.watch(medicationRemindersStreamProvider).value ??
          const <MedicationReminderView>[])
      .length;
});

/// Orchestrates reminders (see [RemindersController]).
final remindersControllerProvider = Provider<RemindersController>(
  RemindersController.new,
);
