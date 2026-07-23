import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:migraine_tracker/features/medications/domain/enums/medication_filters.dart';
import 'package:migraine_tracker/features/medications/domain/services/medication_filterer.dart';

Medication _med(String id, String name, DateTime? createdAt) =>
    Medication(id: id, name: name, createdAt: createdAt);

void main() {
  // Wednesday 2026-07-08, 15:00 local.
  final now = DateTime(2026, 7, 8, 15);

  final today = _med('m1', 'Today', DateTime(2026, 7, 8, 9));
  final thisWeek = _med('m2', 'This week', DateTime(2026, 7, 6, 10));
  final thisMonth = _med('m3', 'This month', DateTime(2026, 7, 5, 23));
  final thisYear = _med('m4', 'This year', DateTime(2026, 6, 20));
  final lastYear = _med('m5', 'Last year', DateTime(2025, 12, 31));
  final unknown = _med('m6', 'Unknown date', null);

  final medications = [today, thisWeek, thisMonth, thisYear, lastYear, unknown];

  const filterer = MedicationFilterer();

  List<Medication> apply(MedicationFilters filters) => filterer.apply(
    medications,
    filters,
    now: now,
    reminderMedicationIds: const {},
    everUsedNames: const {},
  );

  group('date filter', () {
    List<String> names(MedicationDateFilter date) =>
        apply(MedicationFilters(date: date)).map((m) => m.id).toList();

    test('today keeps only medications added on the current calendar day', () {
      expect(names(MedicationDateFilter.today), ['m1']);
    });

    test('week keeps Monday..now of the current calendar week', () {
      expect(names(MedicationDateFilter.week), ['m1', 'm2']);
    });

    test('month keeps the current calendar month', () {
      expect(names(MedicationDateFilter.month), ['m1', 'm2', 'm3']);
    });

    test('year keeps the current calendar year', () {
      expect(names(MedicationDateFilter.year), ['m1', 'm2', 'm3', 'm4']);
    });

    test('all keeps everything, including an unknown creation date', () {
      expect(names(MedicationDateFilter.all), hasLength(6));
    });

    test(
      'a medication with no recorded creation date never matches a specific window',
      () {
        for (final date in [
          MedicationDateFilter.today,
          MedicationDateFilter.week,
          MedicationDateFilter.month,
          MedicationDateFilter.year,
        ]) {
          expect(names(date), isNot(contains('m6')));
        }
      },
    );
  });

  group('reminder filter', () {
    test('withReminder keeps only medications with a configured reminder', () {
      final result = filterer.apply(
        medications,
        const MedicationFilters(reminder: MedicationReminderFilter.withReminder),
        now: now,
        reminderMedicationIds: {'m1', 'm3'},
        everUsedNames: const {},
      );
      expect(result.map((m) => m.id).toSet(), {'m1', 'm3'});
    });

    test('withoutReminder keeps everything else', () {
      final result = filterer.apply(
        medications,
        const MedicationFilters(
          reminder: MedicationReminderFilter.withoutReminder,
        ),
        now: now,
        reminderMedicationIds: {'m1', 'm3'},
        everUsedNames: const {},
      );
      expect(result.map((m) => m.id).toSet(), {'m2', 'm4', 'm5', 'm6'});
    });
  });

  group('usage filter', () {
    test('everUsed keeps only medications matched by name to attack history', () {
      final result = filterer.apply(
        medications,
        const MedicationFilters(usage: MedicationUsageFilter.everUsed),
        now: now,
        reminderMedicationIds: const {},
        everUsedNames: {'Today', 'This year'},
      );
      expect(result.map((m) => m.id).toSet(), {'m1', 'm4'});
    });

    test('neverUsed keeps everything else', () {
      final result = filterer.apply(
        medications,
        const MedicationFilters(usage: MedicationUsageFilter.neverUsed),
        now: now,
        reminderMedicationIds: const {},
        everUsedNames: {'Today', 'This year'},
      );
      expect(result.map((m) => m.id).toSet(), {'m2', 'm3', 'm5', 'm6'});
    });
  });

  test('axes combine with AND', () {
    final result = filterer.apply(
      medications,
      const MedicationFilters(
        date: MedicationDateFilter.year,
        reminder: MedicationReminderFilter.withReminder,
        usage: MedicationUsageFilter.everUsed,
      ),
      now: now,
      reminderMedicationIds: {'m1', 'm4'},
      everUsedNames: {'This year'},
    );
    // m1 has a reminder but was never used; m4 satisfies all three.
    expect(result.map((m) => m.id), ['m4']);
  });

  group('default sort', () {
    test('most recently added first', () {
      final result = apply(const MedicationFilters());
      expect(
        result.where((m) => m.createdAt != null).map((m) => m.id),
        ['m1', 'm2', 'm3', 'm4', 'm5'],
      );
    });

    test('medications with no recorded creation date sort last', () {
      final result = apply(const MedicationFilters());
      expect(result.last.id, 'm6');
    });
  });

  test('does not mutate the input list', () {
    final input = [...medications];
    apply(const MedicationFilters());
    expect(input.map((m) => m.id), medications.map((m) => m.id));
  });
}
