import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';

/// The contract between `tool/head_model.py` and the picker: one mesh node per
/// region, spelled exactly as the enum spells it.
///
/// The nose once shipped unpickable and was reported as *missing* rather than
/// as broken, because nothing on screen says which areas exist. A node whose
/// name drifts from the enum is that same failure, and this is what turns it
/// into a red run instead of a bug report.
void main() {
  late Map<String, Object?> gltf;

  setUpAll(() {
    final Uint8List bytes = File('assets/models/head.glb').readAsBytesSync();
    final ByteData data = ByteData.sublistView(bytes);

    expect(data.getUint32(0, Endian.little), 0x46546C67, reason: 'glTF magic');
    expect(data.getUint32(4, Endian.little), 2, reason: 'glTF version');
    expect(data.getUint32(8, Endian.little), bytes.length, reason: 'length');

    int offset = 12;
    Map<String, Object?>? json;

    while (offset < bytes.length) {
      final int length = data.getUint32(offset, Endian.little);
      final int kind = data.getUint32(offset + 4, Endian.little);

      if (kind == 0x4E4F534A) {
        json =
            jsonDecode(
                  utf8.decode(bytes.sublist(offset + 8, offset + 8 + length)),
                )
                as Map<String, Object?>;
      }

      offset += 8 + length;
    }

    gltf = json!;
  });

  List<String> nodeNames() => <String>[
    for (final Object? node in gltf['nodes']! as List<Object?>)
      (node! as Map<String, Object?>)['name']! as String,
  ];

  test('every region is a node, and every node is a region', () {
    final Set<String> regions = nodeNames()
        .where((String name) => name.startsWith('region_'))
        .map((String name) => name.substring('region_'.length))
        .toSet();

    // Both directions: a node the enum lost is dead weight, and a region with
    // no node is an area the user can name but never point at.
    expect(
      regions,
      HeadRegion.values.map((HeadRegion region) => region.name).toSet(),
    );
  });

  test('the face is one node, so it can be taken out of the ray', () {
    expect(nodeNames(), contains('features'));
  });

  test('every region node carries geometry', () {
    final List<Object?> meshes = gltf['meshes']! as List<Object?>;

    for (final Object? node in gltf['nodes']! as List<Object?>) {
      final Map<String, Object?> entry = node! as Map<String, Object?>;
      final String name = entry['name']! as String;

      if (!name.startsWith('region_')) continue;

      final int index = entry['mesh']! as int;
      final List<Object?> primitives =
          (meshes[index]! as Map<String, Object?>)['primitives']!
              as List<Object?>;

      expect(primitives, isNotEmpty, reason: '$name has no primitive');
    }
  });
}
