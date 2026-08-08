import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../domain/services/export_file_store.dart';

/// Keeps exports in an `exports/` folder inside the app's documents
/// directory, so the history screen can re-share and save them later.
class DocumentsExportFileStore implements ExportFileStore {
  const DocumentsExportFileStore();

  static const String folderName = 'exports';

  @override
  Future<StoredExportFile> write({
    required String filename,
    required Uint8List bytes,
  }) async {
    final Directory dir = await _exportsDir();
    final File file = File('${dir.path}/$filename');

    await file.writeAsBytes(bytes);

    return StoredExportFile(path: file.path, sizeBytes: bytes.length);
  }

  // existsSync, not the async form — avoid_slow_async_io flags async as the slow path.
  @override
  Future<bool> exists(String path) async => File(path).existsSync();

  @override
  Future<Uint8List> read(String path) => File(path).readAsBytes();

  @override
  Future<void> delete(String path) async {
    final File file = File(path);

    if (file.existsSync()) await file.delete();
  }

  @override
  Future<void> deleteAll() async {
    final Directory dir = await _exportsDir();

    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  Future<Directory> _exportsDir() async {
    final Directory documents = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${documents.path}/$folderName');

    return dir.create(recursive: true);
  }
}
