import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/enums/medication_filters.dart';

/// The medications tab's three filter axes (date added, reminder, usage).
/// Mirrors `HistoryController`'s role for `HistoryPeriod`.
class MedicationFiltersController extends Notifier<MedicationFilters> {
  @override
  MedicationFilters build() => const MedicationFilters();

  void setDate(MedicationDateFilter value) =>
      state = state.copyWith(date: value);

  void setReminder(MedicationReminderFilter value) =>
      state = state.copyWith(reminder: value);

  void setUsage(MedicationUsageFilter value) =>
      state = state.copyWith(usage: value);
}
