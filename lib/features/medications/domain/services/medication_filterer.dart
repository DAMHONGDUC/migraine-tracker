import '../entities/medication.dart';
import '../enums/medication_filters.dart';

/// Filters and sorts the medications tab's list. Pure Dart — no Flutter,
/// no repository access; the provider layer resolves [reminderMedicationIds]
/// and [everUsedNames] and hands them in.
///
/// Entirely separate from `medicationsByRecentUseProvider` (the log flow's
/// own ordering): that grid must stay predictable mid-attack regardless of
/// whatever the user last filtered this tab to, so the two never share
/// state. See `MedicationStep`'s doc comment.
class MedicationFilterer {
  const MedicationFilterer();

  /// Inclusive lower bound (local time) of [filter] relative to [now], or
  /// null for [MedicationDateFilter.all]. Mirrors
  /// `AttackPeriodFilterer.periodStart` — same calendar-window math, kept
  /// separate per the enum doc.
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

  /// Applies [filters] (AND across axes) and sorts most-recently-added
  /// first. Medications with no recorded creation date (pre-v3 rows) sort
  /// last — not "oldest", just unrecorded — and never match a specific date
  /// window, only [MedicationDateFilter.all].
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
