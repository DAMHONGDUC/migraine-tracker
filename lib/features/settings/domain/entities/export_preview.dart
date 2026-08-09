import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../../../core/constants/export_constant.dart';

/// A text export's own bytes, ready to read on screen.
///
/// JSON only. A PDF renders as pages instead, and CSV has no preview at all —
/// 14 columns of comma-separated text tell a reader nothing a phone screen can
/// show usefully.
@immutable
class ExportPreview {
  const ExportPreview({required this.text, required this.isTruncated});

  /// Reads [bytes] as UTF-8 and cuts them to
  /// [ExportConstant.previewMaxCharacters].
  ///
  /// Malformed bytes are replaced rather than thrown on: a preview that
  /// refuses to open tells the user less about the file than a preview with
  /// one odd character in it.
  factory ExportPreview.fromBytes(Uint8List bytes) {
    final String text = utf8.decode(bytes, allowMalformed: true);

    if (text.length <= ExportConstant.previewMaxCharacters) {
      return ExportPreview(text: text, isTruncated: false);
    }
    return ExportPreview(
      text: text.substring(0, ExportConstant.previewMaxCharacters),
      isTruncated: true,
    );
  }

  final String text;

  /// True once the file was longer than the preview cap, so the screen can
  /// say the reader is not seeing all of it.
  final bool isTruncated;
}
