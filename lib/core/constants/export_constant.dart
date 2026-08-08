/// Numbers the export feature runs by.
final class ExportConstant {
  /// How much of a text export the preview screen shows.
  ///
  /// A long history exports to megabytes, and the preview answers "what is in
  /// this file", not "read it end to end" — sharing or saving still hands
  /// over every byte.
  static const int previewMaxCharacters = 20000;

  /// Folder inside the app's documents directory that holds past exports.
  static const String folderName = 'exports';
}
