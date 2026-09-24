# Sync

Hard rule 12.

12. **Sync never blocks UI, and it is entirely automatic — there is no control
    for it anywhere** (owner's rule, reversing the manual button). Signed out,
    data is local and nothing goes anywhere. Signed in, **every local write goes
    to the server as it is made**, and the pull runs on sign-in, launch and
    resume: the same best-effort, retry-on-next-launch shape as
    `WeatherAttachService`. No screen, especially the log flow, ever waits on it
    (hard rule 4).

    Signing in is what moves a local-only history up: the sign-in listener in
    `bare_ease_app.dart` fires the pass, and the cooldown stamp is per uid and
    dropped on sign-out, so a fresh account is never held back.

    **Signing out is what moves it back down.** The device's copy belongs to
    the account that is signed in, so `AccountController.signOut` pushes
    whatever is still owed, wipes the device (`DataWipeService.wipeLocal`,
    never `wipeAll` — the server's copy is what the user is getting back),
    drops the cursors and only then signs out. **A push that fails cancels the
    whole sign-out**: every other push in the app is fire-and-forget because a
    later one retries it, and this is the only one that has no later. The
    records left on the device are then the only copy in existence, so the
    session stays and the user is told to get online. Before this, signing out
    left everything in place, and the next account inherited a stranger's
    history — rows already pushed are clean, so they would never reach the new
    account either.

**No sync screen, row or button — one indicator only: the sync card at the top
of Settings** (owner's rule, 2026-09-24, reversing "no indicator anywhere").
Sign-out refuses while records are still owed, and a user who could not see
what was owed met that refusal as a surprise. The card shows it before they
reach the button. `SyncScreen`, `/sync` and the old `syncScreen*` /
`settingsSync*` keys stay deleted; nothing on it makes sync happen.
**The one exception is the Dev group's "Sync everything now"**
(`SyncController.syncEverythingNow`, owner's rule, 2026-09-24): it drops the
pull cursors and runs a whole pass past the cooldown, so the card's bar has a
real history to move and can be watched. Dev group only, never a user control.

**Five kinds of record sync, in this order**: medications, then their reminders
(a reminder points at a medication, so the other order hits a foreign key that is
not there yet), then attacks, then daily check-ins, then notifications (one names
the reminder and medication it came from). The check-ins sit where they do only
for tidiness — a daily log points at nothing and nothing points at it, and its id
is the day itself, so two devices' Tuesday converge on one row. **Exports deliberately do not sync** — `filePath`
is local to one device, and uploading them would multiply the copies hard rule 8
has to chase.

## Two passes, and which one runs when

| | `SyncService.sync` | `SyncService.pushPending` |
|---|---|---|
| Does | pull, then push, per collection | push only |
| Fired by | sign-in, launch, resume | every write to a synced table |
| Held back by | the 6h cooldown, pull half only | nothing |
| Costs when idle | `getSyncKey` + a query per collection | four local queries, no network |

**A local change never waits for a pass.** `SyncWriteThroughService`
(`data/services/`) watches Drift's `tableUpdates` for the synced tables and the
tombstones, debounces `SyncConstant.writeThroughDebounce` (2s) and pushes.

- **It watches tables rather than asking each controller to call sync after its
  own save** — the log flow used to, and medications and reminders never did, so
  an edit sat on the device until the next launch. A rule that has to be repeated
  at every new write is already broken somewhere; a new synced table joins by
  being added to `_syncedTables`.
- **The 2s debounce is what makes a burst one push**: saving a medication with
  three reminders writes four rows.
- **The chain terminates, and that is why `pushPending` must not fetch the key
  when nothing is pending.** Marking a record synced is itself a write to that
  table, so every real push schedules one more; the second finds nothing, sends
  nothing, and stops. A `getSyncKey` call in that empty pass would be paid after
  every single write.
- **A push writes state but stamps no cooldown.** The Settings card shows a
  push's progress and the count still owed, so both come from it; a push is
  still not the pull the floor is about.
- **A failed push that leaves records owed retries on its own**, backing off
  `SyncConstant.pushRetryFirst` (15s), doubling to `pushRetryMax` (5m), reset by
  any push that lands and stopped on sign-out. **Capped at
  `pushRetryLimit` (6, about 13 minutes)**, then it waits for the next launch,
  resume or write, which start the budget over: a refusal that is not the
  network never clears on its own, and each failure files two Crashlytics
  non-fatals. Resume alone was not enough: it
  fires the instant the app comes back, before Wi-Fi or cellular has, so that
  push failed too and the card sat on "Uploads when online" while online
  (owner-reported bug, 2026-09-24). The next write, launch or resume still
  pushes as before.

## The cooldown

**The pull has a floor between passes: `SyncConstant.automaticCooldown` (6h).**
Launch and resume both fire it, so without one, ten app opens in ten minutes were
ten whole passes — a `getSyncKey` callable plus a query and a push per collection
each time, usually to find nothing had changed.

**It holds back the pull half only — a cooled-down pass still pushes what the
device owes.** A write-through push that failed, which offline is the whole
point, has nothing else to retry it: the next pass can be six hours off, a user
who logs nothing more never fires one, and no connectivity listener exists to
notice the network coming back. The skipped pass therefore costs what
`pushPending` costs — four local queries, and no network until something is
actually pending.

- **The stamp is written only after a pass that worked**, so a failure is retried
  by the next open rather than parked for six hours. It lives in `SyncCursorStore`
  (`SecureStore`, per uid) rather than memory, because the triggers are launch
  and resume — a cooldown the app forgets on close would let ten cold starts run
  ten passes. `clear()` drops it with the cursors, so signing into another
  account syncs at once.
- **A skipped pass changes no phase.** It is neither a fresh sync nor a failure;
  its push still recounts `pending` for the Settings card.
- The cost is the owner's call and worth stating: a change made on **another**
  device can wait up to six hours before this one sees it.
- **Passes and pushes run one at a time**, through `SyncController`'s queue: two
  that overlapped would send the same record twice, and one would mark it synced
  while the other was still writing it. Each kind collapses while it is queued —
  two writes a second apart owe one push, ten app opens owe one pass.

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

| Where | Reads | Shows |
|---|---|---|
| History, first pull on a device | `isSyncing`, `isFirstPull` | "getting your attacks" instead of "you have none" |
| Settings, top card, signed in only | `phase`, `done`/`total`, `pending` | title over detail — "Syncing / 12/40 … 30%" over a bar · "3 changes not saved / Uploads when online" · "All saved / On your account" |

- **`pending` is recounted after every pass and push** (`SyncService.pendingCount`,
  four local queries), so an offline write shows up as owed within the 2s
  debounce. Null means not counted yet — the card says "checking" rather than
  guess.
- **`total` can grow during a pass**: pending is counted up front, and each
  collection's pull adds its batch when it lands. The bar may step back a little;
  a total that pretended to know the pull size would be wrong instead.
- **No flow is ever gated on sync completing**, and the card has no button.

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
- **One kind failing does not stop the kinds after it** (owner's rule,
  2026-09-24). A pass and a push each give every collection its turn, then
  throw the first failure, so sign-out and the Settings card still see it. It
  was `daily_logs` refused and the six notifications queued behind it never
  sent. Two limits: no key stops everything (every kind needs it), and within a
  kind the push still stops at the first record — a dropped connection fails
  the rest too.
- **Reminders sync as rows; their OS notifications do not.** A notification is
  registered with the device that made it, so a reminder pulled from another
  phone would sit in the list and never fire. A pull that brought reminders down
  calls `RemindersController.rescheduleAll()`, which reads its strings through
  `lookupAppLocalizations` — there is no `BuildContext` in a background sync.

## Rules, indexes and tests

- **Adding to `SyncCollection` means editing `firestore.rules` in the same change
  and deploying it.** The root-level allowlist must name every value of the enum,
  and `firestore.indexes.json` must carry its composite index. A bare wildcard is
  deliberately not used: at the root it would match `sync_keys` and `app_config`
  too. `sync_collection_rules_test.dart` fails when the two drift — they drifted
  once, when medications and reminders were added while the rules named only
  `attacks`, and every sync died on its first query with `permission-denied`, the
  dev seed included. **A change is only live once `firebase deploy --only
  firestore:rules` AND `--only firestore:indexes` both run**; the test proves the
  files are right, never that the project has them.
- **`pumpApp` overrides `syncKeyRepositoryProvider` and
  `remoteSyncRepositoryProvider`** with the fakes in
  `test/helpers/sync_fakes.dart`, because the app root fires a sync on sign-in
  and a push after every write.
  Without them a widget test reaches for Firebase, the spinner renders, and every
  `pumpAndSettle` waits out its full 10-minute timeout — the suite goes from 30
  seconds to 10 minutes.
- **The GDPR wipe deletes the account's synced records BEFORE the device's**, and
  a failure there aborts the whole wipe. The other order leaves the cloud copy
  with nothing left to say it should go, and the next sync pulls every deleted
  record back down. What the wipe still misses is in `docs/REMAINING_WORK.md`.
- **Neither half of the remote wipe may run unbounded, because both sit behind a
  spinner with nothing else on screen.** `FirestoreSyncRepository` pages a
  collection at most `_maxDeleteRounds` (40 × 500 documents) and then throws
  naming the collection; `DataWipeService.remoteTimeout` (60s) caps each of the
  two network steps. Both were bare `await`s and the delete loop was a bare
  `while (true)` whose only exit was an empty page — so a Firestore write
  waiting on a server ack that never came, or a write-through push refilling the
  page that had just been emptied, left the three dev tiles spinning for as long
  as the app ran, with no error and no way out. **Giving up is safe here and
  only here**: both steps run before anything local is touched, so the abort
  leaves the device's copy whole.
