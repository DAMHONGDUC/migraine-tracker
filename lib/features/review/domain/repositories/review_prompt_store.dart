import '../entities/review_prompt_state.dart';

/// Remembers how often the review prompt has been asked for.
abstract interface class ReviewPromptStore {
  /// [ReviewPromptState.never] when nothing was ever stored.
  Future<ReviewPromptState> read();

  /// Records one ask at [at] and bumps the count.
  Future<void> recordAsked(DateTime at);
}
