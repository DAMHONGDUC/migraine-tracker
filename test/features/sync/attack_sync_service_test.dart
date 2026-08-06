import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_sync_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/sync/data/services/aes_gcm_attack_cipher.dart';
import 'package:migraine_tracker/features/sync/domain/entities/encrypted_attack.dart';
import 'package:migraine_tracker/features/sync/domain/entities/encrypted_payload.dart';
import 'package:migraine_tracker/features/sync/domain/entities/sync_outcome.dart';
import 'package:migraine_tracker/features/sync/domain/services/attack_sync_service.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

import '../../helpers/sync_fakes.dart';

void main() {
  late AppDatabase db;
  late DriftAttackRepository attacks;
  late DriftAttackSyncRepository local;
  late FakeRemoteAttackRepository remote;
  late FakeSyncKeyRepository keys;
  late FakeSyncCursorStore cursor;
  late AttackSyncService service;

  const String uid = 'user-1';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    attacks = DriftAttackRepository(db);
    local = DriftAttackSyncRepository(db);
    remote = FakeRemoteAttackRepository();
    keys = FakeSyncKeyRepository();
    cursor = FakeSyncCursorStore();
    service = AttackSyncService(
      local,
      remote,
      keys,
      cursor,
      const AesGcmAttackCipher(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Attack attack(
    String id, {
    int intensity = 5,
    WeatherSnapshot? weather,
    DateTime? startedAt,
  }) => Attack(
    id: id,
    startedAt: startedAt ?? DateTime.utc(2026, 7, 1, 8, 30),
    intensity: intensity,
    location: HeadLocation.right,
    weather: weather,
  );

  WeatherSnapshot snapshot() => WeatherSnapshot(
    capturedAt: DateTime.utc(2026, 7, 1, 8),
    pressureHpa: 1008.2,
    pressureDelta24hHpa: -6,
  );

  /// Puts an attack on the server as another device would have, without
  /// counting as a write this device made.
  Future<void> seedRemote(Attack value, DateTime updatedAt) async {
    await remote.put(uid, await encryptedFor(value, updatedAt, keys.key));
    remote.putCount = 0;
  }

  group('push', () {
    test('uploads a logged attack and stops owing it', () async {
      await attacks.insert(attack('a1', weather: snapshot()));

      final SyncOutcome outcome = await service.sync(uid);

      expect(outcome.pushed, 1);
      expect(remote.documents, hasLength(1));
      expect(await local.pendingChanges(), isEmpty);
    });

    test('sends nothing readable to the server', () async {
      await attacks.insert(
        Attack(
          id: 'a1',
          startedAt: DateTime.utc(2026, 7, 1),
          intensity: 9,
          location: HeadLocation.left,
          medicationName: 'Sumatriptan',
          notes: 'woke up with it',
        ),
      );

      await service.sync(uid);

      // Hard rule 1: nothing about the attack may reach Firestore in clear.
      final EncryptedAttack stored = remote.documents.values.single;
      expect(stored.payload, isNotNull);
      expect(stored.payload!.ciphertext, isNot(contains('Sumatriptan')));
      expect(stored.payload!.ciphertext, isNot(contains('woke up')));
    });

    test('uploads a deletion, then forgets the tombstone', () async {
      await attacks.insert(attack('a1'));
      await service.sync(uid);

      await attacks.deleteById('a1');
      await service.sync(uid);

      expect(remote.documents['a1']!.isDeleted, isTrue);
      // The ciphertext must not survive the deletion that removed it.
      expect(remote.documents['a1']!.payload, isNull);
      expect(await local.pendingChanges(), isEmpty);
    });

    test('a failed upload leaves the attack owed for next time', () async {
      await attacks.insert(attack('a1'));
      remote.failNextPut = true;

      await expectLater(service.sync(uid), throwsA(isA<Exception>()));

      // Marking it synced before the server confirmed would lose it outright.
      expect(await local.pendingChanges(), hasLength(1));
      expect(remote.documents, isEmpty);
    });

    test('pushes nothing twice across repeated syncs', () async {
      await attacks.insert(attack('a1'));

      await service.sync(uid);
      final SyncOutcome second = await service.sync(uid);

      expect(second.pushed, 0);
      expect(remote.putCount, 1);
    });
  });

  group('pull', () {
    test('brings down an attack this device has never seen', () async {
      await seedRemote(attack('r1', weather: snapshot()), DateTime.utc(2026, 8));

      final SyncOutcome outcome = await service.sync(uid);

      expect(outcome.pulled, 1);
      final Attack pulled = (await attacks.watchAll().first).single;
      expect(pulled.id, 'r1');
      expect(pulled.weather, snapshot());
    });

    test('what came down is not pushed straight back', () async {
      await seedRemote(attack('r1'), DateTime.utc(2026, 8));

      await service.sync(uid);

      expect(await local.pendingChanges(), isEmpty);
      expect(remote.putCount, 0);
    });

    test('only asks for what changed after the last pull', () async {
      await seedRemote(
        attack('r1', startedAt: DateTime.utc(2026, 7, 1)),
        DateTime.utc(2026, 8),
      );
      await service.sync(uid);

      await seedRemote(
        attack('r2', startedAt: DateTime.utc(2026, 7, 2)),
        DateTime.utc(2026, 9),
      );
      final SyncOutcome second = await service.sync(uid);

      expect(second.pulled, 1);
      expect(remote.lastSince, DateTime.utc(2026, 8));
      expect((await attacks.watchAll().first).map((a) => a.id), ['r2', 'r1']);
    });

    test('a remote deletion removes the local attack', () async {
      await attacks.insert(attack('a1'));
      await service.sync(uid);

      await remote.put(
        uid,
        EncryptedAttack(id: 'a1', updatedAt: DateTime.utc(2026, 9)),
      );
      await service.sync(uid);

      expect(await attacks.watchAll().first, isEmpty);
    });

    test('a payload it cannot open is counted and stepped over', () async {
      await remote.put(
        uid,
        EncryptedAttack(
          id: 'broken',
          updatedAt: DateTime.utc(2026, 8),
          payload: const EncryptedPayload(
            ciphertext: 'bm90LWEtcGF5bG9hZA==',
            nonce: 'bm90LWEtbm9uY2U=',
            mac: 'bm90LWEtbWFj',
          ),
        ),
      );
      await seedRemote(attack('good'), DateTime.utc(2026, 9));

      final SyncOutcome outcome = await service.sync(uid);

      // One bad record must never wedge every later one behind it.
      expect(outcome.unreadable, 1);
      expect(outcome.pulled, 1);
      expect((await attacks.watchAll().first).map((a) => a.id), ['good']);
    });

    test('a pull that throws leaves the cursor where it was', () async {
      await seedRemote(attack('r1'), DateTime.utc(2026, 8));
      remote.failNextQuery = true;

      await expectLater(service.sync(uid), throwsA(isA<Exception>()));

      expect(await cursor.lastPulledAt(uid), isNull);
    });
  });

  group('two devices', () {
    test('the newer edit wins, whichever side made it', () async {
      await attacks.insert(attack('a1', intensity: 3));
      await service.sync(uid);

      await seedRemote(attack('a1', intensity: 8), DateTime.utc(2030));
      await service.sync(uid);

      expect((await attacks.watchAll().first).single.intensity, 8);
    });

    test('a stale remote copy never overwrites a newer local edit', () async {
      await attacks.insert(attack('a1', intensity: 3));
      await seedRemote(attack('a1', intensity: 8), DateTime.utc(2020));

      await service.sync(uid);

      expect((await attacks.watchAll().first).single.intensity, 3);
    });

    test('signing into an account merges this device history in', () async {
      await attacks.insert(attack('local'));
      await seedRemote(attack('remote'), DateTime.utc(2026, 8));

      final SyncOutcome outcome = await service.sync(uid);

      // Neither side may vanish just because the other existed first.
      expect(outcome.pushed, 1);
      expect(outcome.pulled, 1);
      expect(
        (await attacks.watchAll().first).map((a) => a.id),
        containsAll(<String>['local', 'remote']),
      );
    });
  });

  group('interrupted mid-sync', () {
    test('resuming re-pushes rather than losing or duplicating', () async {
      await attacks.insert(attack('a1'));
      await attacks.insert(attack('a2'));
      remote.failPutAfter = 1;

      await expectLater(service.sync(uid), throwsA(isA<Exception>()));
      expect(remote.documents, hasLength(1));

      remote.failPutAfter = null;
      await service.sync(uid);

      expect(remote.documents, hasLength(2));
      expect(await local.pendingChanges(), isEmpty);
    });
  });

  group('account lifecycle', () {
    test('the first pull is only first once', () async {
      expect(await service.isFirstPull(uid), isTrue);

      await service.sync(uid);

      expect(await service.isFirstPull(uid), isFalse);
    });

    test('signing out forgets the key and the cursor, keeping attacks', () async {
      await attacks.insert(attack('a1'));
      await service.sync(uid);

      await service.onSignedOut();

      expect(keys.forgotten, isTrue);
      expect(await cursor.lastPulledAt(uid), isNull);
      // Signing out is not a delete: local data is the source of truth.
      expect(await attacks.watchAll().first, hasLength(1));
    });

    test('the wipe clears the server copy and the cursor', () async {
      await attacks.insert(attack('a1'));
      await service.sync(uid);

      await service.wipeRemote(uid);

      expect(remote.documents, isEmpty);
      expect(await cursor.lastPulledAt(uid), isNull);
    });
  });
}
