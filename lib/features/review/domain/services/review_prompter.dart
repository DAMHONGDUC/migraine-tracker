/// Asks the platform to show its own review dialog.
abstract interface class ReviewPrompter {
  /// True when the platform was actually asked.
  Future<bool> request();
}
