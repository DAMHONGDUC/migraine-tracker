import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../notifications/domain/entities/app_notification.dart';
import '../../../notifications/providers.dart';
import '../../domain/entities/review_prompt_state.dart';
import '../../domain/enums/review_moment.dart';
import '../../domain/services/review_prompt_policy.dart';
import '../../providers.dart';

/// Turns a value moment into a store review prompt, or into nothing.
class ReviewPromptController {
  const ReviewPromptController(this._ref);

  final Ref _ref;

  static const ReviewPromptPolicy _policy = ReviewPromptPolicy();

  /// A doctor report reached the share sheet — the PDF export's whole point.
  Future<void> onDoctorReportShared() => _consider(ReviewMoment.doctorReport);

  /// An attack was logged at [attackAt].
  Future<void> onAttackLogged(DateTime attackAt) async {
    try {
      final AppNotification? alert = await _ref
          .read(notificationRepositoryProvider)
          .latestPressureAlert();

      if (alert == null) return;

      final bool hit = _policy.isAlertHit(
        alertAt: alert.occurredAt,
        attackAt: attackAt,
      );

      SdLogger.info(LogTagConstant.review, 'Alert hit checked', {
        'alertAt': alert.occurredAt.toUtc().toIso8601String(),
        'hit': hit,
      });
      if (!hit) return;

      await _consider(ReviewMoment.correctAlert);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.review,
        'Alert hit check failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Asks the platform when [ReviewPromptPolicy] allows it, and records the ask either way it lands.
  Future<void> _consider(ReviewMoment moment) async {
    SdLogger.action(LogTagConstant.review, 'Review moment', moment.name);
    try {
      final DateTime now = DateTime.now().toUtc();
      final ReviewPromptState state = await _ref
          .read(reviewPromptStoreProvider)
          .read();
      final bool allowed = _policy.shouldAsk(state, now: now);

      SdLogger.info(LogTagConstant.review, 'Review prompt considered', {
        'moment': moment.name,
        'askCount': state.askCount,
        'lastAskedAt': state.lastAskedAt?.toIso8601String(),
        'allowed': allowed,
      });
      if (!allowed) return;

      final bool asked = await _ref.read(reviewPrompterProvider).request();

      // Record only prompts the platform actually displayed.
      if (!asked) return;

      await _ref.read(reviewPromptStoreProvider).recordAsked(now);
      AppAnalytics.logReviewPromptRequested(moment: moment.name);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.review,
        'Review prompt failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'moment': moment.name},
      );
    }
  }
}
