import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../../core/constants/export_constant.dart';
import '../domain/services/export_file_store.dart';

/// Keeps exports in an `exports/` folder inside the app's documents directory, so the history screen can re-share and save them later.
class DocumentsExportFileStore implements ExportFileStore {
  const DocumentsExportFileStore();

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
  Future<bool> exists(String path) async => (await _resolve(path)).existsSync();

  @override
  Future<Uint8List> read(String path) async =>
      (await _resolve(path)).readAsBytes();

  @override
  Future<void> delete(String path) async {
    final File file = await _resolve(path);

    if (file.existsSync()) await file.delete();
  }

  /// The file a stored path means *now*.
  Future<File> _resolve(String path) async {
    final File direct = File(path);

    if (direct.existsSync()) return direct;

    final Directory dir = await _exportsDir();

    return File('${dir.path}/${_basename(path)}');
  }

  /// Last segment of [path], for either separator — the records were written on this device, but the separator is not worth assuming.
  String _basename(String path) => path.split(RegExp(r'[/\\]')).last;

  @override
  Future<void> deleteAll() async {
    final Directory dir = await _exportsDir();

    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  Future<Directory> _exportsDir() async {
    final Directory documents = await getApplicationDocumentsDirectory();
    final Directory dir = Directory(
      '${documents.path}/${ExportConstant.folderName}',
    );

    return dir.create(recursive: true);
  }
}
