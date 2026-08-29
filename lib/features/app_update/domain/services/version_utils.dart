/// Version-name comparison for the update gate.
abstract final class VersionUtils {
  /// `1.4.0` → `[1, 4, 0]`.
  static List<int>? parse(String version) {
    final String normalized = version.trim().replaceFirst(RegExp('^[vV]'), '');
    final List<String> rawSegments = normalized.split('.');
    final List<int> segments = <int>[];

    for (final String raw in rawSegments) {
      final String trimmed = raw.trim();
      final RegExpMatch? match = RegExp(r'^\d+').firstMatch(trimmed);

      if (match == null) break;
      segments.add(int.parse(match.group(0)!));
      // A tag segment (`0-beta`, `0+3`) ends the version — the rest describes the same release.
      if (trimmed != match.group(0)) break;
    }
    return segments.isEmpty ? null : segments;
  }

  /// Negative when [a] is older than [b], 0 when equal, positive when newer.
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
