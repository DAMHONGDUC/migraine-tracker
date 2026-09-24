import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/auth/providers.dart';
import 'package:migraine_tracker/features/sync/domain/entities/sync_status.dart';
import 'package:migraine_tracker/features/sync/providers.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/sync_fakes.dart';

/// What the Settings sync card reads: progress while a push runs, and what is still owed once it stops.
void main() {
  late AppDatabase db;
  late DriftAttackRepository attacks;
  late FakeRemoteSyncRepository remote;
  late FakeSyncCursorStore cursor;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    attacks = DriftAttackRepository(db);
    remote = FakeRemoteSyncRepository();
    cursor = FakeSyncCursorStore();
    container = ProviderContainer(
      overrides: [
        syncServiceProvider.overrideWithValue(
          syncServiceOver(db, remote: remote, cursor: cursor),
        ),
        syncCursorStoreProvider.overrideWithValue(cursor),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(signedIn: true),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Attack attack(String id) => Attack(
    id: id,
    startedAt: DateTime.utc(2026, 7, 1, 8, 30),
    intensity: 5,
    regions: const <HeadRegion>[HeadRegion.templeR],
  );

  test('nothing is counted before the first push', () {
    expect(container.read(syncControllerProvider).pending, isNull);
  });

  test('a push shows its progress, then settles on nothing owed', () async {
    await attacks.insert(attack('a1'));
    await attacks.insert(attack('a2'));
    final List<SyncStatus> seen = <SyncStatus>[];

    container.listen<SyncStatus>(
      syncControllerProvider,
      (_, SyncStatus next) => seen.add(next),
    );
    await container.read(syncControllerProvider.notifier).pushPending();

    expect(
      seen.where((SyncStatus s) => s.isSyncing).map((s) => (s.done, s.total)),
      <(int, int)>[(0, 2), (1, 2), (2, 2)],
    );
    final SyncStatus last = container.read(syncControllerProvider);

    expect(last.isSyncing, isFalse);
    expect(last.pending, 0);
    expect(last.total, 0, reason: 'progress is cleared once it stops');
  });

  test('an offline push leaves the owed count on the card', () async {
    await attacks.insert(attack('a1'));
    remote.failNextPut = true;

    await container.read(syncControllerProvider.notifier).pushPending();

    final SyncStatus status = container.read(syncControllerProvider);

    expect(status.phase, SyncPhase.failed);
    expect(status.pending, 1);
  });

  test(
    'the dev full sync re-reads the account, so its bar has work to show',
    () async {
      await attacks.insert(attack('a1'));
      await attacks.insert(attack('a2'));
      // A normal pass: both go up, and the cursor moves past them.
      await container.read(syncControllerProvider.notifier).sync();
      final List<SyncStatus> seen = <SyncStatus>[];

      container.listen<SyncStatus>(
        syncControllerProvider,
        (_, SyncStatus next) => seen.add(next),
      );
      final bool synced = await container
          .read(syncControllerProvider.notifier)
          .syncEverythingNow();

      expect(synced, isTrue);
      // Nothing new anywhere, and still the two records come back through the pull.
      expect(seen.map((SyncStatus s) => s.total), contains(2));
      expect(container.read(syncControllerProvider).isSyncing, isFalse);
    },
  );
}
