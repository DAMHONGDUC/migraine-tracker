/// Makes "follow the system" a value like any other. A nullable `Locale`
/// cannot tell "chose System" from "dismissed"; an enum can, and compares
/// by identity as the choice sheet needs.
///
/// Pure Dart: the mapping to `Locale` belongs to presentation.
/// Order is the order of the picker: [system] first, then the languages by
/// how many of the app's users read them, not alphabetically — a list sorted
/// by a name the reader cannot read yet sorts by nothing.
enum AppLanguage {
  system(null),
  english('en'),
  vietnamese('vi'),
  japanese('ja'),
  german('de'),
  spanish('es'),
  french('fr'),
  chinese('zh');

  const AppLanguage(this.languageCode);

  /// Null for [system] — no fixed code to store.
  final String? languageCode;

  /// Falls back to [system] for null and for codes this build dropped.
  static AppLanguage fromCode(String? code) => values.firstWhere(
    (AppLanguage language) => language.languageCode == code,
    orElse: () => system,
  );
}
