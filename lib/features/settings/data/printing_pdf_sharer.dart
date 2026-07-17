import 'dart:typed_data';

import 'package:printing/printing.dart';

import '../domain/services/pdf_sharer.dart';

class PrintingPdfSharer implements PdfSharer {
  const PrintingPdfSharer();

  @override
  Future<void> share({
    required Uint8List bytes,
    required String filename,
  }) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
