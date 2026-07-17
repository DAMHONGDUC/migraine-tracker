import 'dart:typed_data';

/// Hands a generated PDF to the system share sheet (a recorder in tests).
abstract interface class PdfSharer {
  Future<void> share({required Uint8List bytes, required String filename});
}
