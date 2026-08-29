import 'package:in_app_review/in_app_review.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/services/review_prompter.dart';

/// `SKStoreReviewController` on iOS, the Play In-App Review API on Android.
class InAppReviewPrompter implements ReviewPrompter {
  const InAppReviewPrompter(this._review);

  final InAppReview _review;

  @override
  Future<bool> request() async {
    try {
      final bool available = await _review.isAvailable();

      if (!available) {
        SdLogger.info(LogTagConstant.review, 'Review prompt unavailable', {
          'available': false,
        });
        return false;
      }
      await _review.requestReview();
      // "Asked", never "shown": iOS returns nothing and may draw nothing.
      SdLogger.info(LogTagConstant.review, 'Review prompt requested', {
        'available': true,
      });

      return true;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.review,
        'Review prompt failed',
        error: error,
        stackTrace: stackTrace,
      );

      return false;
    }
  }
}
