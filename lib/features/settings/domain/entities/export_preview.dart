import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../../../core/constants/export_constant.dart';
import '../../../../core/utils/csv_table_utils.dart';

/// A text export's own bytes, ready to read on screen.
///
/// Only JSON and CSV come through here. A PDF is rendered as pages instead —
/// its bytes say nothing to a reader.
@immutable
class ExportPreview {
  const ExportPreview({
    required this.text,
    required this.isTruncated,
    this.rows,
  });

  /// Reads [bytes] as UTF-8 and cuts them to
  /// [ExportConstant.previewMaxCharacters].
  ///
  /// [asTable] parses the result into [rows] as well, for CSV: wrapped as
  /// running text a 14-column CSV reads as a wall of words, which is not what
  /// the file looks like anywhere else it is opened.
  ///
  /// Malformed bytes are replaced rather than thrown on: a preview that
  /// refuses to open tells the user less about the file than a preview with
  /// one odd character in it.
  factory ExportPreview.fromBytes(Uint8List bytes, {bool asTable = false}) {
    final String decoded = utf8.decode(bytes, allowMalformed: true);
    final bool isTruncated =
        decoded.length > ExportConstant.previewMaxCharacters;
    final String text = isTruncated
        ? decoded.substring(0, ExportConstant.previewMaxCharacters)
        : decoded;

    if (!asTable) {
      return ExportPreview(text: text, isTruncated: isTruncated);
    }

    final List<List<String>> rows = CsvTableUtils.parse(text);

    // Cutting mid-file leaves a half-read last record, which would render as
    // a row with missing columns and read as data loss rather than a cut.
    if (isTruncated && rows.isNotEmpty) rows.removeLast();

    return ExportPreview(text: text, isTruncated: isTruncated, rows: rows);
  }

  final String text;

  /// True once the file was longer than the preview cap, so the screen can
  /// say the reader is not seeing all of it.
  final bool isTruncated;

  /// Header first, then one entry per record — null for anything that is not
  /// tabular, which is how the screen chooses between a table and plain text.
  final List<List<String>>? rows;
}
