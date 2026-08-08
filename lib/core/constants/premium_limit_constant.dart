/// How many records the free plan holds, in one place.
///
/// The numbers and the reasoning behind each one are documented in
/// `docs/PREMIUM_RULES.md`, which is the authority; this class is what the
/// code reads.
///
/// It sits in `core/` rather than on `Attack`, `Medication` or
/// `MedicationReminder` because a constant on an entity is a number the
/// entity does not use — the gate providers and the limit dialogs do — and
/// because three features have to agree on them.
final class PremiumLimitConstant {
  /// Attacks a free user may log.
  ///
  /// Well clear of `CorrelationEngine.minAttacks` (15): the wall must sit far
  /// enough past it that every free user reaches the insight the paywall is
  /// selling before meeting the wall.
  static const int attacks = 40;

  /// How many logs from [attacks] the dashboard starts counting down.
  ///
  /// The wall lands on the log button, which is tapped mid-attack — the worst
  /// moment to learn a limit exists, so it is never the first the user hears
  /// of it.
  static const int attacksWarnAt = 5;

  /// Medications a free user may keep. Enough for the ordinary regimen: two
  /// acute, a preventive, an anti-nausea and a supplement.
  static const int medications = 5;

  /// Reminders a free user may create, across every medication — not two
  /// each. Two, because a preventive taken morning and evening is the
  /// ordinary regimen and a limit that blocks it on day one reads as broken
  /// rather than tiered.
  static const int reminders = 2;
}
