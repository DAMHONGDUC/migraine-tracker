import 'dart:convert';
import 'dart:typed_data';

import 'package:migraine_tracker/features/settings/domain/services/export_file_store.dart';
import 'package:migraine_tracker/features/settings/domain/services/export_sharer.dart';
import 'package:migraine_tracker/features/settings/domain/services/file_saver.dart';

/// In-memory stand-in for the documents directory. Widget tests have no
/// path_provider, so the real store would throw the moment anything exports.
class FakeExportFileStore implements ExportFileStore {
  final Map<String, Uint8List> files = <String, Uint8List>{};

  @override
  Future<StoredExportFile> write({
    required String filename,
    required Uint8List bytes,
  }) async {
    final String path = '/fake/exports/$filename';

    files[path] = bytes;

    return StoredExportFile(path: path, sizeBytes: bytes.length);
  }

  @override
  Future<bool> exists(String path) async => files.containsKey(path);

  @override
  Future<void> delete(String path) async {
    files.remove(path);
  }

  @override
  Future<void> deleteAll() async => files.clear();

  /// The only file written, decoded as text — what the JSON/CSV assertions
  /// read. Throws when there isn't exactly one, which is the bug worth
  /// failing on rather than silently reading the wrong export.
  String get singleContent => utf8.decode(files.values.single);
}

/// Records what was handed to the share sheet.
class RecordingExportSharer implements ExportSharer {
  final List<({String path, String mimeType})> shared =
      <({String path, String mimeType})>[];

  @override
  Future<void> shareFile({
    required String path,
    required String mimeType,
  }) async {
    shared.add((path: path, mimeType: mimeType));
  }
}

/// Records "Save to Files" calls. [result] false simulates the user
/// dismissing the system picker.
class RecordingFileSaver implements FileSaver {
  RecordingFileSaver({this.result = true});

  final bool result;
  final List<({String sourcePath, String filename})> saved =
      <({String sourcePath, String filename})>[];

  @override
  Future<bool> save({
    required String sourcePath,
    required String filename,
  }) async {
    saved.add((sourcePath: sourcePath, filename: filename));

    return result;
  }
}
