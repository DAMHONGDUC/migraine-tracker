/// The symptoms an attack is recorded with, as a fixed list.
///
/// Fixed for the reason `DailyFactor` is: a count is only worth reading if two
/// users' lists mean the same thing, and free text cannot be counted at all.
/// Anything outside it is still recordable — the details sheet keeps a text
/// field beside the chips, and those words stay in the same column.
///
/// Aura is NOT here. It has its own field with three states (never asked, no
/// aura, these kinds), because migraine with and without aura are separate
/// ICHD-3 entries — see `lib/features/attacks/CLAUDE.md`.
enum SymptomTag {
  nausea,
  vomiting,
  lightSensitivity,
  soundSensitivity,
  smellSensitivity,
  dizziness,
  neckPain,
  blurredVision;

  /// The stored id back to the tag, or null for a word the user typed themselves.
  static SymptomTag? tryParse(String value) {
    for (final SymptomTag tag in SymptomTag.values) {
      if (tag.name == value) return tag;
    }

    return null;
  }
}
