import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_sync_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack_sync_record.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

void main() {
  late AppDatabase db;
  late DriftAttackRepository attacks;
  late DriftAttackSyncRepository sync;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    attacks = DriftAttackRepository(db);
    sync = DriftAttackSyncRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Attack attack(String id, {int intensity = 5, WeatherSnapshot? weather}) =>
      Attack(
        id: id,
        startedAt: DateTime.utc(2026, 7, 1, 8, 30),
        intensity: intensity,
        location: HeadLocation.right,
        weather: weather,
      );

  WeatherSnapshot snapshot() => WeatherSnapshot(
    capturedAt: DateTime.utc(2026, 7, 1, 8),
    pressureHpa: 1008.2,
    pressureDelta24hHpa: -6,
  );

  /// Pushes everything currently pending, as the sync service would.
  Future<void> pushAll() async {
    for (final AttackSyncRecord record in await sync.pendingChanges()) {
      if (record.isDeleted) {
        await sync.clearTombstone(record.id);
      } else {
        await sync.markSynced(record.id, record.revision);
      }
    }
  }

  group('what is owed to the server', () {
    test('a freshly logged attack is pending, and stops being after a push', () async {
      await attacks.insert(attack('a1'));

      final pending = await sync.pendingChanges();
      expect(pending.map((r) => r.id), ['a1']);
      expect(pending.single.isDeleted, isFalse);
      expect(pending.single.attack?.intensity, 5);

      await pushAll();
      expect(await sync.pendingChanges(), isEmpty);
    });

    test('editing a synced attack makes it pending again', () async {
      await attacks.insert(attack('a1'));
      await pushAll();

      await attacks.updateCore(
        'a1',
        intensity: 9,
        location: HeadLocation.back,
        medicationName: null,
      );

      final pending = await sync.pendingChanges();
      expect(pending.single.attack?.intensity, 9);
    });

    test('a backfilled weather snapshot makes the attack pending again', () async {
      await attacks.insert(attack('a1'));
      await pushAll();

      await attacks.attachWeather('a1', snapshot());

      // The snapshot travels inside the attack's payload, so without this the
      // server would never learn about it.
      final pending = await sync.pendingChanges();
      expect(pending.single.attack?.weather, snapshot());
    });

    test('a deletion is pending as a tombstone carrying no attack', () async {
      await attacks.insert(attack('a1', weather: snapshot()));
      await pushAll();

      await attacks.deleteById('a1');

      final pending = await sync.pendingChanges();
      expect(pending.single.id, 'a1');
      expect(pending.single.isDeleted, isTrue);
      expect(pending.single.attack, isNull);
    });

    test('deleting keeps nothing but the id on this device', () async {
      await attacks.insert(attack('a1', weather: snapshot()));

      await attacks.deleteById('a1');

      // The user pressed delete: no intensity, note or snapshot may outlive it.
      expect(await db.select(db.attacks).get(), isEmpty);
      expect(await db.select(db.weatherSnapshots).get(), isEmpty);
      expect((await db.select(db.attackTombstones).get()).single.id, 'a1');
    });

    test('an edit and a deletion are both owed, untouched rows are not', () async {
      await attacks.insert(attack('a1'));
      await attacks.insert(attack('a2'));
      await attacks.insert(attack('a3'));
      await pushAll();

      await attacks.deleteById('a2');
      await attacks.updateCore(
        'a1',
        intensity: 2,
        location: HeadLocation.left,
        medicationName: null,
      );

      final pending = await sync.pendingChanges();
      expect(pending.map((r) => r.id), ['a1', 'a2']);
      expect(pending.map((r) => r.isDeleted), [false, true]);
    });

    test('the GDPR wipe leaves nothing owed', () async {
      await attacks.insert(attack('a1'));
      await pushAll();
      await attacks.deleteById('a1');

      await attacks.deleteAll();

      // The whole remote collection goes in the same pass, so a tombstone
      // left here would be a deletion owed to a server that no longer has it.
      expect(await sync.pendingChanges(), isEmpty);
    });
  });

  group('an edit landing mid-push', () {
    test('stays pending rather than being marked clean', () async {
      await attacks.insert(attack('a1'));
      final AttackSyncRecord inFlight = (await sync.pendingChanges()).single;

      await attacks.updateCore(
        'a1',
        intensity: 10,
        location: HeadLocation.front,
        medicationName: null,
      );
      // The server acknowledges the version we sent, not the newer one.
      await sync.markSynced(inFlight.id, inFlight.revision);

      final pending = await sync.pendingChanges();
      expect(pending.single.attack?.intensity, 10);
    });
  });

  group('applying what came down', () {
    test('an unknown attack is inserted, already in step', () async {
      final applied = await sync.applyRemote(
        attack('remote', weather: snapshot()),
        DateTime.utc(2026, 7, 2),
      );

      expect(applied, isTrue);
      expect((await attacks.watchAll().first).single.weather, snapshot());
      expect(await sync.pendingChanges(), isEmpty);
    });

    test('a newer remote copy overwrites the local one', () async {
      await attacks.insert(attack('a1'));
      await pushAll();

      final applied = await sync.applyRemote(
        attack('a1', intensity: 8),
        DateTime.now().toUtc().add(const Duration(minutes: 5)),
      );

      expect(applied, isTrue);
      expect((await attacks.watchAll().first).single.intensity, 8);
    });

    test('a stale remote copy never clobbers a newer local edit', () async {
      await attacks.insert(attack('a1', intensity: 3));

      final applied = await sync.applyRemote(
        attack('a1', intensity: 8),
        DateTime.utc(2020),
      );

      expect(applied, isFalse);
      expect((await attacks.watchAll().first).single.intensity, 3);
      // Still ours to push — the server's copy is the one that is behind.
      expect(await sync.pendingChanges(), hasLength(1));
    });

    test('a tie goes to the server, so two devices converge', () async {
      await attacks.insert(attack('a1', intensity: 3));
      final DateTime localTime = (await sync.pendingChanges()).single.updatedAt;

      expect(await sync.applyRemote(attack('a1', intensity: 8), localTime), isTrue);
      expect((await attacks.watchAll().first).single.intensity, 8);
    });

    test('a remote deletion removes the attack and owes nothing back', () async {
      await attacks.insert(attack('a1'));
      await pushAll();

      final applied = await sync.applyRemoteDeletion(
        'a1',
        DateTime.now().toUtc().add(const Duration(minutes: 5)),
      );

      expect(applied, isTrue);
      expect(await attacks.watchAll().first, isEmpty);
      // The server is the one that told us, so it already knows.
      expect(await sync.pendingChanges(), isEmpty);
    });

    test('a stale remote deletion loses to a newer local edit', () async {
      await attacks.insert(attack('a1'));

      final applied = await sync.applyRemoteDeletion('a1', DateTime.utc(2020));

      expect(applied, isFalse);
      expect((await attacks.watchAll().first).map((a) => a.id), ['a1']);
    });
  });

  group('rows logged before sync existed', () {
    /// A v5-era row: no updatedAt, no syncedAt.
    Future<void> insertLegacy(String id) => db
        .into(db.attacks)
        .insert(
          AttacksCompanion.insert(
            id: id,
            startedAt: DateTime.utc(2025, 3, 4),
            intensity: 6,
            location: HeadLocation.left,
          ),
        );

    test('are pending, dated by when they were logged', () async {
      await insertLegacy('old');

      final pending = await sync.pendingChanges();
      expect(pending.single.id, 'old');
      expect(pending.single.updatedAt, DateTime.utc(2025, 3, 4));
    });

    test('settle after one push instead of re-pushing forever', () async {
      await insertLegacy('old');

      await pushAll();

      expect(await sync.pendingChanges(), isEmpty);
    });
  });

  test('re-using a deleted id drops its stale tombstone', () async {
    await attacks.insert(attack('a1'));
    await attacks.deleteById('a1');

    await attacks.insert(attack('a1'));

    final pending = await sync.pendingChanges();
    expect(pending, hasLength(1));
    expect(pending.single.isDeleted, isFalse);
  });
}
