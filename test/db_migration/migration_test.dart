import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';

import 'generated/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('database is at schema version 4', () {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 4);
  });

  // Always migrates to AppDatabase.schemaVersion, so every starting point is
  // validated against the current head, not the head at write time.
  test('migrates from v1 all the way to current', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 4);
  });

  test('v1 data survives every migration', () async {
    final schema = await verifier.schemaAt(1);
    // Seed a medication under the v1 schema (raw sqlite3 execute).
    schema.rawDatabase.execute(
      "INSERT INTO medications (id, name) VALUES ('m1', 'Ibuprofen')",
    );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 4);

    final meds = await db.select(db.medications).get();
    expect(meds.map((m) => m.name), ['Ibuprofen']);
    expect(meds.single.createdAt, isNull);
  });

  test('migrates from v2 to v3 (adds medications.created_at)', () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 4);
  });

  test('v2 medications survive v3 with an unknown createdAt', () async {
    final schema = await verifier.schemaAt(2);
    schema.rawDatabase.execute(
      "INSERT INTO medications (id, name) VALUES ('m1', 'Sumatriptan')",
    );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 4);

    final med = (await db.select(db.medications).get()).single;
    expect(med.name, 'Sumatriptan');
    // Their real creation date was never recorded — null says so instead of
    // inventing the migration's timestamp and poisoning the date filter.
    expect(med.createdAt, isNull);
  });

  test('migrates from v3 to v4 (adds the export history table)', () async {
    final connection = await verifier.startAt(3);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 4);

    // The new table is usable, and starts empty — exports made before v4
    // were never recorded, so there is nothing to backfill.
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
    await verifier.migrateAndValidate(db, 4);

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
    await verifier.migrateAndValidate(db, 4);

    // Rebuilding a table for addColumn can silently drop foreign keys.
    await (db.delete(db.medications)..where((m) => m.id.equals('m1'))).go();
    expect(await db.select(db.medicationReminders).get(), isEmpty);
  });
}
