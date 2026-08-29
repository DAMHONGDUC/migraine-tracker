import 'package:share_plus/share_plus.dart';

import '../domain/services/export_sharer.dart';

/// Hands the stored export file to the system share sheet.
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
