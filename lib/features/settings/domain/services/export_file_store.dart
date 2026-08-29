import 'dart:typed_data';

/// Where export files live on disk (a fake in tests).
abstract interface class ExportFileStore {
  /// Writes [bytes] under [filename] and returns the absolute path and the size actually written.
  Future<StoredExportFile> write({
    required String filename,
    required Uint8List bytes,
  });

  Future<bool> exists(String path);

  /// The bytes of a stored export, for the preview screen. Callers check [exists] first — a file taken out from under us throws here.
  Future<Uint8List> read(String path);

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
