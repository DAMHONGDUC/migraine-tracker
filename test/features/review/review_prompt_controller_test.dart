import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/review_prompt_constant.dart';
import 'package:migraine_tracker/features/notifications/domain/entities/app_notification.dart';
import 'package:migraine_tracker/features/notifications/domain/enums/notification_type.dart';
import 'package:migraine_tracker/features/notifications/domain/repositories/notification_repository.dart';
import 'package:migraine_tracker/features/notifications/providers.dart';
import 'package:migraine_tracker/features/review/domain/entities/review_prompt_state.dart';
import 'package:migraine_tracker/features/review/domain/repositories/review_prompt_store.dart';
import 'package:migraine_tracker/features/review/providers.dart';

import '../../helpers/review_fakes.dart';

/// In-memory prompt state. The prefs-backed one has its own concerns; this test is about what the controller does with what it reads.
class _FakeReviewPromptStore implements ReviewPromptStore {
  _FakeReviewPromptStore({this.state = ReviewPromptState.never, this.throws});

  ReviewPromptState state;

  /// When set, [read] throws it — a prompt must never break its caller.
  final Exception? throws;

  final List<DateTime> recorded = <DateTime>[];

  @override
  Future<ReviewPromptState> read() async {
    if (throws != null) throw throws!;
    return state;
  }

  @override
  Future<void> recordAsked(DateTime at) async {
    recorded.add(at);
    state = ReviewPromptState(askCount: state.askCount + 1, lastAskedAt: at);
  }
}

/// Answers only [latestPressureAlert]; anything else the controller touched would be a call it has no business making.
class _FakeNotificationRepository implements NotificationRepository {
  _FakeNotificationRepository({this.alert});

  AppNotification? alert;

  @override
  Future<AppNotification?> latestPressureAlert() async => alert;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  final DateTime attackAt = DateTime.utc(2026, 8, 16, 9);

  AppNotification alertAt(DateTime at) => AppNotification(
    id: 'pa:1',
    type: NotificationType.pressureAlert,
    occurredAt: at,
    pressureDropHpa: 6,
  );

  ({
    ProviderContainer container,
    _FakeReviewPromptStore store,
    RecordingReviewPrompter prompter,
    _FakeNotificationRepository notifications,
  })
  harness({
    ReviewPromptState state = ReviewPromptState.never,
    Exception? storeThrows,
    bool prompterAvailable = true,
    AppNotification? alert,
  }) {
    final _FakeReviewPromptStore store = _FakeReviewPromptStore(
      state: state,
      throws: storeThrows,
    );
    final RecordingReviewPrompter prompter = RecordingReviewPrompter(
      available: prompterAvailable,
    );
    final _FakeNotificationRepository notifications =
        _FakeNotificationRepository(alert: alert);
    final ProviderContainer container = ProviderContainer(
      overrides: [
        reviewPromptStoreProvider.overrideWithValue(store),
        reviewPrompterProvider.overrideWithValue(prompter),
        notificationRepositoryProvider.overrideWithValue(notifications),
      ],
    );

    addTearDown(container.dispose);

    return (
      container: container,
      store: store,
      prompter: prompter,
      notifications: notifications,
    );
  }

  group('onDoctorReportShared', () {
    test('asks and records the ask', () async {
      final harnessed = harness();

      await harnessed.container
          .read(reviewPromptControllerProvider)
          .onDoctorReportShared();

      expect(harnessed.prompter.requests, 1);
      expect(harnessed.store.recorded, hasLength(1));
    });

    test('stays quiet while the gap since the last ask is open', () async {
      final harnessed = harness(
        state: ReviewPromptState(
          askCount: 1,
          lastAskedAt: DateTime.now().toUtc(),
        ),
      );

      await harnessed.container
          .read(reviewPromptControllerProvider)
          .onDoctorReportShared();

      expect(harnessed.prompter.requests, isZero);
      expect(harnessed.store.recorded, isEmpty);
    });

    /// A device with no review flow — every simulator. Recording the ask would spend one of three on a dialog nobody could have seen.
    test('records nothing when the platform has no review flow', () async {
      final harnessed = harness(prompterAvailable: false);

      await harnessed.container
          .read(reviewPromptControllerProvider)
          .onDoctorReportShared();

      expect(harnessed.prompter.requests, 1);
      expect(harnessed.store.recorded, isEmpty);
    });

    test('swallows a failed read rather than breaking the share', () async {
      final harnessed = harness(storeThrows: Exception('prefs unavailable'));

      await expectLater(
        harnessed.container
            .read(reviewPromptControllerProvider)
            .onDoctorReportShared(),
        completes,
      );
      expect(harnessed.prompter.requests, isZero);
    });
  });

  group('onAttackLogged', () {
    test('asks when an alert came first and close enough', () async {
      final harnessed = harness(
        alert: alertAt(attackAt.subtract(const Duration(hours: 5))),
      );

      await harnessed.container
          .read(reviewPromptControllerProvider)
          .onAttackLogged(attackAt);

      expect(harnessed.prompter.requests, 1);
    });

    test('stays quiet when no alert was ever sent', () async {
      final harnessed = harness();

      await harnessed.container
          .read(reviewPromptControllerProvider)
          .onAttackLogged(attackAt);

      expect(harnessed.prompter.requests, isZero);
    });

    test('stays quiet when the alert is older than the window', () async {
      final harnessed = harness(
        alert: alertAt(
          attackAt.subtract(
            ReviewPromptConstant.alertHitWindow + const Duration(hours: 1),
          ),
        ),
      );

      await harnessed.container
          .read(reviewPromptControllerProvider)
          .onAttackLogged(attackAt);

      expect(harnessed.prompter.requests, isZero);
    });
  });
}
