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

  /// Locales whose script the report's bundled fonts cannot draw.
  ///
  /// The PDF renders with Noto Sans regular/bold, which carry Latin only, so a
  /// CJK locale would print a page of blank boxes. Those locales get the
  /// English report instead; a bundled CJK face costs ~16 MB of app size.
  static const Set<String> reportFontlessLocales = <String>{'ja', 'zh'};
}
