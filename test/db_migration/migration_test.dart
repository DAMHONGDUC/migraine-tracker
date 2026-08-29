import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/notifications/domain/enums/notification_type.dart';

import 'generated/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('database is at schema version 15', () {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 15);
  });

  // Always migrates to AppDatabase.schemaVersion, so every starting point is validated against the current head, not the head at write time.
  test('migrates from v1 all the way to current', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, db.schemaVersion);
  });

  test('v1 data survives every migration', () async {
    final schema = await verifier.schemaAt(1);
    // Seed a medication under the v1 schema (raw sqlite3 execute).
    schema.rawDatabase.execute(
      "INSERT INTO medications (id, name) VALUES ('m1', 'Ibuprofen')",
    );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    final meds = await db.select(db.medications).get();
    expect(meds.map((m) => m.name), ['Ibuprofen']);
    expect(meds.single.createdAt, isNull);
  });

  test('migrates from v2 to v3 (adds medications.created_at)', () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, db.schemaVersion);
  });

  test('v2 medications survive v3 with an unknown createdAt', () async {
    final schema = await verifier.schemaAt(2);
    schema.rawDatabase.execute(
      "INSERT INTO medications (id, name) VALUES ('m1', 'Sumatriptan')",
    );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    final med = (await db.select(db.medications).get()).single;
    expect(med.name, 'Sumatriptan');
    // Their real creation date was never recorded — null says so instead of inventing the migration's timestamp and poisoning the date filter.
    expect(med.createdAt, isNull);
  });

  test('migrates from v3 to v4 (adds the export history table)', () async {
    final connection = await verifier.startAt(3);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, db.schemaVersion);

    // The new table is usable, and starts empty — exports made before v4 were never recorded, so there is nothing to backfill.
    expect(await db.select(db.exportRecords).get(), isEmpty);
  });

  test('v3 attacks survive v4', () async {
    final schema = await verifier.schemaAt(3);
    schema.rawDatabase.execute(
      'INSERT INTO attacks (id, started_at, intensity, location) '
      "VALUES ('a1', 1750000000, 7, 'left')",
    );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    expect((await db.select(db.attacks).get()).single.id, 'a1');
  });

  test('reminders still cascade after v3', () async {
    final schema = await verifier.schemaAt(2);
    schema.rawDatabase
      ..execute("INSERT INTO medications (id, name) VALUES ('m1', 'Ibuprofen')")
      ..execute(
        'INSERT INTO medication_reminders (id, medication_id, minute_of_day, '
        "enabled) VALUES ('r1', 'm1', 480, 1)",
      );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    // Rebuilding a table for addColumn can silently drop foreign keys.
    await (db.delete(db.medications)..where((m) => m.id.equals('m1'))).go();
    expect(await db.select(db.medicationReminders).get(), isEmpty);
  });

  test('migrates from v4 to v5 (adds attacks.exertion_level)', () async {
    final connection = await verifier.startAt(4);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, db.schemaVersion);
  });

  test('v4 attacks survive v5 with an unknown exertionLevel', () async {
    final schema = await verifier.schemaAt(4);
    schema.rawDatabase.execute(
      'INSERT INTO attacks (id, started_at, intensity, location) '
      "VALUES ('a1', 1750000000, 7, 'left')",
    );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    final attack = (await db.select(db.attacks).get()).single;
    expect(attack.id, 'a1');
    // Nobody reported exertion before this shipped — null says so instead of inventing an answer.
    expect(attack.exertionLevel, isNull);
  });

  test('migrates from v5 to v6 (adds sync state and tombstones)', () async {
    final connection = await verifier.startAt(5);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, db.schemaVersion);

    // Nothing was ever deleted before this shipped, so nothing to backfill.
    expect(await db.select(db.syncTombstones).get(), isEmpty);
  });

  test('v5 attacks survive v7 unsynced', () async {
    final schema = await verifier.schemaAt(5);
    schema.rawDatabase.execute(
      'INSERT INTO attacks (id, started_at, intensity, location) '
      "VALUES ('a1', 1750000000, 7, 'left')",
    );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    final attack = (await db.select(db.attacks).get()).single;
    expect(attack.id, 'a1');
    // - Nothing confirmed yet is what makes the first sync push these rows. - Null updatedAt says "never modified since logged", which is true.
    expect(attack.updatedAt, isNull);
    expect(attack.revision, 0);
    expect(attack.syncedRevision, isNull);
  });

  test('weather snapshots still cascade after v6', () async {
    final schema = await verifier.schemaAt(5);
    schema.rawDatabase
      ..execute(
        'INSERT INTO attacks (id, started_at, intensity, location) '
        "VALUES ('a1', 1750000000, 7, 'left')",
      )
      ..execute(
        'INSERT INTO weather_snapshots (attack_id, captured_at, pressure_hpa, '
        "pressure_delta24h_hpa) VALUES ('a1', 1750000000, 1010.0, -6.0)",
      );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    // Three addColumns rebuild the attacks table — that is where a foreign key gets silently dropped.
    await (db.delete(db.attacks)..where((a) => a.id.equals('a1'))).go();
    expect(await db.select(db.weatherSnapshots).get(), isEmpty);
  });

  test('migrates from v6 to v7 (medications and reminders sync too)', () async {
    final connection = await verifier.startAt(6);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, db.schemaVersion);
  });

  test('v6 medications survive v7 unsynced', () async {
    final schema = await verifier.schemaAt(6);
    schema.rawDatabase
      ..execute("INSERT INTO medications (id, name) VALUES ('m1', 'Ibuprofen')")
      ..execute(
        'INSERT INTO medication_reminders (id, medication_id, minute_of_day, '
        "enabled) VALUES ('r1', 'm1', 480, 1)",
      );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    expect((await db.select(db.medications).get()).single.revision, 0);
    expect(
      (await db.select(db.medicationReminders).get()).single.syncedRevision,
      isNull,
    );
  });

  test('a v6 deletion still owed to the server survives v7', () async {
    final schema = await verifier.schemaAt(6);
    schema.rawDatabase.execute(
      "INSERT INTO attack_tombstones (id, deleted_at) VALUES ('gone', 1750000000)",
    );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    // Losing it would silently resurrect the attack on the next pull.
    final tombstone = (await db.select(db.syncTombstones).get()).single;
    expect(tombstone.id, 'gone');
    expect(tombstone.collection, 'attacks');
  });

  test('migrates from v7 to v8 (notifications, reminder created_at)', () async {
    final connection = await verifier.startAt(7);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, db.schemaVersion);
  });

  test('v7 reminders survive v8 with an unknown createdAt', () async {
    final schema = await verifier.schemaAt(7);
    schema.rawDatabase
      ..execute("INSERT INTO medications (id, name) VALUES ('m1', 'Ibuprofen')")
      ..execute(
        'INSERT INTO medication_reminders (id, medication_id, minute_of_day, '
        "enabled, revision) VALUES ('r1', 'm1', 480, 1, 0)",
      );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    // Null, not the migration's own clock: a stamped date would hand the notification window months of reminders that never fired.
    final reminder = (await db.select(db.medicationReminders).get()).single;
    expect(reminder.id, 'r1');
    expect(reminder.createdAt, isNull);
  });

  test('migrates from v8 to v9 (notifications table recreated)', () async {
    final connection = await verifier.startAt(8);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, db.schemaVersion);
  });

  test(
    'v9 recreates the notifications table whatever v8 left behind',
    () async {
      final schema = await verifier.schemaAt(8);
      // The shape the intermediate v8 actually had on a dev device: the type column under its old name.
      schema.rawDatabase
        ..execute('DROP TABLE IF EXISTS app_notifications')
        ..execute(
          'CREATE TABLE app_notifications (id TEXT NOT NULL PRIMARY KEY, '
          'kind TEXT NOT NULL, occurred_at INTEGER NOT NULL)',
        );

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, db.schemaVersion);

      // Writable under today's definition — the failure this fixes was an insert against a table that had no `type` column.
      await db
          .into(db.appNotifications)
          .insert(
            AppNotificationsCompanion.insert(
              id: 'rem:r1:1',
              type: NotificationType.medicationReminder,
              occurredAt: DateTime.now().toUtc(),
            ),
          );
      expect(await db.select(db.appNotifications).get(), hasLength(1));
    },
  );

  test('reminders still cascade after v8', () async {
    final schema = await verifier.schemaAt(6);
    schema.rawDatabase
      ..execute("INSERT INTO medications (id, name) VALUES ('m1', 'Ibuprofen')")
      ..execute(
        'INSERT INTO medication_reminders (id, medication_id, minute_of_day, '
        "enabled) VALUES ('r1', 'm1', 480, 1)",
      );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    // Six addColumns rebuild both tables — that is where a foreign key gets silently dropped.
    await (db.delete(db.medications)..where((m) => m.id.equals('m1'))).go();
    expect(await db.select(db.medicationReminders).get(), isEmpty);
  });

  test('migrates from v9 to v10 (adds attacks.ended_at)', () async {
    final connection = await verifier.startAt(9);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, db.schemaVersion);
  });

  // Null is "never said", which is also what a still-running attack looks like.
  test('v9 attacks survive v10 with an unknown end', () async {
    final schema = await verifier.schemaAt(9);
    schema.rawDatabase.execute(
      'INSERT INTO attacks (id, started_at, intensity, location) '
      "VALUES ('a1', 1750000000, 7, 'front')",
    );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    final List<AttackRow> attacks = await db.select(db.attacks).get();

    expect(attacks.single.id, 'a1');
    expect(attacks.single.endedAt, isNull);
  });

  test('migrates from v10 to v11 (adds attacks.medication_effect)', () async {
    final connection = await verifier.startAt(10);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, db.schemaVersion);
  });

  // Backfilling "helped" would invent the very evidence a prescription gets changed on. Null means the question was never answered.
  test('v10 attacks survive v11 with no outcome recorded', () async {
    final schema = await verifier.schemaAt(10);
    schema.rawDatabase.execute(
      'INSERT INTO attacks (id, started_at, intensity, location, '
      "medication_name) VALUES ('a1', 1750000000, 7, 'front', 'Sumatriptan')",
    );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    final AttackRow stored = (await db.select(db.attacks).get()).single;

    expect(stored.medicationName, 'Sumatriptan');
    expect(stored.medicationEffect, isNull);
  });

  test('migrates from v11 to v12 (adds the daily_weather table)', () async {
    final connection = await verifier.startAt(11);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, db.schemaVersion);

    // Empty, and nothing to backfill: no weather was ever stored for a day that had no attack.
    expect(await db.select(db.dailyWeather).get(), isEmpty);
  });

  test('migrates from v12 to v15 (adds attacks.aura)', () async {
    final connection = await verifier.startAt(12);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, db.schemaVersion);
  });

  // NULL, not an empty list: an empty list is the user answering "no aura", which is a different fact from a question nobody put — and the two are.
  test('v12 attacks survive v15 with no aura recorded', () async {
    final schema = await verifier.schemaAt(12);
    schema.rawDatabase.execute(
      'INSERT INTO attacks (id, started_at, intensity, location, '
      "medication_name) VALUES ('a1', 1750000000, 7, 'front', 'Sumatriptan')",
    );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    final AttackRow stored = (await db.select(db.attacks).get()).single;

    expect(stored.medicationName, 'Sumatriptan');
    expect(stored.aura, isNull);
    // v13 widened the coarse `location` into a set of regions; the aura step must not have disturbed that backfill on the way past.
    expect(stored.regions, isNotEmpty);
  });
}
