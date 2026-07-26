/// Makes "follow the system" a value like any other. A nullable `Locale`
/// cannot tell "chose System" from "dismissed"; an enum can, and compares
/// by identity as the choice sheet needs.
///
/// Pure Dart: the mapping to `Locale` belongs to presentation.
enum AppLanguage {
  system(null),
  english('en'),
  vietnamese('vi');

  const AppLanguage(this.languageCode);

  /// Null for [system] — no fixed code to store.
  final String? languageCode;

  /// Falls back to [system] for null and for codes this build dropped.
  static AppLanguage fromCode(String? code) => values.firstWhere(
    (AppLanguage language) => language.languageCode == code,
    orElse: () => system,
  );
}
