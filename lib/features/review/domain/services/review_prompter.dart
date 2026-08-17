/// Asks the platform to show its own review dialog.
///
/// An interface because the plugin behind it draws an OS dialog and answers
/// nothing useful — a test can only assert that we asked, which is exactly
/// what this makes possible.
abstract interface class ReviewPrompter {
  /// True when the platform was actually asked.
  ///
  /// False means the platform has no review flow to show (a simulator, a
  /// sideloaded build, an unsupported OS) — not that the user declined.
  /// **Nobody can tell us whether the dialog appeared**, let alone whether
  /// anyone rated anything: iOS answers `requestReview` with nothing at all.
  Future<bool> request();
}
