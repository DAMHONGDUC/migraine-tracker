import 'dart:typed_data';

/// Where export files live on disk (a fake in tests). Exports go to the app's
/// documents directory rather than a temp one: the history screen offers to
/// re-share and save them later, and a temp file the OS reclaimed would leave
/// rows pointing at nothing.
abstract interface class ExportFileStore {
  /// Writes [bytes] under [filename] and returns the absolute path and the
  /// size actually written.
  Future<StoredExportFile> write({
    required String filename,
    required Uint8List bytes,
  });

  Future<bool> exists(String path);

  /// Best-effort: a file that is already gone is not an error.
  Future<void> delete(String path);

  /// Drops every stored export — part of the GDPR wipe (hard rule 8).
  Future<void> deleteAll();
}

/// What [ExportFileStore.write] produced.
class StoredExportFile {
  const StoredExportFile({required this.path, required this.sizeBytes});

  final String path;
  final int sizeBytes;
}
