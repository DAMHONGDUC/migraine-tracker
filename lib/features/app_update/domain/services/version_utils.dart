/// Version-name comparison for the update gate.
///
/// Never compare build names as strings: `"1.10.0" < "1.9.0"` is true for a
/// string and false for a version, and that one lie is enough to lock every
/// install out of the app. Segments are compared as numbers, in order.
abstract final class VersionUtils {
  /// `1.4.0` → `[1, 4, 0]`. Null when nothing numeric can be read, which is
  /// the caller's signal to fall back to the build number.
  ///
  /// Tolerant on purpose — the value is typed by hand into a console:
  /// `v1.4` and `1.4.0-beta.2` both parse (to `[1, 4]` and `[1, 4, 0]`),
  /// trailing pre-release tags are ignored.
  static List<int>? parse(String version) {
    final String normalized = version.trim().replaceFirst(RegExp('^[vV]'), '');
    final List<String> rawSegments = normalized.split('.');
    final List<int> segments = <int>[];

    for (final String raw in rawSegments) {
      final String trimmed = raw.trim();
      final RegExpMatch? match = RegExp(r'^\d+').firstMatch(trimmed);

      if (match == null) break;
      segments.add(int.parse(match.group(0)!));
      // A tag segment (`0-beta`, `0+3`) ends the version — everything after
      // it describes the same release.
      if (trimmed != match.group(0)) break;
    }
    return segments.isEmpty ? null : segments;
  }

  /// Negative when [a] is older than [b], 0 when equal, positive when newer.
  /// Null when either side is unparseable.
  ///
  /// Missing segments count as 0, so `1.4` and `1.4.0` are the same version.
  static int? compare(String a, String b) {
    final List<int>? left = parse(a);
    final List<int>? right = parse(b);

    if (left == null || right == null) return null;
    for (
      int i = 0;
      i < (left.length > right.length ? left : right).length;
      i++
    ) {
      final int leftSegment = i < left.length ? left[i] : 0;
      final int rightSegment = i < right.length ? right[i] : 0;

      if (leftSegment != rightSegment) return leftSegment - rightSegment;
    }
    return 0;
  }
}
