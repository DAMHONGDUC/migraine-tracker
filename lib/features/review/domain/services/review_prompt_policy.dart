import '../../../../core/constants/review_prompt_constant.dart';
import '../entities/review_prompt_state.dart';

/// Decides whether a value moment may become a store review prompt.
class ReviewPromptPolicy {
  const ReviewPromptPolicy();

  /// Whether the prompt may be asked for now. Two gates, both from [ReviewPromptConstant]: a lifetime cap, and a floor since the last ask.
  bool shouldAsk(ReviewPromptState state, {required DateTime now}) {
    final DateTime? lastAskedAt = state.lastAskedAt;

    if (state.askCount >= ReviewPromptConstant.maxAsks) return false;
    if (lastAskedAt == null) return true;

    return !now.toUtc().isBefore(
      lastAskedAt.toUtc().add(ReviewPromptConstant.minGapBetweenAsks),
    );
  }

  /// Whether an attack logged at [attackAt] means the alert sent at [alertAt] was right.
  bool isAlertHit({required DateTime alertAt, required DateTime attackAt}) {
    final DateTime alert = alertAt.toUtc();
    final DateTime attack = attackAt.toUtc();

    if (attack.isBefore(alert)) return false;

    return !attack.isAfter(alert.add(ReviewPromptConstant.alertHitWindow));
  }
}
