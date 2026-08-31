import 'package:meta/meta.dart';

/// When the medication was added, bucketed the same calendar windows as History's period filter (today / this week / this month / this year / all).
enum MedicationDateFilter { today, week, month, year, all }

/// Whether the medication has any local reminder configured.
enum MedicationReminderFilter { all, withReminder, withoutReminder }

/// Whether the medication has ever been picked in a logged attack.
enum MedicationUsageFilter { all, everUsed, neverUsed }

/// The medications tab's three independent filter axes, combined with AND. Each axis defaults to "no filter" so a freshly opened tab shows everything.
@immutable
class MedicationFilters {
  const MedicationFilters({
    this.date = MedicationDateFilter.all,
    this.reminder = MedicationReminderFilter.all,
    this.usage = MedicationUsageFilter.all,
  });

  final MedicationDateFilter date;
  final MedicationReminderFilter reminder;
  final MedicationUsageFilter usage;

  /// How many axes are narrowing the list — what the summary line above it counts. Same getter, same wording, as `AttackFilters` on History.
  int get activeCount => <bool>[
    date != MedicationDateFilter.all,
    reminder != MedicationReminderFilter.all,
    usage != MedicationUsageFilter.all,
  ].where((bool on) => on).length;

  bool get isDefault => activeCount == 0;

  MedicationFilters copyWith({
    MedicationDateFilter? date,
    MedicationReminderFilter? reminder,
    MedicationUsageFilter? usage,
  }) => MedicationFilters(
    date: date ?? this.date,
    reminder: reminder ?? this.reminder,
    usage: usage ?? this.usage,
  );

  @override
  bool operator ==(Object other) =>
      other is MedicationFilters &&
      other.date == date &&
      other.reminder == reminder &&
      other.usage == usage;

  @override
  int get hashCode => Object.hash(date, reminder, usage);
}
