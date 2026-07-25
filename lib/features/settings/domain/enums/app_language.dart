/// The language choices offered in Settings.
///
/// Exists so "follow the system" is a value like any other. The locale
/// itself is nullable (`null` = system), which makes a picker unable to tell
/// "chose System" from "dismissed without choosing" — an enum has no such
/// hole, and it compares by identity, which is what the single-choice sheet
/// needs.
///
/// Pure Dart on purpose (domain layer): the mapping to a Flutter `Locale`
/// belongs to presentation.
enum AppLanguage {
  system(null),
  english('en'),
  vietnamese('vi');

  const AppLanguage(this.languageCode);

  /// Null for [system] — there is no fixed code to store.
  final String? languageCode;

  /// The choice matching a persisted locale, falling back to [system] for
  /// null and for any code this build no longer ships.
  static AppLanguage fromCode(String? code) => values.firstWhere(
    (AppLanguage language) => language.languageCode == code,
    orElse: () => system,
  );
}
