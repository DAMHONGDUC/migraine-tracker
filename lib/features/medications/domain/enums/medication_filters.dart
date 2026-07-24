import 'package:meta/meta.dart';

/// When the medication was added, bucketed the same calendar windows as
/// History's period filter (today / this week / this month / this year /
/// all). Kept as its own enum rather than reusing `HistoryPeriod` —
/// identical buckets, but coupling this feature to History's enum would be
/// a surprising cross-feature dependency for what is really its own filter
/// axis with its own null case (see [MedicationFilterer]).
enum MedicationDateFilter { today, week, month, year, all }

/// Whether the medication has any local reminder configured. Asks "did the
/// user set one up", not "is it currently firing" — a disabled reminder
/// still counts as [withReminder].
enum MedicationReminderFilter { all, withReminder, withoutReminder }

/// Whether the medication has ever been picked in a logged attack.
enum MedicationUsageFilter { all, everUsed, neverUsed }

/// The medications tab's three independent filter axes, combined with AND.
/// Each axis defaults to "no filter" so a freshly opened tab shows
/// everything.
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

  bool get isDefault =>
      date == MedicationDateFilter.all &&
      reminder == MedicationReminderFilter.all &&
      usage == MedicationUsageFilter.all;

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
