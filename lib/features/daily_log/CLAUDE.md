# Daily check-in

The one row a day the app asks for whether or not anything hurt.

**It exists to give every analysis a control group.** v1.0 recorded only days
that hurt, so a correlation could say "12 of your attacks followed a 6 hPa drop"
and never "and 40 quiet days followed one too". Wave 2's trigger/protector map
and risk score both read these rows — see `docs/ROADMAP.md`.

## The rules

- **The day is the primary key**, as `yyyy-MM-dd` local
  (`DateTimeUtils.dayKey`). Two devices checking in on the same Tuesday converge
  on one row under last-write-wins instead of syncing two rows that both claim
  it. The key also sorts lexicographically in date order, which is what every
  range query relies on — do not swap it for a UUID with a date column.
- **The payload never carries the date**, because the document id already is it.
  Two copies is two chances to disagree; `daily_log_payload_codec_test.dart`
  asserts the absence.
- **Every field is optional.** A check-in nobody can leave half-done is one they
  stop opening, and a half-answered day is still a day of evidence.
  `DailyLog.isAnswered` is what separates a check-in from a row Apple Health
  filled in on its own with a step count — `answeredCount` counts the former.
- **The screen always writes TODAY.** A date picker would invite filling a week
  in from memory, which is the one thing that would make the control group worse
  than not having one.
- **Sleep MINUTES are never stored here, only the user's 1–5 answer.** HealthKit
  is already on-device storage and sleep never leaves it
  (`features/health/CLAUDE.md`, and `PLAN.md`'s privacy boundary). Steps are
  stored and do sync, exactly as they do on an attack.
- **The factor list is fixed** (`DailyFactor`). Custom factors were rejected:
  the map compares a factor's attack rate against its own absence, so a factor
  invented in week three has too few days behind it to grade, and no two users'
  maps would mean the same thing. `docs/rules/DECISIONS.md` holds the reasoning;
  adding a factor is a release decision.
- **A factor this build has never heard of is dropped, never guessed at** — in
  the converter and in the codec both, so a day written by a newer device still
  opens here.
- **The cycle section asks nothing.** It is a connect switch and a line of
  status read from Apple Health, because the cycle is already recorded there and
  asking the user to type it again is asking twice for something the phone
  knows. Nothing it reads is stored — `features/health/CLAUDE.md` is the rule.
- **The card stays on the dashboard once answered**, saying so. A card that
  vanished on save reads as the app forgetting what it was just told.

## Where it is wired

| Concern | Owner |
|---|---|
| Table, schema v17 | `data/tables/daily_log_tables.dart`, `core/db/app_database.dart` |
| Row → model | `data/repositories/daily_log_mapper.dart` — the repository and the sync store both read rows |
| Sync | `SyncCollection.dailyLogs`, `DriftDailyLogSyncStore`, `DailyLogPayloadCodec`, plus `firestore.rules` and `firestore.indexes.json` |
| Write-through | `SyncWriteThroughService._syncedTables` |
| GDPR wipe | `DataWipeService`, step 10 of 12 |
| Dev fixture | `DevSeedService._seedDailyLogs` — 29 days, worse sleep and more factors on days that hurt, so an analysis built on the fixture has a signal to find |

## Schema v16 is deliberately empty

An unshipped v16 ran on a dev device meaning something else entirely (weather
snapshot columns, since reverted). A device that took it would skip a step
numbered the same, so the check-in's table is created in **v17**. Rule 15 in
`docs/rules/DATA_AND_SYNC.md` is why.
