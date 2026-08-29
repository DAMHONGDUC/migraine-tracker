import 'package:intl/intl.dart';

import '../enums/export_kind.dart';

/// What a new export is called on disk.
final class ExportFilenameUtils {
  /// Timestamped to the second: two exports on the same day must not overwrite each other's file.
  static final DateFormat _stamp = DateFormat('yyyy-MM-dd_HHmmss');

  static const String _reportPrefix = 'baroease_report';
  static const String _exportPrefix = 'baroease_export';

  static String of(ExportKind kind, DateTime now) {
    final String prefix = kind == ExportKind.pdf
        ? _reportPrefix
        : _exportPrefix;

    return '${prefix}_${_stamp.format(now)}.${kind.fileExtension}';
  }
}
