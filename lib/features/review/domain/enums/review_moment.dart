/// A moment the app has just been useful, and may therefore ask to be rated.
///
/// The two `PLAN.md` names, and nothing else: a review prompt is only ever
/// worth a moment the user would call a result. Adding a third means arguing
/// it is one.
enum ReviewMoment {
  /// A doctor report left the app — the thing the PDF export exists for.
  doctorReport,

  /// An attack was logged inside the window after a pressure alert, so the
  /// alert the user pays for turned out to be right.
  correctAlert,
}
