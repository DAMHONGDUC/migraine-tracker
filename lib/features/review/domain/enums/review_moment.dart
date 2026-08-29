/// A moment the app has just been useful, and may therefore ask to be rated.
enum ReviewMoment {
  /// A doctor report left the app — the thing the PDF export exists for.
  doctorReport,

  /// An attack was logged inside the window after a pressure alert, so the alert the user pays for turned out to be right.
  correctAlert,
}
