# Sync

Hard rule 12.

12. **Sync never blocks UI — automatic, with one manual control in Settings.**
    It runs silently in the background on sign-in, on launch/resume, and after
    logging an attack: the same best-effort, retry-on-next-launch shape as
    `WeatherAttachService`. No screen, especially the log flow, ever waits on it
    (hard rule 4).

**Three kinds of record sync, in this order**: medications, then their reminders
(a reminder points at a medication, so the other order hits a foreign key that is
not there yet), then attacks. **Exports deliberately do not sync** — `filePath`
is local to one device, and uploading them would multiply the copies hard rule 8
has to chase.

## The cooldown

**Automatic sync has a floor between passes: `SyncController.automaticCooldown`
(6h).** Launch and resume both fire it, so without one, ten app opens in ten
minutes were ten whole passes — a `getSyncKey` callable plus a query and a push
per collection each time, usually to find nothing had changed.

- **`SyncTrigger` decides who is held back: only `automatic`.** `manual` is the
  user asking in as many words with the screen in front of them, and `record`
  exists so a just-logged attack reaches the server before the phone can be lost.
- **The stamp is written only after a pass that worked**, so a failure is retried
  by the next open rather than parked for six hours. It lives in `SyncCursorStore`
  (`SecureStore`, per uid) rather than memory, because the automatic triggers are launch
  and resume — a cooldown the app forgets on close would let ten cold starts run
  ten passes. `clear()` drops it with the cursors, so signing into another
  account syncs at once.
- **A skipped pass changes no state at all** — not `lastSyncedAt`, not the phase.
  `SyncScreen` must show it neither as a fresh sync nor as a failure.
- The cost is the owner's call and worth stating: a change made on another device
  can wait up to six hours, unless the user logs an attack or taps the button.

## Decrypting a pull

**A pull decrypts the whole batch through `AttackCipher.decryptAll`, which moves
the AES off the UI isolate above `AesGcmAttackCipher.isolateThreshold` (50
records).** It is the only part of a sync that holds the UI thread: SQLite is
already on a background isolate (`drift_flutter` opens a
`createBackgroundConnection`), Firestore and the callables are platform channels,
and the push loop awaits a network write per record so it interleaves on its own.
Measured at ~0.27ms a record, so a hundred-record pull is a couple of dropped
frames and a thousand is a visible stutter.

- **The threshold is not optional.** An ordinary pull carries a handful of
  records, and paying an isolate hop for each of four collections on every sync
  would cost more than the jank it removes.
- **`decryptAll` is index-for-index with its input and never throws for one bad
  row** — null at a position means that one could not be opened. That is what
  keeps "counted and skipped, never retried forever" true across the hop; a batch
  that threw would wedge every record behind the bad one. The codec's own
  `decode` stays on the calling isolate, where its per-record `FormatException`
  is already handled.
- Both routes run the same `_decryptEach`, so the isolate and the inline path
  cannot answer differently.

## Where sync is visible

- **A row in Settings' "Your data" leading to `SyncScreen`**
  (`features/sync/presentation/screens/sync_screen/`), sitting with export and
  delete because it is one more thing that happens to the user's data. The row
  (`SyncSettingsTile`, `core/widgets/sections/`) is a plain chevron row **except
  while a pass runs**: then its trailing slot carries a spinner and the
  percentage, spinner first. Both, never just the spinner — a row that only spins
  cannot tell a slow sync from a stuck one. The row is absent without an account,
  and the router turns `/sync` away while signed out.
- **`SyncScreen` shows it in full**: a determinate bar with the percentage while
  a pass runs, the last-synced time when it does not, and the one manual button.
  Determinate on purpose — an indeterminate bar next to "42%" says two things at
  once. **Nothing about sync appears on the Account screen**, and no other row
  anywhere shows an indicator.
