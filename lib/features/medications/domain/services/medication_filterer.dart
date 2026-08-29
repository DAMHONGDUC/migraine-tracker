import '../entities/medication.dart';
import '../enums/medication_filters.dart';

/// Filters and sorts the medications tab's list.
class MedicationFilterer {
  const MedicationFilterer();

  /// Inclusive lower bound (local time) of [filter] relative to [now], or null for [MedicationDateFilter.all].
  DateTime? _dateFilterStart(MedicationDateFilter filter, DateTime now) {
    final local = now.toLocal();
    final midnight = DateTime(local.year, local.month, local.day);

    return switch (filter) {
      MedicationDateFilter.today => midnight,
      MedicationDateFilter.week => midnight.subtract(
        Duration(days: midnight.weekday - 1),
      ),
      MedicationDateFilter.month => DateTime(local.year, local.month),
      MedicationDateFilter.year => DateTime(local.year),
      MedicationDateFilter.all => null,
    };
  }

  /// Applies [filters] (AND across axes) and sorts most-recently-added first.
  List<Medication> apply(
    List<Medication> medications,
    MedicationFilters filters, {
    required DateTime now,
    required Set<String> reminderMedicationIds,
    required Set<String> everUsedNames,
  }) {
    final start = _dateFilterStart(filters.date, now);
    final filtered = medications.where((m) {
      if (start != null) {
        if (m.createdAt == null) return false;
        if (m.createdAt!.toLocal().isBefore(start)) return false;
      }

      final hasReminder = reminderMedicationIds.contains(m.id);
      if (filters.reminder == MedicationReminderFilter.withReminder &&
          !hasReminder) {
        return false;
      }
      if (filters.reminder == MedicationReminderFilter.withoutReminder &&
          hasReminder) {
        return false;
      }

      final everUsed = everUsedNames.contains(m.name);
      if (filters.usage == MedicationUsageFilter.everUsed && !everUsed) {
        return false;
      }
      if (filters.usage == MedicationUsageFilter.neverUsed && everUsed) {
        return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      final ac = a.createdAt;
      final bc = b.createdAt;
      if (ac == null && bc == null) return 0;
      if (ac == null) return 1;
      if (bc == null) return -1;
      return bc.compareTo(ac);
    });
    return filtered;
  }
}
