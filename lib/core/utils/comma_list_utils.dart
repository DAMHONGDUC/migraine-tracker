/// The comma-separated text fields (symptoms, triggers) read and written as a list.
final class CommaListUtils {
  /// Separator written between values — with the space, since a human types into this field.
  static const String separator = ', ';

  /// Blank entries are dropped rather than kept as empty strings: a trailing comma is how someone types, not something they meant.
  static List<String> split(String input) => input
      .split(',')
      .map((String value) => value.trim())
      .where((String value) => value.isNotEmpty)
      .toList();

  static String join(List<String> values) => values.join(separator);
}
