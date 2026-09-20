/// How loudly the owner's notice is drawn — the `type` field of `error_view`.
///
/// Presentation only: **it does not decide whether the notice shows**, which
/// is `enable`'s job alone. A warning and an error both replace the app; they
/// differ in the glyph and its colour, and in both, per hard rule 3, the glyph
/// changes with the colour so the severity is never carried by colour alone.
enum ErrorViewType {
  warning,
  error;

  /// The value the owner typed, or [error] for anything else.
  ///
  /// **Unreadable falls back to the louder one.** The rest of this document
  /// reads an unusable field as "does nothing", because every other field
  /// grants a privilege or takes the app away. This one is different: the
  /// notice is already being shown on purpose, so a typo in `type` must not
  /// quietly downgrade an outage to a warning.
  static ErrorViewType from(Object? value) {
    if (value is! String) return ErrorViewType.error;

    final String name = value.trim().toLowerCase();

    return ErrorViewType.values.firstWhere(
      (ErrorViewType type) => type.name == name,
      orElse: () => ErrorViewType.error,
    );
  }
}
