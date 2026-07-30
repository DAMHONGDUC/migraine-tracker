import 'package:meta/meta.dart';

import '../enums/export_kind.dart';

/// One past export, kept so the export screen can list what the user has
/// already produced and act on it again (share, save to device) without
/// rebuilding the file.
@immutable
class ExportRecord {
  const ExportRecord({
    required this.id,
    required this.kind,
    required this.filename,
    required this.filePath,
    required this.sizeBytes,
    required this.createdAt,
  });

  final String id;
  final ExportKind kind;
  final String filename;

  /// Absolute path inside the app's documents directory. The file can go
  /// missing (a restore, a manual clean-up), so callers check before use.
  final String filePath;
  final int sizeBytes;

  /// UTC, like every other timestamp on record.
  final DateTime createdAt;
}
