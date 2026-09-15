import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/constants/review_prompt_constant.dart';
import 'package:migraine_tracker/features/review/domain/entities/review_prompt_state.dart';
import 'package:migraine_tracker/features/review/domain/services/review_prompt_policy.dart';

void main() {
  const ReviewPromptPolicy policy = ReviewPromptPolicy();
  final DateTime now = DateTime.utc(2026, 8, 16, 9);

  group('shouldAsk', () {
    test('asks on the first moment of a fresh install', () {
      expect(policy.shouldAsk(ReviewPromptState.never, now: now), isTrue);
    });

    test('never asks past the lifetime cap', () {
      final ReviewPromptState state = ReviewPromptState(
        askCount: ReviewPromptConstant.maxAsks,
        // Long enough ago that only the cap can be what stops it.
        lastAskedAt: now.subtract(const Duration(days: 900)),
      );

      expect(policy.shouldAsk(state, now: now), isFalse);
    });

    test('holds a second ask back until the gap has passed', () {
      final ReviewPromptState state = ReviewPromptState(
        askCount: 1,
        lastAskedAt: now.subtract(
          ReviewPromptConstant.minGapBetweenAsks - const Duration(days: 1),
        ),
      );

      expect(policy.shouldAsk(state, now: now), isFalse);
    });

    test('asks again the moment the gap is exactly met', () {
      final ReviewPromptState state = ReviewPromptState(
        askCount: 1,
        lastAskedAt: now.subtract(ReviewPromptConstant.minGapBetweenAsks),
      );

      expect(policy.shouldAsk(state, now: now), isTrue);
    });

    /// A stored timestamp read back as local time must not shift the gap by the device's offset.
    test('compares in UTC whatever zone the stamp arrives in', () {
      final ReviewPromptState state = ReviewPromptState(
        askCount: 1,
        lastAskedAt: now
            .subtract(ReviewPromptConstant.minGapBetweenAsks)
            .toLocal(),
      );

      expect(policy.shouldAsk(state, now: now.toLocal()), isTrue);
    });
  });

  group('isAlertHit', () {
    test('counts an attack inside the window', () {
      expect(
        policy.isAlertHit(
          alertAt: now,
          attackAt: now.add(const Duration(hours: 3)),
        ),
        isTrue,
      );
    });

    test('counts the last minute of the window', () {
      expect(
        policy.isAlertHit(
          alertAt: now,
          attackAt: now.add(ReviewPromptConstant.alertHitWindow),
        ),
        isTrue,
      );
    });

    test(
      'drops an attack past the window — that is another day of weather',
      () {
        expect(
          policy.isAlertHit(
            alertAt: now,
            attackAt: now.add(
              ReviewPromptConstant.alertHitWindow + const Duration(minutes: 1),
            ),
          ),
          isFalse,
        );
      },
    );

    test('never counts an attack the alert came after', () {
      expect(
        policy.isAlertHit(
          alertAt: now,
          attackAt: now.subtract(const Duration(minutes: 5)),
        ),
        isFalse,
      );
    });
  });
}
