import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/sync_constant.dart';
import 'package:migraine_tracker/features/auth/providers.dart';
import 'package:migraine_tracker/features/sync/domain/entities/sync_outcome.dart';
import 'package:migraine_tracker/features/sync/domain/enums/sync_trigger.dart';
import 'package:migraine_tracker/features/sync/domain/repositories/sync_cursor_store.dart';
import 'package:migraine_tracker/features/sync/domain/services/sync_service.dart';
import 'package:migraine_tracker/features/sync/presentation/controllers/sync_controller.dart';
import 'package:migraine_tracker/features/sync/providers.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/sync_fakes.dart';

/// Counts passes without running one: the cooldown decides whether
/// `SyncService.sync` is reached at all, which is the only thing under test.
class CountingSyncService implements SyncService {
  int passes = 0;

  @override
  Future<SyncOutcome> sync(
    String uid, {
    SyncProgressCallback? onProgress,
  }) async {
    passes++;
    return const SyncOutcome(pushed: 0, pulled: 0, unreadable: 0);
  }

  @override
  Future<bool> isFirstPull(String uid) async => false;

  @override
  Future<void> wipeRemote(String uid) async {}

  @override
  Future<void> onSignedOut() async {}
}

ProviderContainer containerWith(
  CountingSyncService service,
  SyncCursorStore cursor,
) {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      syncServiceProvider.overrideWithValue(service),
      syncCursorStoreProvider.overrideWithValue(cursor),
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(signedIn: true),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late CountingSyncService service;
  late FakeSyncCursorStore cursor;
  late ProviderContainer container;

  setUp(() {
    service = CountingSyncService();
    cursor = FakeSyncCursorStore();
    container = containerWith(service, cursor);
  });

  SyncController controller() =>
      container.read(syncControllerProvider.notifier);

  test('the first automatic pass runs — nothing has been synced yet', () async {
    await controller().sync();

    expect(service.passes, 1);
  });

  test('a second automatic pass inside the cooldown does nothing', () async {
    await controller().sync();
    await controller().sync();
    await controller().sync();

    // Ten app opens in ten minutes are one pass, which is the whole point.
    expect(service.passes, 1);
  });

  test('an automatic pass runs again once the cooldown has passed', () async {
    await controller().sync();
    await cursor.saveSyncedAt(
      'test-uid',
      DateTime.now().toUtc().subtract(
        SyncConstant.automaticCooldown + const Duration(minutes: 1),
      ),
    );

    await controller().sync();

    expect(service.passes, 2);
  });

  test('a manual pass is never held back', () async {
    await controller().sync();
    await controller().sync(trigger: SyncTrigger.manual);

    // The user is watching the screen for the answer.
    expect(service.passes, 2);
  });

  test('a just-logged attack is never held back', () async {
    await controller().sync();
    await controller().sync(trigger: SyncTrigger.record);

    // Hard rule 12: the record has to reach the server before the phone can
    // be lost.
    expect(service.passes, 2);
  });

  test('a failed pass is retried by the next open, not held off', () async {
    final FailingSyncService failing = FailingSyncService();
    final ProviderContainer failingContainer = ProviderContainer(
      overrides: [
        syncServiceProvider.overrideWithValue(failing),
        syncCursorStoreProvider.overrideWithValue(cursor),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(signedIn: true),
        ),
      ],
    );
    addTearDown(failingContainer.dispose);

    await failingContainer.read(syncControllerProvider.notifier).sync();
    await failingContainer.read(syncControllerProvider.notifier).sync();

    // The cooldown is stamped only on success, so both attempts got through.
    expect(failing.attempts, 2);
  });

  test(
    'another account syncs at once rather than inheriting the window',
    () async {
      await controller().sync();
      await cursor.clear();

      await controller().sync();

      expect(service.passes, 2);
    },
  );
}

/// Always throws, to prove a failed pass leaves no cooldown behind.
class FailingSyncService implements SyncService {
  int attempts = 0;

  @override
  Future<SyncOutcome> sync(
    String uid, {
    SyncProgressCallback? onProgress,
  }) async {
    attempts++;
    throw StateError('offline');
  }

  @override
  Future<bool> isFirstPull(String uid) async => false;

  @override
  Future<void> wipeRemote(String uid) async {}

  @override
  Future<void> onSignedOut() async {}
}
