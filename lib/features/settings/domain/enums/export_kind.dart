/// What an export produced. Replaces the old `ExportFormat`, which only knew
/// the two data formats — the doctor report now lands in the same history,
/// so one enum covers everything the export screen can make.
enum ExportKind {
  json,
  csv,
  pdf;

  /// Extension without the dot, used to build the filename.
  String get fileExtension => switch (this) {
    ExportKind.json => 'json',
    ExportKind.csv => 'csv',
    ExportKind.pdf => 'pdf',
  };

  String get mimeType => switch (this) {
    ExportKind.json => 'application/json',
    ExportKind.csv => 'text/csv',
    ExportKind.pdf => 'application/pdf',
  };
}
