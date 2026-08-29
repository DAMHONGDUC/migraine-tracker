/// What an export produced.
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
