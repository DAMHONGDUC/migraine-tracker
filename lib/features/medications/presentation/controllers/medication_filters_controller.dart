import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/enums/medication_filters.dart';

/// The medications tab's three filter axes (date added, reminder, usage).
/// Mirrors `HistoryController`'s role for `HistoryPeriod`.
class MedicationFiltersController extends Notifier<MedicationFilters> {
  @override
  MedicationFilters build() => const MedicationFilters();

  void setDate(MedicationDateFilter value) {
    AppLogger.action('Medication date filter', value.name);
    state = state.copyWith(date: value);
  }

  void setReminder(MedicationReminderFilter value) {
    AppLogger.action('Medication reminder filter', value.name);
    state = state.copyWith(reminder: value);
  }

  void setUsage(MedicationUsageFilter value) {
    AppLogger.action('Medication usage filter', value.name);
    state = state.copyWith(usage: value);
  }
}
