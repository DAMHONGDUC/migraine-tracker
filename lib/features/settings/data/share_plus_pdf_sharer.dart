import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/services/pdf_sharer.dart';

/// Writes the PDF to a temp file and hands it to the system share sheet.
/// Uses share_plus (not the `printing` package) so iOS builds stay on Swift
/// Package Manager — printing has no SPM support yet.
class SharePlusPdfSharer implements PdfSharer {
  const SharePlusPdfSharer();

  @override
  Future<void> share({
    required Uint8List bytes,
    required String filename,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')]),
    );
  }
}
