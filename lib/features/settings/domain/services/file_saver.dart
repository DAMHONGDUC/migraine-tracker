/// Saves an export somewhere the user chooses — on iOS the native "Save to
/// Files" picker. Separate from [ExportSharer]: sharing hands the file to
/// another app, saving puts a copy where the user can find it again.
abstract interface class FileSaver {
  /// Returns false when the user backed out of the picker. Cancelling is not
  /// a failure, so callers show nothing rather than an error.
  Future<bool> save({required String sourcePath, required String filename});
}
