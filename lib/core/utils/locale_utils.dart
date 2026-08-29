import 'dart:ui';

/// Which locale a string should be rendered in when there is no `BuildContext` to ask — a notification scheduled from a background sync, for instance.
final class LocaleUtils {
  /// The user's own choice, else the platform's, else [fallback].
  static Locale resolve({
    required Locale? chosen,
    required Locale platform,
    required Iterable<Locale> supported,
    Locale fallback = const Locale('en'),
  }) {
    final Locale wanted = chosen ?? platform;

    return supported.any(
          (Locale locale) => locale.languageCode == wanted.languageCode,
        )
        ? Locale(wanted.languageCode)
        : fallback;
  }
}
