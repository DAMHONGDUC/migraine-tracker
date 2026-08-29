/// Hands an already-written export to the system share sheet (a recorder in tests).
abstract interface class ExportSharer {
  Future<void> shareFile({required String path, required String mimeType});
}
