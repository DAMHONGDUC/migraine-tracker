/// Where an export ends up (system share sheet in production, a recorder in
/// tests). Keeps platform channels out of the export logic.
abstract interface class ExportSink {
  Future<void> share({
    required String content,
    required String filename,
    required String mimeType,
  });
}
