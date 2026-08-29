/// How many records the free plan holds, in one place.
final class PremiumLimitConstant {
  /// Attacks a free user may log.
  static const int attacks = 40;

  /// How many logs from [attacks] the dashboard starts counting down.
  static const int attacksWarnAt = 5;

  /// Medications a free user may keep. Enough for the ordinary regimen: two acute, a preventive, an anti-nausea and a supplement.
  static const int medications = 5;

  /// Reminders a free user may create, across every medication — not two each.
  static const int reminders = 2;
}
