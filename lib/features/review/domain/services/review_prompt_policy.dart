import '../../../../core/constants/review_prompt_constant.dart';
import '../entities/review_prompt_state.dart';

/// Decides whether a value moment may become a store review prompt.
///
/// Pure Dart and the whole of the rule, so the thing that can be got wrong —
/// asking too often — is the thing under test. The controller only sequences
/// the calls around it.
class ReviewPromptPolicy {
  const ReviewPromptPolicy();

  /// Whether the prompt may be asked for now.
  ///
  /// Two gates, both from [ReviewPromptConstant]: a lifetime cap, and a
  /// floor since the last ask.
  bool shouldAsk(ReviewPromptState state, {required DateTime now}) {
    final DateTime? lastAskedAt = state.lastAskedAt;

    if (state.askCount >= ReviewPromptConstant.maxAsks) return false;
    if (lastAskedAt == null) return true;

    return !now.toUtc().isBefore(
      lastAskedAt.toUtc().add(ReviewPromptConstant.minGapBetweenAsks),
    );
  }

  /// Whether an attack logged at [attackAt] means the alert sent at
  /// [alertAt] was right.
  ///
  /// An attack *before* the alert never counts, however close: the alert has
  /// to have come first to have predicted anything.
  bool isAlertHit({required DateTime alertAt, required DateTime attackAt}) {
    final DateTime alert = alertAt.toUtc();
    final DateTime attack = attackAt.toUtc();

    if (attack.isBefore(alert)) return false;

    return !attack.isAfter(alert.add(ReviewPromptConstant.alertHitWindow));
  }
}
