import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/settings/domain/entities/export_preview.dart';

void main() {
  Uint8List bytesOf(String text) => Uint8List.fromList(utf8.encode(text));

  test('a short export is shown whole', () {
    final ExportPreview preview = ExportPreview.fromBytes(
      bytesOf('{"attacks":[]}'),
    );

    expect(preview.text, '{"attacks":[]}');
    expect(preview.isTruncated, isFalse);
  });

  test('a long export is cut, and says so', () {
    final ExportPreview preview = ExportPreview.fromBytes(
      bytesOf('x' * (ExportPreview.maxCharacters + 500)),
    );

    expect(preview.text, hasLength(ExportPreview.maxCharacters));
    expect(preview.isTruncated, isTrue);
  });

  test('exactly the limit is not truncated', () {
    final ExportPreview preview = ExportPreview.fromBytes(
      bytesOf('x' * ExportPreview.maxCharacters),
    );

    expect(preview.isTruncated, isFalse);
  });

  test('a bad byte does not stop the preview opening', () {
    // A preview that refuses to open says less about the file than one with
    // a replacement character in it.
    final ExportPreview preview = ExportPreview.fromBytes(
      Uint8List.fromList(<int>[0xC3, 0x28, 0x61]),
    );

    expect(preview.text, endsWith('a'));
  });

  test('multi-byte characters survive the round trip', () {
    final ExportPreview preview = ExportPreview.fromBytes(
      bytesOf('{"note":"đau nửa đầu"}'),
    );

    expect(preview.text, contains('đau nửa đầu'));
  });
}
