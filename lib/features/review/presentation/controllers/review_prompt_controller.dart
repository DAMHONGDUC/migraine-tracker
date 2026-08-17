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
///
/// **Every entry point is best-effort and must be called unawaited.** A
/// review prompt is the least important thing happening on the screen it
/// interrupts, so nothing here rethrows: a failure is logged and the moment
/// is dropped, exactly like the weather backfill (hard rule 4).
class ReviewPromptController {
  const ReviewPromptController(this._ref);

  final Ref _ref;

  static const ReviewPromptPolicy _policy = ReviewPromptPolicy();

  /// A doctor report reached the share sheet — the PDF export's whole point.
  Future<void> onDoctorReportShared() => _consider(ReviewMoment.doctorReport);

  /// An attack was logged at [attackAt].
  ///
  /// A moment only when a pressure alert came first and close enough to have
  /// predicted it: the alert being right is what the subscription is for, and
  /// an attack on a quiet day says nothing about the app.
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

  /// Asks the platform when [ReviewPromptPolicy] allows it, and records the
  /// ask either way it lands.
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

      // Only a real ask is recorded: a platform with no review flow never
      // showed anything, and spending one of three on it would silence the
      // next moment for four months.
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
