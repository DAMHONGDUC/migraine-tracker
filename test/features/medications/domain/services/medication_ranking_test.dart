import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:migraine_tracker/features/medications/domain/services/medication_ranking.dart';

Medication _med(String name) => Medication(id: 'id-$name', name: name);

List<String> _names(List<Medication> meds) =>
    meds.map((m) => m.name).toList();

void main() {
  group('MedicationRanking.byRecentUse', () {
    // Repository order — alphabetical, as watchAll() delivers it.
    final all = [
      _med('Aspirin'),
      _med('Ibuprofen'),
      _med('Naproxen'),
      _med('Sumatriptan'),
    ];

    test('puts the most recently taken medication first', () {
      final ranked = MedicationRanking.byRecentUse(all, ['Sumatriptan']);

      expect(_names(ranked), [
        'Sumatriptan',
        'Aspirin',
        'Ibuprofen',
        'Naproxen',
      ]);
    });

    test('orders several taken medications by recency, newest first', () {
      final ranked = MedicationRanking.byRecentUse(all, [
        'Naproxen',
        'Sumatriptan',
        'Aspirin',
      ]);

      expect(_names(ranked), [
        'Naproxen',
        'Sumatriptan',
        'Aspirin',
        'Ibuprofen',
      ]);
    });

    test('ranks by most recent use, not by how often it was taken', () {
      final ranked = MedicationRanking.byRecentUse(all, [
        'Naproxen',
        'Sumatriptan',
        'Sumatriptan',
        'Sumatriptan',
      ]);

      expect(_names(ranked).first, 'Naproxen');
    });

    test('keeps never-taken medications alphabetical after the ranked ones', () {
      final ranked = MedicationRanking.byRecentUse(all, ['Sumatriptan', 'Naproxen']);

      expect(_names(ranked).sublist(2), ['Aspirin', 'Ibuprofen']);
    });

    test('ignores "no medication" entries in the history', () {
      final ranked = MedicationRanking.byRecentUse(all, [null, null, 'Ibuprofen']);

      expect(_names(ranked).first, 'Ibuprofen');
    });

    test('ignores history naming a medication that no longer exists', () {
      final ranked = MedicationRanking.byRecentUse(all, ['Deleted med', 'Aspirin']);

      expect(_names(ranked), [
        'Aspirin',
        'Ibuprofen',
        'Naproxen',
        'Sumatriptan',
      ]);
    });

    test('keeps alphabetical order when nothing has been taken yet', () {
      expect(_names(MedicationRanking.byRecentUse(all, const [])), _names(all));
      expect(_names(MedicationRanking.byRecentUse(all, const [null, null])), _names(all));
    });

    test('handles empty and single-entry medication lists', () {
      expect(MedicationRanking.byRecentUse(const [], ['Aspirin']), isEmpty);
      expect(_names(MedicationRanking.byRecentUse([_med('Aspirin')], ['Aspirin'])), [
        'Aspirin',
      ]);
    });

    test('does not mutate the medication list it is given', () {
      final input = [...all];
      MedicationRanking.byRecentUse(input, ['Sumatriptan']);

      expect(_names(input), _names(all));
    });
  });
}
