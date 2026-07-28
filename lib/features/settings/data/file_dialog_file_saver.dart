import 'package:flutter_file_dialog/flutter_file_dialog.dart';

import '../domain/services/file_saver.dart';

/// Opens the platform's own save dialog — on iOS the "Save to Files" picker,
/// so the user chooses iCloud Drive, On My iPhone, or any file provider.
///
/// Copies the already-stored export rather than re-serializing it: the file
/// on disk is what the history row points at, so what gets saved is exactly
/// what the row says.
class FileDialogFileSaver implements FileSaver {
  const FileDialogFileSaver();

  @override
  Future<bool> save({
    required String sourcePath,
    required String filename,
  }) async {
    final String? savedPath = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        sourceFilePath: sourcePath,
        // Suggest the same name the history row shows, so what the user
        // saves is recognisably what they tapped.
        fileName: filename,
      ),
    );

    // Null means the user dismissed the picker — not a failure.
    return savedPath != null;
  }
}
