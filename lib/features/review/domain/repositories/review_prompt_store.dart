import '../entities/review_prompt_state.dart';

/// Remembers how often the review prompt has been asked for.
///
/// Device-local and never synced: the cap it feeds is the OS's, and the OS
/// is this device's. A second phone gets its own three.
abstract interface class ReviewPromptStore {
  /// [ReviewPromptState.never] when nothing was ever stored.
  Future<ReviewPromptState> read();

  /// Records one ask at [at] and bumps the count.
  Future<void> recordAsked(DateTime at);
}
