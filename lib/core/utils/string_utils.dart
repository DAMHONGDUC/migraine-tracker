/// String shaping the UI needs and `String` does not carry.
final class StringUtils {
  const StringUtils._();

  /// The first word of a full name, for a greeting.
  ///
  /// "Dam Hong Duc" → "Dam", "  Duc  " → "Duc", "" → null. Null is "nothing to
  /// greet by name", so the caller falls back to the nameless greeting rather
  /// than printing an empty one.
  static String? firstName(String? fullName) {
    final String trimmed = fullName?.trim() ?? '';

    if (trimmed.isEmpty) return null;

    return trimmed.split(RegExp(r'\s+')).first;
  }
}
