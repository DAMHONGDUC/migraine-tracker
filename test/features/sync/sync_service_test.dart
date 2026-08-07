import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_reminder_repository.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication_reminder.dart';
import 'package:migraine_tracker/features/sync/domain/entities/encrypted_payload.dart';
import 'package:migraine_tracker/features/sync/domain/entities/encrypted_record.dart';
import 'package:migraine_tracker/features/sync/domain/entities/sync_collection.dart';
import 'package:migraine_tracker/features/sync/domain/entities/sync_outcome.dart';
import 'package:migraine_tracker/features/sync/domain/services/attack_payload_codec.dart';
import 'package:migraine_tracker/features/sync/domain/services/medication_payload_codec.dart';
import 'package:migraine_tracker/features/sync/domain/services/medication_reminder_payload_codec.dart';
import 'package:migraine_tracker/features/sync/domain/services/sync_service.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

import '../../helpers/sync_fakes.dart';

void main() {
  late AppDatabase db;
  late DriftAttackRepository attacks;
  late DriftMedicationRepository medications;
  late DriftMedicationReminderRepository reminders;
  late FakeRemoteSyncRepository remote;
  late FakeSyncCursorStore cursor;
  late SyncService service;
  late int rescheduleCalls;

  const String uid = 'user-1';
  const String key = 'ZmFrZS1zeW5jLWtleS0zMi1ieXRlcy1sb25nLXh4eHg=';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    attacks = DriftAttackRepository(db);
    medications = DriftMedicationRepository(db);
    reminders = DriftMedicationReminderRepository(db);
    remote = FakeRemoteSyncRepository();
    cursor = FakeSyncCursorStore();
    rescheduleCalls = 0;
    service = syncServiceOver(
      db,
      remote: remote,
      cursor: cursor,
      onRemindersPulled: () async => rescheduleCalls++,
    );
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

  /// Puts a record on the server as another device would have, without
  /// counting as a write this device made.
  Future<void> seedRemote(
    SyncCollection collection,
    EncryptedRecord record,
  ) async {
    await remote.put(uid, collection, record);
    remote.putCount = 0;
  }

  group('attacks', () {
    test('go up encrypted and stop being owed', () async {
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

      final SyncOutcome outcome = await service.sync(uid);

      expect(outcome.pushed, 1);
      // Hard rule 1: nothing about the attack may reach the server in clear.
      final EncryptedRecord stored = remote.of(SyncCollection.attacks).values.single;
      expect(stored.payload!.ciphertext, isNot(contains('Sumatriptan')));
      expect(await service.sync(uid), isA<SyncOutcome>());
      expect(remote.putCount, 1);
    });

    test('come down from another device', () async {
      await seedRemote(
        SyncCollection.attacks,
        await encryptedFor(
          'r1',
          attack('r1'),
          const AttackPayloadCodec(),
          DateTime.utc(2026, 8),
          key,
        ),
      );

      final SyncOutcome outcome = await service.sync(uid);

      expect(outcome.pulled, 1);
      expect((await attacks.watchAll().first).single.id, 'r1');
      // What came down must not be pushed straight back.
      expect(remote.putCount, 0);
    });
  });

  group('medications', () {
    test('go up and come back down', () async {
      await medications.upsert(
        Medication(id: 'm1', name: 'Ibuprofen', createdAt: DateTime.utc(2026)),
      );

      expect((await service.sync(uid)).pushed, 1);

      final EncryptedRecord stored =
          remote.of(SyncCollection.medications).values.single;
      // The name is health data and never leaves in clear (hard rule 1).
      expect(stored.payload!.ciphertext, isNot(contains('Ibuprofen')));
    });

    test('a name arriving from another device wins when it is newer', () async {
      await medications.upsert(const Medication(id: 'm1', name: 'Ibuprofen'));
      await service.sync(uid);

      await seedRemote(
        SyncCollection.medications,
        await encryptedFor(
          'm1',
          const Medication(id: 'm1', name: 'Naproxen'),
          const MedicationPayloadCodec(),
          DateTime.utc(2030),
          key,
        ),
      );
      await service.sync(uid);

      expect((await medications.getAll()).single.name, 'Naproxen');
    });

    test('deleting one also owes the server its reminders', () async {
      await medications.upsert(const Medication(id: 'm1', name: 'Ibuprofen'));
      await reminders.upsert(
        const MedicationReminder(id: 'r1', medicationId: 'm1', minuteOfDay: 480),
      );
      await service.sync(uid);

      await medications.deleteById('m1');
      await service.sync(uid);

      // The FK cascade removes the reminder on every device that pulls the
      // medication's deletion, but the server's copy belongs to no cascade.
      expect(remote.of(SyncCollection.medications)['m1']!.isDeleted, isTrue);
      expect(
        remote.of(SyncCollection.medicationReminders)['r1']!.isDeleted,
        isTrue,
      );
    });
  });

  group('reminders', () {
    Future<void> seedReminderPair() async {
      await seedRemote(
        SyncCollection.medications,
        await encryptedFor(
          'm1',
          const Medication(id: 'm1', name: 'Ibuprofen'),
          const MedicationPayloadCodec(),
          DateTime.utc(2026, 8),
          key,
        ),
      );
      await seedRemote(
        SyncCollection.medicationReminders,
        await encryptedFor(
          'r1',
          const MedicationReminder(
            id: 'r1',
            medicationId: 'm1',
            minuteOfDay: 480,
          ),
          const MedicationReminderPayloadCodec(),
          DateTime.utc(2026, 8),
          key,
        ),
      );
    }

    test('arrive after the medication they belong to', () async {
      await seedReminderPair();

      await service.sync(uid);

      // Medications sync first for exactly this reason: the other order hits
      // a foreign key that is not there yet.
      final views = await reminders.watchAll().first;
      expect(views.single.medicationName, 'Ibuprofen');
      expect(views.single.reminder.minuteOfDay, 480);
    });

    test('are re-scheduled once they land', () async {
      await seedReminderPair();

      await service.sync(uid);

      // The row travels; the OS notification does not. Without this the
      // reminder would sit in the list and never fire.
      expect(rescheduleCalls, 1);
    });

    test('nothing is re-scheduled when none came down', () async {
      await attacks.insert(attack('a1'));

      await service.sync(uid);

      expect(rescheduleCalls, 0);
    });

    test('one whose medication is missing is held back, not lost', () async {
      await seedRemote(
        SyncCollection.medicationReminders,
        await encryptedFor(
          'r1',
          const MedicationReminder(
            id: 'r1',
            medicationId: 'gone',
            minuteOfDay: 480,
          ),
          const MedicationReminderPayloadCodec(),
          DateTime.utc(2026, 8),
          key,
        ),
      );

      // Skipped rather than crashing on the foreign key.
      expect((await service.sync(uid)).pulled, 0);
      expect(await reminders.watchAll().first, isEmpty);
    });
  });

  group('a pass that goes wrong', () {
    test('a payload it cannot open is counted and stepped over', () async {
      await seedRemote(
        SyncCollection.attacks,
        EncryptedRecord(
          id: 'broken',
          updatedAt: DateTime.utc(2026, 8),
          payload: const EncryptedPayload(
            ciphertext: 'bm90LWEtcGF5bG9hZA==',
            nonce: 'bm90LWEtbm9uY2U=',
            mac: 'bm90LWEtbWFj',
          ),
        ),
      );
      await seedRemote(
        SyncCollection.attacks,
        await encryptedFor(
          'good',
          attack('good'),
          const AttackPayloadCodec(),
          DateTime.utc(2026, 9),
          key,
        ),
      );

      final SyncOutcome outcome = await service.sync(uid);

      // One bad record must never wedge every later one behind it.
      expect(outcome.unreadable, 1);
      expect(outcome.pulled, 1);
      expect((await attacks.watchAll().first).map((a) => a.id), ['good']);
    });

    test('an upload that fails leaves the record owed', () async {
      await attacks.insert(attack('a1'));
      remote.failNextPut = true;

      await expectLater(service.sync(uid), throwsA(isA<Exception>()));

      // Marking it synced before the server confirmed would lose it outright.
      expect((await service.sync(uid)).pushed, 1);
    });

    test('a pull that throws leaves the cursor where it was', () async {
      remote.failNextQuery = true;

      await expectLater(service.sync(uid), throwsA(isA<Exception>()));

      expect(await cursor.lastPulledAt(uid, SyncCollection.medications), isNull);
    });
  });

  group('account lifecycle', () {
    test('the first pull is only first once', () async {
      expect(await service.isFirstPull(uid), isTrue);

      await service.sync(uid);

      expect(await service.isFirstPull(uid), isFalse);
    });

    test('the wipe clears every collection and the cursor', () async {
      await attacks.insert(attack('a1'));
      await medications.upsert(const Medication(id: 'm1', name: 'Ibuprofen'));
      await service.sync(uid);
      expect(remote.documents, hasLength(2));

      await service.wipeRemote(uid);

      expect(remote.documents, isEmpty);
      expect(await cursor.lastPulledAt(uid, SyncCollection.attacks), isNull);
    });

    test('signing out keeps local data and forgets the cursor', () async {
      await attacks.insert(attack('a1'));
      await service.sync(uid);

      await service.onSignedOut();

      expect(await cursor.lastPulledAt(uid, SyncCollection.attacks), isNull);
      // Signing out is not a delete: local data is the source of truth.
      expect(await attacks.watchAll().first, hasLength(1));
    });
  });

  group('progress', () {
    test('climbs from 0 to 1 and never goes backwards', () async {
      await attacks.insert(attack('a1'));
      await medications.upsert(const Medication(id: 'm1', name: 'Ibuprofen'));
      final List<double> seen = <double>[];

      await service.sync(uid, onProgress: seen.add);

      expect(seen.first, 0);
      expect(seen.last, 1);
      // A bar that jumps backwards reads as a bug even when the sync is fine,
      // which is why progress counts fixed steps and not records discovered.
      for (int i = 1; i < seen.length; i++) {
        expect(seen[i], greaterThanOrEqualTo(seen[i - 1]), reason: 'step $i');
      }
    });

    test('reaches 1 even with nothing to move', () async {
      final List<double> seen = <double>[];

      await service.sync(uid, onProgress: seen.add);

      // An empty account must not leave the row stuck partway.
      expect(seen.last, 1);
    });

    test('is reported without a callback too', () async {
      await attacks.insert(attack('a1'));

      // The callback is optional; every other caller passes nothing.
      await expectLater(service.sync(uid), completes);
    });
  });
}
