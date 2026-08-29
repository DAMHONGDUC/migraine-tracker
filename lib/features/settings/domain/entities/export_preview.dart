import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../../../core/constants/export_constant.dart';

/// A text export's own bytes, ready to read on screen.
@immutable
class ExportPreview {
  const ExportPreview({required this.text, required this.isTruncated});

  /// Reads [bytes] as UTF-8 and cuts them to [ExportConstant.previewMaxCharacters].
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

  /// True once the file was longer than the preview cap, so the screen can say the reader is not seeing all of it.
  final bool isTruncated;
}
