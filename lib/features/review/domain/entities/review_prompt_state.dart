import 'package:meta/meta.dart';

/// What the app remembers about ever having asked for a review.
@immutable
class ReviewPromptState {
  const ReviewPromptState({this.askCount = 0, this.lastAskedAt});

  /// Never asked — a fresh install, and the state a failed read falls back to.
  static const ReviewPromptState never = ReviewPromptState();

  final int askCount;

  /// UTC. Null when [askCount] is 0.
  final DateTime? lastAskedAt;
}
