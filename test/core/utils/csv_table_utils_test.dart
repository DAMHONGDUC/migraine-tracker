import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/utils/csv_table_utils.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/settings/domain/services/data_export_service.dart';

/// The preview reads a CSV back the way a spreadsheet would, which means
/// honouring the quoting `DataExportService.toCsv` writes.
void main() {
  test('reads back a header and its rows', () {
    final List<List<String>> rows = CsvTableUtils.parse(
      'id,intensity\r\na1,7\r\na2,3',
    );

    expect(rows, <List<String>>[
      <String>['id', 'intensity'],
      <String>['a1', '7'],
      <String>['a2', '3'],
    ]);
  });

  test('a quoted field keeps its commas as one cell', () {
    // Splitting on the comma is what turns one note into two columns.
    final List<List<String>> rows = CsvTableUtils.parse(
      'notes,intensity\r\n"woke up, then it built",7',
    );

    expect(rows[1], <String>['woke up, then it built', '7']);
  });

  test('a doubled quote is one literal quote', () {
    final List<List<String>> rows = CsvTableUtils.parse(
      'notes\r\n"she said ""ouch"""',
    );

    expect(rows[1], <String>['she said "ouch"']);
  });

  test('a quoted field may hold a line break', () {
    final List<List<String>> rows = CsvTableUtils.parse('notes\r\n"first\nsecond"');

    expect(rows, hasLength(2));
    expect(rows[1].single, 'first\nsecond');
  });

  test('empty cells survive, and empty input is no rows', () {
    expect(CsvTableUtils.parse('a,,c').single, <String>['a', '', 'c']);
    expect(CsvTableUtils.parse(''), isEmpty);
  });

  test('a real export round-trips: every row has the header s columns', () {
    final String csv = const DataExportService().toCsv(<Attack>[
      Attack(
        id: 'a1',
        startedAt: DateTime.utc(2026, 8, 1, 9),
        intensity: 7,
        location: HeadLocation.left,
        medicationName: 'Sumatriptan',
        notes: 'woke up, then it built',
        symptoms: const <String>['aura'],
      ),
    ]);

    final List<List<String>> rows = CsvTableUtils.parse(csv);

    expect(rows, hasLength(2));
    expect(rows[1], hasLength(rows.first.length));
    expect(rows[1], contains('woke up, then it built'));
    expect(rows[1], contains('Sumatriptan'));
  });
}
