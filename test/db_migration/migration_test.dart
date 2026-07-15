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

  test('database is at schema version 2', () {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 2);
  });

  test('migrates from v1 to v2 (adds medication_reminders)', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    // Runs onUpgrade and asserts the resulting schema matches v2 exactly.
    await verifier.migrateAndValidate(db, 2);
  });

  test('v1 data survives the migration', () async {
    final schema = await verifier.schemaAt(1);
    // Seed a medication under the v1 schema (raw sqlite3 execute).
    schema.rawDatabase.execute(
      "INSERT INTO medications (id, name) VALUES ('m1', 'Ibuprofen')",
    );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);

    final meds = await db.select(db.medications).get();
    expect(meds.map((m) => m.name), ['Ibuprofen']);
  });
}
