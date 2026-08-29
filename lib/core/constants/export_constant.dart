/// Numbers the export feature runs by.
final class ExportConstant {
  /// How much of a text export the preview screen shows.
  static const int previewMaxCharacters = 20000;

  /// Folder inside the app's documents directory that holds past exports.
  static const String folderName = 'exports';

  /// Locales whose script the report's bundled fonts cannot draw.
  static const Set<String> reportFontlessLocales = <String>{'ja', 'zh'};
}
