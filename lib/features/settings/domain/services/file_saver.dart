/// Saves an export somewhere the user chooses — on iOS the native "Save to Files" picker.
abstract interface class FileSaver {
  /// Returns false when the user backed out of the picker. Cancelling is not a failure, so callers show nothing rather than an error.
  Future<bool> save({required String sourcePath, required String filename});
}
