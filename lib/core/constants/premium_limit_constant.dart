/// How many records the free plan holds, in one place.
final class PremiumLimitConstant {
  /// How far back the free plan reads and analyses.
  ///
  /// It replaces a 40-attack lifetime cap (owner's call, 2026-09-14). Logging
  /// is never capped now: the app calls the record the user's own in every
  /// other sentence it says, and a wall in front of writing one contradicts
  /// that — a chronic sufferer hit it in month three, exactly when the
  /// correlation had finally gathered enough to be worth paying for, and left
  /// rather than paid. What is sold instead is the long history, the
  /// correlation, the forecast and the doctor report.
  static const Duration freeHistoryWindow = Duration(days: 90);

  /// Medications a free user may keep. Enough for the ordinary regimen: two acute, a preventive, an anti-nausea and a supplement.
  static const int medications = 5;

  /// Reminders a free user may create, across every medication — not two each.
  static const int reminders = 2;
}
