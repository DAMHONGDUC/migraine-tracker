import 'package:share_plus/share_plus.dart';

import '../domain/services/export_sharer.dart';

/// Hands the stored export file to the system share sheet. Uses share_plus
/// rather than the `printing` package — one sharer for JSON, CSV and the
/// PDF report alike, instead of a second dependency for one of the three.
class SharePlusExportSharer implements ExportSharer {
  const SharePlusExportSharer();

  @override
  Future<void> shareFile({
    required String path,
    required String mimeType,
  }) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path, mimeType: mimeType)]),
    );
  }
}
