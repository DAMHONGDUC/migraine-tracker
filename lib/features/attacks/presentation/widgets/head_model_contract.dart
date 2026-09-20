import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../../domain/enums/head_region.dart';

final class HeadModelContract {
  const HeadModelContract._();

  static String nodeName(HeadRegion region) => 'region_${region.name}';

  static HeadRegion? regionOf(String? name) {
    for (final HeadRegion region in HeadRegion.values) {
      if (nodeName(region) == name) return region;
    }
    return null;
  }

  static Iterable<Node> nodes(Node root) sync* {
    yield root;
    for (final Node child in root.children) {
      yield* nodes(child);
    }
  }

  static void validate(Node root) {
    final Set<HeadRegion> found = <HeadRegion>{};
    final vm.Aabb3? bounds = root.combinedWorldBounds;

    if (bounds == null ||
        bounds.min.storage.any((double value) => !value.isFinite) ||
        bounds.max.storage.any((double value) => !value.isFinite) ||
        (bounds.max - bounds.min).length2 <= 0) {
      throw const FormatException('Unbounded or empty head model');
    }

    for (final Node node in nodes(root)) {
      final HeadRegion? region = regionOf(node.name);

      if (region == null) {
        if (node.name.startsWith('region_')) {
          throw FormatException('Unknown head region: ${node.name}');
        }
        continue;
      }
      if (!found.add(region) ||
          node.mesh == null ||
          node.mesh!.primitives.isEmpty ||
          node.combinedWorldBounds == null) {
        throw FormatException('Invalid or duplicate head region: ${node.name}');
      }
    }
    if (found.length != HeadRegion.values.length) {
      throw const FormatException('Incomplete head model');
    }
  }
}
