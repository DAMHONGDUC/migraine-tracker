import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/enums/medication_filters.dart';

/// The medications tab's three filter axes (date added, reminder, usage).
/// Mirrors `HistoryController`'s role for `HistoryPeriod`.
class MedicationFiltersController extends Notifier<MedicationFilters> {
  @override
  MedicationFilters build() => const MedicationFilters();

  void setDate(MedicationDateFilter value) {
    SdLogger.action(
      LogTagConstant.medicationFilters,
      'Medication date filter',
      value.name,
    );
    state = state.copyWith(date: value);
  }

  void setReminder(MedicationReminderFilter value) {
    SdLogger.action(
      LogTagConstant.medicationFilters,
      'Medication reminder filter',
      value.name,
    );
    state = state.copyWith(reminder: value);
  }

  void setUsage(MedicationUsageFilter value) {
    SdLogger.action(
      LogTagConstant.medicationFilters,
      'Medication usage filter',
      value.name,
    );
    state = state.copyWith(usage: value);
  }
}
