import 'package:in_app_review/in_app_review.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/services/review_prompter.dart';

/// `SKStoreReviewController` on iOS, the Play In-App Review API on Android.
///
/// **Never wire this to a button.** Apple's guidelines forbid a control that
/// calls `requestReview` — the dialog has to arrive on its own, which is why
/// the only callers are value moments. `openStoreListing` is the API for a
/// button, and nothing here needs one yet.
class InAppReviewPrompter implements ReviewPrompter {
  const InAppReviewPrompter(this._review);

  final InAppReview _review;

  @override
  Future<bool> request() async {
    try {
      final bool available = await _review.isAvailable();

      if (!available) {
        AppLogger.info('Review prompt unavailable', {'available': false});
        return false;
      }
      await _review.requestReview();
      // "Asked", never "shown": iOS returns nothing and may draw nothing.
      AppLogger.info('Review prompt requested', {'available': true});

      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Review prompt failed',
        error: error,
        stackTrace: stackTrace,
      );

      return false;
    }
  }
}
