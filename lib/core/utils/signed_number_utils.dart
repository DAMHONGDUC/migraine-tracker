/// A number that has to show which way it went.
///
/// `toStringAsFixed` writes the minus sign and nothing else, so a rise reads
/// as a bare number next to a fall that reads as negative — the pair looks
/// like two different measurements rather than one going both ways.
///
/// Deliberately not [NumberFormat]: every other reading in the app is a plain
/// `toStringAsFixed`, and a locale-grouped one puts a thousands separator in
/// a pressure value ("1,008 hPa") that nothing else in the app has.
final class SignedNumberUtils {
  /// [value] with an explicit `+` when positive. Zero takes no sign: it went
  /// nowhere.
  static String format(double value, {int fractionDigits = 1}) =>
      '${value > 0 ? '+' : ''}${value.toStringAsFixed(fractionDigits)}';
}
