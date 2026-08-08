import 'package:system_design/index.dart';

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

  /// Width of one cell in the CSV preview's table.
  ///
  /// Fixed, so every column lines up down the table without laying the whole
  /// file out twice to measure it — the table scrolls sideways instead.
  static double get previewCellWidth => SdSpacingConstant.w160;
}
