import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/attacks/data/tables/attack_tables.dart';
import '../../features/attacks/domain/enums/aura_type.dart';
import '../../features/attacks/domain/enums/exertion_level.dart';
import '../../features/attacks/domain/enums/head_location.dart';
import '../../features/attacks/domain/enums/head_region.dart';
import '../../features/attacks/domain/enums/medication_effect.dart';
import '../../features/medications/data/tables/medication_tables.dart';
import '../../features/notifications/data/tables/notification_tables.dart';
import '../../features/notifications/domain/enums/notification_type.dart';
import '../../features/settings/data/tables/export_tables.dart';
import '../../features/sync/data/tables/sync_tables.dart';
import '../../features/weather/data/tables/daily_weather_tables.dart';
import 'converters.dart';

export '../../features/attacks/data/tables/attack_tables.dart';
export '../../features/medications/data/tables/medication_tables.dart';
export '../../features/notifications/data/tables/notification_tables.dart';
export '../../features/settings/data/tables/export_tables.dart';
export '../../features/sync/data/tables/sync_tables.dart';
export '../../features/weather/data/tables/daily_weather_tables.dart';

part 'app_database.g.dart';

/// The single on-device database. Tables are owned by their features; this
/// class only composes them into one SQLite file.
@DriftDatabase(
  tables: [
    Attacks,
    WeatherSnapshots,
    Medications,
    MedicationReminders,
    AppNotifications,
    ExportRecords,
    SyncTombstones,
    DailyWeather,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Test constructor — pass e.g. `NativeDatabase.memory()`.
  AppDatabase(super.e);

  /// Opens the on-device database. Source of truth for all health data.
  AppDatabase.open() : super(driftDatabase(name: 'baroease'));

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v2: daily medication reminders.
      if (from < 2) {
        await m.createTable(medicationReminders);
      }
      // - v3: medications remember when they were added, so the tab can sort/filter by it.
      // - Existing rows get null — inventing a date would corrupt the very filter this serves.
      if (from < 3) {
        await m.addColumn(medications, medications.createdAt);
      }
      // - v4: the export screen keeps a history.
      // - Nothing to backfill — exports before this shipped were never recorded.
      if (from < 4) {
        await m.createTable(exportRecords);
      }
      // - v5: self-reported physical exertion, added to the details step.
      // - Existing rows get null — nobody reported exertion before this shipped.
      if (from < 5) {
        await m.addColumn(attacks, attacks.exertionLevel);
      }
      // - v6: sync state per attack, for encrypted upload once signed in.
      // - Existing rows land at revision 0 with nothing confirmed, which is
      //   what makes the first sync push the whole history.
      if (from < 6) {
        await m.addColumn(attacks, attacks.updatedAt);
        await m.addColumn(attacks, attacks.revision);
        await m.addColumn(attacks, attacks.syncedRevision);
        // v6's own tombstone table, replaced in v7 below. Raw SQL because it
        // is no longer in the schema, so there is no generated class for it —
        // but a v5 database must still walk the path v6 actually shipped.
        await customStatement(
          'CREATE TABLE IF NOT EXISTS attack_tombstones ('
          'id TEXT NOT NULL PRIMARY KEY, deleted_at INTEGER NOT NULL)',
        );
      }
      // - v7: medications and their reminders sync too, not just attacks.
      // - One tombstone table for all three replaces the attacks-only one:
      //   a tombstone holds no data, so three copies could only disagree.
      if (from < 7) {
        await m.addColumn(medications, medications.updatedAt);
        await m.addColumn(medications, medications.revision);
        await m.addColumn(medications, medications.syncedRevision);
        // Only when the reminders table predates this: `createTable` builds
        // from today's definition, so a database that ran the v2 step already
        // has these three and adding them again is a duplicate-column error.
        if (from >= 2) {
          await m.addColumn(medicationReminders, medicationReminders.updatedAt);
          await m.addColumn(medicationReminders, medicationReminders.revision);
          await m.addColumn(
            medicationReminders,
            medicationReminders.syncedRevision,
          );
        }
        await m.createTable(syncTombstones);
        // Deletions still owed to the server must survive the move, or they
        // would silently come back on the next pull.
        await customStatement(
          'INSERT INTO sync_tombstones (collection, id, deleted_at) '
          "SELECT 'attacks', id, deleted_at FROM attack_tombstones",
        );
        await customStatement('DROP TABLE IF EXISTS attack_tombstones');
      }
      // - v8: the notification list, and the bound its reminder half needs.
      // - Existing reminders get a null createdAt: this migration's clock
      //   would invent the history the column exists to fence off (as in v3).
      if (from < 8) {
        await m.createTable(appNotifications);
        // Same guard as v7's: `createTable` builds from today's definition,
        // so a database young enough to have just run the v2 step already
        // has this column.
        if (from >= 2) {
          await m.addColumn(medicationReminders, medicationReminders.createdAt);
        }
      }
      // - v9: `type` was `kind` in a dev-only v8, renamed in place — those
      //   databases sit at v8 with the old column and no step that fixes it.
      // - Recreated, not renamed: nothing records what that v8 held.
      if (from < 9) {
        await customStatement('DROP TABLE IF EXISTS app_notifications');
        await m.createTable(appNotifications);
      }
      // - v10: how long an attack lasted, recorded after the fact.
      // - Existing rows get null = "never said", the same state as an attack
      //   still running. An invented end is a duration nobody gave.
      if (from < 10) {
        await m.addColumn(attacks, attacks.endedAt);
      }
      // - v11: whether the medication taken for an attack helped.
      // - Existing rows get null = "never answered", the same state as one
      //   where nothing was taken. "Helped" is evidence nobody gave.
      if (from < 11) {
        await m.addColumn(attacks, attacks.medicationEffect);
      }
      // - v12: a pressure reading per day, so the correlation has a
      //   denominator — the days without an attack.
      // - Nothing to backfill: no weather was ever stored for an attackless day.
      if (from < 12) {
        await m.createTable(dailyWeather);
      }
      // - v13: the location step records a SET of head areas, so `location`
      //   becomes `regions`. Backfilled but never sharpened: "left side" is
      //   every region on the left, which is how precise the user was.
      if (from < 13) {
        await m.addColumn(attacks, attacks.regions);
        for (final HeadLocation location in HeadLocation.values) {
          await customUpdate(
            'UPDATE attacks SET regions = ? WHERE location = ?',
            variables: <Variable<Object>>[
              Variable<String>(
                const HeadRegionListConverter().toSql(location.regions),
              ),
              Variable<String>(location.name),
            ],
            updates: <TableInfo<Table, Object?>>{attacks},
          );
        }
        // Recreates the table from today's definition, which no longer has
        // `location` — drift's way of dropping a column SQLite cannot drop.
        // The UPDATE above is raw SQL for the same reason: no field to name.
        //
        // `newColumns` names every column added AFTER v13, and this list has
        // to grow with each one. "Today's definition" is today's, not v13's,
        // so drift would otherwise copy a column out of an old table that
        // does not have it yet and the whole migration dies on
        // `no such column`. v14's `steps` and v15's `aura` are here for that
        // reason and nothing else.
        await m.alterTable(
          TableMigration(
            attacks,
            newColumns: <GeneratedColumn<Object>>[
              attacks.steps,
              attacks.aura,
            ],
          ),
        );
      }
      // - v14: an attack carries the day's step count, read as it was logged.
      // - Null on every existing row: HealthKit can answer a past day but not
      //   a past moment, so a backfill files another figure as the same one.
      // - `from >= 13` because v13 rebuilt the table from TODAY's definition,
      //   which already has this column: a database coming from v12 or below
      //   arrives here with `steps` present, and ADD COLUMN would die on a
      //   duplicate. Every column added from now on needs the same guard —
      //   see the v13 step.
      if (from >= 13 && from < 14) {
        await m.addColumn(attacks, attacks.steps);
      }
      // - v15: the aura kinds reported for an attack, recorded after the fact.
      // - Existing rows get the empty list, which is both "no aura" and
      //   "never asked" — nothing here can tell those apart, and inventing
      //   "no aura" would answer a question nobody was put.
      if (from >= 13 && from < 15) {
        await m.addColumn(attacks, attacks.aura);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
