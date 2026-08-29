/// A number that has to show which way it went.
final class SignedNumberUtils {
  /// [value] with an explicit `+` when positive. Zero takes no sign: it went nowhere.
  static String format(double value, {int fractionDigits = 1}) =>
      '${value > 0 ? '+' : ''}${value.toStringAsFixed(fractionDigits)}';
}
