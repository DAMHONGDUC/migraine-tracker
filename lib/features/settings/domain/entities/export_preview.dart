import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// A text export's own bytes, ready to read on screen.
///
/// Only JSON and CSV come through here. A PDF is rendered as pages instead —
/// its bytes say nothing to a reader.
@immutable
class ExportPreview {
  const ExportPreview({required this.text, required this.isTruncated});

  /// Reads [bytes] as UTF-8 and cuts them to [maxCharacters].
  ///
  /// Malformed bytes are replaced rather than thrown on: a preview that
  /// refuses to open tells the user less about the file than a preview with
  /// one odd character in it.
  factory ExportPreview.fromBytes(Uint8List bytes) {
    final String text = utf8.decode(bytes, allowMalformed: true);

    if (text.length <= maxCharacters) {
      return ExportPreview(text: text, isTruncated: false);
    }
    return ExportPreview(
      text: text.substring(0, maxCharacters),
      isTruncated: true,
    );
  }

  /// How much of a text export is shown. A long history exports to megabytes,
  /// and the preview answers "what is in this file", not "read it end to
  /// end" — sharing or saving still hands over every byte.
  static const int maxCharacters = 20000;

  final String text;

  /// True once the file was longer than [maxCharacters], so the screen can
  /// say the reader is not seeing all of it.
  final bool isTruncated;
}
