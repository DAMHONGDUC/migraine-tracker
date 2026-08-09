# local/ — on-device data (Drift / SQLite)

The 7 tables of `AppDatabase`, schema v9. This is the **source of truth** for
every piece of health data (hard rule 1); Firebase only ever holds an encrypted
copy.

| File | SQL table | Drift class | Syncs? |
| --- | --- | --- | --- |
| `attacks.json` | `attacks` | `Attacks` | yes |
| `weather_snapshots.json` | `weather_snapshots` | `WeatherSnapshots` | travels inside the attack's payload |
| `medications.json` | `medications` | `Medications` | yes |
| `medication_reminders.json` | `medication_reminders` | `MedicationReminders` | yes |
| `app_notifications.json` | `app_notifications` | `AppNotifications` | yes |
| `export_records.json` | `export_records` | `ExportRecords` | **no** — `filePath` is true on one device only |
| `sync_tombstones.json` | `sync_tombstones` | `SyncTombstones` | sync bookkeeping, not a user record |

`all_tables.json` merges all 7, generated from the files above.

## Conventions

- **Dates are ISO-8601 UTC strings** for readability. In SQLite, Drift stores a
  `DateTimeColumn` as **unix seconds**, so loading these means parsing and
  converting to epoch seconds — milliseconds are lost, exactly as in the real
  database.
- **`symptoms` / `triggers` are JSON arrays here.** The real column is `TEXT`
  holding a JSON string (`StringListConverter`), defaulting to `"[]"`.
- **Enums are stored by `.name`**: `location` ∈ left/right/front/back/whole,
  `exertionLevel` ∈ none/light/moderate/severe (null = "never asked"),
  `type` ∈ medicationReminder/pressureAlert, `kind` ∈ json/csv/pdf,
  `collection` ∈ attacks/medications/medication_reminders/notifications.
- **The three sync columns** (`updatedAt`, `revision`, `syncedRevision`) exist
  on `attacks`, `medications`, `medication_reminders` and `app_notifications`.
  Dirty means `syncedRevision != revision`. `export_records` and
  `sync_tombstones` have none.
- **`minuteOfDay`** is minutes from local midnight: 480 = 08:00, 1290 = 21:30.

## Cases included on purpose

- `attacks[0]` — complete, and synced (`revision == syncedRevision`).
- `attacks[1]` — **no weather**: logged offline, waiting on the backfill; still
  dirty (`syncedRevision: null`), so it is absent from `firebase/`.
- `attacks[2]` — no medication, empty `symptoms`/`triggers`, `exertionLevel:
  none` (a real answer, not missing data).
- `attacks[3]` — a row predating v5/v6: `exertionLevel` and `updatedAt` null,
  `revision: 0`, never pushed.
- `attacks[4]` — edited after a push: `revision: 5` > `syncedRevision: 4`, so
  the server's copy is the older one.
- `medications[3]` / `medication_reminders[3]` — `createdAt: null`, rows
  predating v3 / v8; null means "unknown", not the date the migration ran.
- `app_notifications[2]` — its reminder and medication are **gone** from
  `medications.json`: deleting a medication cascades its reminders away, but
  the history of having been reminded has to survive (`medicationId` /
  `reminderId` carry no foreign key).
- `sync_tombstones` — the ids here match **no** row in the other files, because
  those records were really deleted; a tombstone keeps an id and nothing else,
  no name and no note. The same four ids reappear in `firebase/` as documents
  with `deleted: true`.
