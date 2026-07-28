/// Hands an already-written export to the system share sheet (a recorder in
/// tests). Replaces the old `ExportSink`/`PdfSharer` pair: now that every
/// export is written to disk first, one path-based sharer covers JSON, CSV
/// and the doctor report alike.
abstract interface class ExportSharer {
  Future<void> shareFile({required String path, required String mimeType});
}
