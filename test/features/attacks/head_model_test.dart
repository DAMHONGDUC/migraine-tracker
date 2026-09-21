import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_viewport.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// The contract between `tool/head_model.py` and the picker: one mesh node per
/// region, spelled exactly as the enum spells it.
///
/// The nose once shipped unpickable and was reported as *missing* rather than
/// as broken, because nothing on screen says which areas exist. A node whose
/// name drifts from the enum is that same failure, and this is what turns it
/// into a red run instead of a bug report.
void main() {
  late Map<String, Object?> gltf;
  late ByteData binary;
  late int assetBytes;

  setUpAll(() {
    final Uint8List bytes = File('assets/models/head.glb').readAsBytesSync();
    final ByteData data = ByteData.sublistView(bytes);
    assetBytes = bytes.length;

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

      if (kind == 0x004E4942) {
        binary = ByteData.sublistView(bytes, offset + 8, offset + 8 + length);
      }
      offset += 8 + length;
    }

    gltf = json!;
  });

  List<String> nodeNames() => <String>[
    for (final Object? node in gltf['nodes']! as List<Object?>)
      (node! as Map<String, Object?>)['name']! as String,
  ];

  /// The shipped model's own box, from the accessors' declared extents.
  vm.Aabb3 bounds() {
    final List<Object?> accessors = gltf['accessors']! as List<Object?>;
    final vm.Vector3 min = vm.Vector3.all(double.infinity);
    final vm.Vector3 max = vm.Vector3.all(double.negativeInfinity);

    for (final Object? mesh in gltf['meshes']! as List<Object?>) {
      for (final Object? primitive
          in (mesh! as Map<String, Object?>)['primitives']! as List<Object?>) {
        final Map<String, Object?> attributes =
            (primitive! as Map<String, Object?>)['attributes']!
                as Map<String, Object?>;
        final Map<String, Object?> position =
            accessors[attributes['POSITION']! as int]! as Map<String, Object?>;

        for (int axis = 0; axis < 3; axis++) {
          min[axis] = math.min(
            min[axis],
            ((position['min']! as List<Object?>)[axis]! as num).toDouble(),
          );
          max[axis] = math.max(
            max[axis],
            ((position['max']! as List<Object?>)[axis]! as num).toDouble(),
          );
        }
      }
    }

    return vm.Aabb3.minMax(min, max);
  }

  // The asset and the opening magnification are one answer: the level is
  // measured off THESE proportions, so a re-export that changes them changes
  // how big the head opens. The old flat 150% is the bar, because that is what
  // this replaced and the owner has asked for bigger three times.
  test('the shipped head opens larger on a phone than the 150% it replaced', () {
    final vm.Aabb3 box = bounds();

    expect(
      HeadViewportUtils.fitZoom(box, const Size(393, 430)),
      greaterThan(1.5),
    );
    expect(
      HeadViewportUtils.fitZoom(box, const Size(393, 430)),
      lessThanOrEqualTo(HeadViewportUtils.maxZoom),
    );
    // A head that is WIDER than it is tall would mean the model came back with
    // a neck, or on its side — either way the picker is not drawing a face.
    expect(box.max.y - box.min.y, greaterThan(box.max.x - box.min.x));
  });

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

  test('every non-root node owns visible region geometry', () {
    for (final Object? node in gltf['nodes']! as List<Object?>) {
      final Map<String, Object?> entry = node! as Map<String, Object?>;
      if (entry['name'] == 'head') continue;
      expect(entry['name'], startsWith('region_'));
      expect(entry['mesh'], isA<int>());
    }
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
  test(
    'asset stays within budget and uses only embedded standard geometry',
    () {
      final List<Object?> accessors = gltf['accessors']! as List<Object?>;
      final List<Object?> meshes = gltf['meshes']! as List<Object?>;
      int triangles = 0;

      expect(assetBytes, lessThanOrEqualTo(1024 * 1024));
      expect(nodeNames().toSet().length, nodeNames().length);
      expect(gltf['extensionsRequired'], isNull);
      for (final Object? buffer in gltf['buffers']! as List<Object?>) {
        expect((buffer! as Map<String, Object?>)['uri'], isNull);
      }
      for (final Object? mesh in meshes) {
        for (final Object? primitive
            in (mesh! as Map<String, Object?>)['primitives']!
                as List<Object?>) {
          final Map<String, Object?> value = primitive! as Map<String, Object?>;
          final Map<String, Object?> indices =
              accessors[value['indices']! as int]! as Map<String, Object?>;
          final int count = indices['count']! as int;

          expect(count, greaterThan(0));
          expect(count % 3, 0);
          triangles += count ~/ 3;
        }
      }
      expect(triangles, lessThanOrEqualTo(25000));
    },
  );

  test(
    'all positions and normals are finite and triangle indices are in range',
    () {
      final List<Object?> accessors = gltf['accessors']! as List<Object?>;
      final List<Object?> views = gltf['bufferViews']! as List<Object?>;

      for (final Object? mesh in gltf['meshes']! as List<Object?>) {
        for (final Object? primitive
            in (mesh! as Map<String, Object?>)['primitives']!
                as List<Object?>) {
          final Map<String, Object?> value = primitive! as Map<String, Object?>;
          final Map<String, Object?> attributes =
              value['attributes']! as Map<String, Object?>;
          final Map<String, Object?> position =
              accessors[attributes['POSITION']! as int]!
                  as Map<String, Object?>;
          final int vertices = position['count']! as int;

          for (final String semantic in <String>['POSITION', 'NORMAL']) {
            final Map<String, Object?> accessor =
                accessors[attributes[semantic]! as int]!
                    as Map<String, Object?>;
            final Map<String, Object?> view =
                views[accessor['bufferView']! as int]! as Map<String, Object?>;
            final int offset =
                (view['byteOffset'] as int? ?? 0) +
                (accessor['byteOffset'] as int? ?? 0);

            expect(accessor['count'], vertices);
            expect(accessor['componentType'], 5126);
            for (int i = 0; i < vertices * 3; i++) {
              expect(
                binary.getFloat32(offset + i * 4, Endian.little).isFinite,
                isTrue,
              );
            }
          }
          final Map<String, Object?> indices =
              accessors[value['indices']! as int]! as Map<String, Object?>;
          final Map<String, Object?> view =
              views[indices['bufferView']! as int]! as Map<String, Object?>;
          final int offset =
              (view['byteOffset'] as int? ?? 0) +
              (indices['byteOffset'] as int? ?? 0);

          for (int i = 0; i < (indices['count']! as int); i++) {
            expect(
              binary.getUint32(offset + i * 4, Endian.little),
              lessThan(vertices),
            );
          }
        }
      }
    },
  );
}