- **Progress counts fixed steps, never records** — two per collection, plus the
  fraction of the step in flight. Counting records means discovering more work
  mid-pass, and a bar that jumps backwards reads as a bug even when the sync is
  fine. `SyncController` pushes a new state only when the whole percent changes,
  so a thousand-record account rebuilds the row a hundred times, not a thousand.
- The History list has one extra, scoped to the very first pull after signing in
  on a device: an empty list says "getting your attacks" instead of "you have
  none". **No flow is ever gated on sync completing.**

## The crypto

**Sync is encrypted but NOT end-to-end, and the copy must never imply
otherwise.** The `getSyncKey` callable mints and holds a per-account AES-256 key
in `sync_keys/{uid}`, which `firestore.rules` denies to every client — only the
Admin SDK behind that function reaches it, and anonymous callers are refused
(hard rule 1). Google infrastructure can therefore decrypt. `loginPrivacyNote`
and `accountDataNote` say "encrypted" and deliberately never "only you can read
them"; hold any new copy to that bar.

**A payload codec refuses only versions NEWER than it knows, never merely
different**, and ignores fields it does not recognise. The first bump would
otherwise orphan every record already uploaded, and an added optional field would
stop two builds in the wild reading each other.

## Change tracking and ordering

- **Local change tracking is a `revision` counter, never a timestamp.** Drift
  stores dates as whole seconds, so an edit in the same second as the push before
  it looks unchanged and silently never syncs; a counter also survives the clock
  stepping backwards. `updatedAt` still exists on each synced table, but only to
  settle which device's version wins.
- **Deleting really deletes the row** and leaves a `SyncTombstones` entry holding
  the opaque id and its collection — no intensity, note or medication name may
  outlive a delete, and reads then need no filter that could be forgotten.
  **Deleting a medication tombstones its reminders too**: the FK cascade removes
  them on every device that pulls the deletion, but the server's copies belong to
  no cascade.
- **Mark synced only after the server confirms, and pull before pushing.** A kill
  mid-pass must cost a re-push, never a lost record. Pull goes first because the
  other order re-downloads everything it just uploaded (a device signing in has
  no cursor). A payload that will not decrypt is counted and skipped, never
  retried forever. Each collection keeps its own cursor, so a pull that failed on
  reminders cannot look finished because attacks got through.
- **Reminders sync as rows; their OS notifications do not.** A notification is
  registered with the device that made it, so a reminder pulled from another
  phone would sit in the list and never fire. A pull that brought reminders down
  calls `RemindersController.rescheduleAll()`, which reads its strings through
  `lookupAppLocalizations` — there is no `BuildContext` in a background sync.

## Rules, indexes and tests

- **Adding to `SyncCollection` means editing `firestore.rules` in the same change
  and deploying it.** The root-level allowlist must name every value of the enum,
  and `firestore.indexes.json` must carry its composite index. A bare wildcard is
  deliberately not used: at the root it would match `sync_keys` and `app_updates`
  too. `sync_collection_rules_test.dart` fails when the two drift — they drifted
  once, when medications and reminders were added while the rules named only
  `attacks`, and every sync died on its first query with `permission-denied`, the
  dev seed included. **A change is only live once `firebase deploy --only
  firestore:rules` AND `--only firestore:indexes` both run**; the test proves the
  files are right, never that the project has them.
- **`pumpApp` overrides `syncKeyRepositoryProvider` and
  `remoteSyncRepositoryProvider`** with the fakes in
  `test/helpers/sync_fakes.dart`, because the app root fires a sync on sign-in.
  Without them a widget test reaches for Firebase, the spinner renders, and every
  `pumpAndSettle` waits out its full 10-minute timeout — the suite goes from 30
  seconds to 10 minutes.
- **The GDPR wipe deletes the account's synced records BEFORE the device's**, and
  a failure there aborts the whole wipe. The other order leaves the cloud copy
  with nothing left to say it should go, and the next sync pulls every deleted
  record back down. What the wipe still misses is in `docs/REMAINING_WORK.md`.
