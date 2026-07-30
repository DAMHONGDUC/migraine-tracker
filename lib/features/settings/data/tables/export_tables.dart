import 'package:drift/drift.dart';

/// One past export. Added in schema v4 so the export screen can show a
/// history instead of firing and forgetting.
@DataClassName('ExportRecordRow')
class ExportRecords extends Table {
  TextColumn get id => text()();

  /// `ExportKind.name` — json, csv or pdf.
  TextColumn get kind => text()();
  TextColumn get filename => text()();

  /// Absolute path in the app's documents directory. Stored rather than
  /// rebuilt so a rename of the naming scheme can't orphan old rows.
  TextColumn get filePath => text()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
