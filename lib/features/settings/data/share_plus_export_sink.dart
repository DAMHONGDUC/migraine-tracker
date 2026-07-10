import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/services/export_sink.dart';

/// Writes the export to a temp file and hands it to the system share sheet.
class SharePlusExportSink implements ExportSink {
  const SharePlusExportSink();

  @override
  Future<void> share({
    required String content,
    required String filename,
    required String mimeType,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: mimeType)]),
    );
  }
}
