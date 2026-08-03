import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication_draft.dart';
import 'package:migraine_tracker/features/medications/domain/services/medication_label_parser.dart';

/// The parser only ever proposes — a wrong guess costs the user an edit, a
/// confident wrong guess costs them a wrong medicine record. These pin what
/// it is allowed to claim.
void main() {
  const MedicationLabelParser parser = MedicationLabelParser();

  test('an empty scan proposes nothing', () {
    final MedicationDraft draft = parser.parse(const <String>[]);

    expect(draft.isEmpty, isTrue);
  });

  test('blank lines never become the name', () {
    final MedicationDraft draft = parser.parse(const <String>[
      '   ',
      '',
      'Panadol Extra',
    ]);

    expect(draft.name, 'Panadol Extra');
  });

  test('the first real line is the name, the strength comes off any line', () {
    final MedicationDraft draft = parser.parse(const <String>[
      'Sumatriptan',
      '50 mg film-coated tablets',
    ]);

    expect(draft.name, 'Sumatriptan');
    expect(draft.strength, '50 mg');
  });

  test('a strength printed on the name line still reads', () {
    final MedicationDraft draft = parser.parse(const <String>[
      'Panadol Extra 500mg',
    ]);

    expect(draft.name, 'Panadol Extra 500mg');
    expect(draft.strength, '500mg');
  });

  test('a line that is only a strength does not name the medication', () {
    final MedicationDraft draft = parser.parse(const <String>[
      '500 mg',
      'Paracetamol',
    ]);

    expect(draft.name, 'Paracetamol');
    expect(draft.strength, '500 mg');
  });

  test('a batch number is not a strength', () {
    final MedicationDraft draft = parser.parse(const <String>[
      'Ibuprofen',
      'Lot L20250416',
    ]);

    expect(draft.strength, isNull);
  });

  test('labelled fields are read, inline or on the next line', () {
    final MedicationDraft draft = parser.parse(const <String>[
      'Rizatriptan',
      'Active ingredients: Rizatriptan benzoate',
      'Dosage',
      '1 tablet, twice a day',
      'Directions: After food, with water',
    ]);

    expect(draft.ingredients, 'Rizatriptan benzoate');
    expect(draft.dosage, '1 tablet, twice a day');
    expect(draft.instructions, 'After food, with water');
  });

  test('Vietnamese labels are read too, accents and all', () {
    final MedicationDraft draft = parser.parse(const <String>[
      'Efferalgan',
      'Thành phần: Paracetamol 500mg',
      'Liều dùng: 1 viên mỗi 6 giờ',
      'Cách dùng: Uống sau ăn',
    ]);

    expect(draft.ingredients, 'Paracetamol 500mg');
    expect(draft.dosage, '1 viên mỗi 6 giờ');
    expect(draft.instructions, 'Uống sau ăn');
  });

  test('a label line never becomes the name', () {
    final MedicationDraft draft = parser.parse(const <String>[
      'Ingredients: Paracetamol',
      'Panadol',
    ]);

    expect(draft.name, 'Panadol');
  });

  test('the first value wins when a label repeats', () {
    final MedicationDraft draft = parser.parse(const <String>[
      'Aspirin',
      'Dosage: 1 tablet',
      'Dosage: 2 tablets',
    ]);

    expect(draft.dosage, '1 tablet');
  });

  test('a paragraph of small print is not a field value', () {
    final String smallPrint = 'a' * 200;
    final MedicationDraft draft = parser.parse(<String>[
      'Naproxen',
      'Directions: $smallPrint',
    ]);

    expect(draft.instructions, isNull);
  });
}
