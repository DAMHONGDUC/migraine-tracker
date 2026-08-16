import 'package:meta/meta.dart';

/// What the app remembers about ever having asked for a review.
///
/// Deliberately not "has the user rated us": the store never tells us, and a
/// prompt the OS decided not to draw is indistinguishable from one it did.
/// So this counts what we *asked for*, which is the only thing we know.
@immutable
class ReviewPromptState {
  const ReviewPromptState({this.askCount = 0, this.lastAskedAt});

  /// Never asked — a fresh install, and the state a failed read falls back
  /// to. Falling back to "never" risks one extra prompt; falling back to
  /// "asked three times" would silence the feature forever on one bad read.
  static const ReviewPromptState never = ReviewPromptState();

  final int askCount;

  /// UTC. Null when [askCount] is 0.
  final DateTime? lastAskedAt;
}
