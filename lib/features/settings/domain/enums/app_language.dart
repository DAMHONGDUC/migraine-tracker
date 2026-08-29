/// Makes "follow the system" a value like any other.
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
