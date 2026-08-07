# Remaining work (premium assumed done)

Snapshot taken with RevenueCat/premium treated as finished — the owner is
handling the App Store Connect side separately. This is what is left in the
codebase, ordered top to bottom by priority. Re-check before acting on an
item; this is a point-in-time survey, not a live tracker.

## 1. ~~GDPR "Delete everything" is incomplete~~ — done

Both halves now exist and are separate on purpose. **"Delete all data"**
(Settings) clears the records on device and in the account, past exports, and
gives up the FCM token, geohash and threshold — but keeps the account, so
someone clearing their history does not lose their subscription binding with
it. **"Delete account"** (Account screen) tears the whole thing down through
the `deleteAccount` callable: synced records, `users/{uid}`, `sync_keys/{uid}`,
then the auth user, in that order — deleting the auth user first would leave
every later step unauthorised and the records stranded.

The server half had to be a Cloud Function, not a choice: rules deny a client
deleting `users/{uid}` (the write rule reads `request.resource.data`, which
does not exist on a delete) and deny `sync_keys` to everyone.

What is still worth knowing:

- The confirm dialog says deleting the account does NOT cancel the
  subscription. It cannot — that lives in the App Store — and a user who
  assumes otherwise keeps being charged.
- Nothing revokes the FCM token from the *device*, only from the server
  record. The cron can no longer target it, which is what matters.

The old "what is left" list under this item is gone: every point on it
(the `users/{uid}` doc, FCM token revocation, `AuthRepository.deleteAccount`,
the `sync_keys/{uid}` teardown) is now built and covered by
`data_wipe_service_test.dart`.

## 2. Push notifications can't deliver on a real device

`ios/Runner/Runner.entitlements` only declares `com.apple.developer.healthkit`
— `aps-environment` is missing. Client code in `alerts`
(`firebase_alert_registration_repository.dart`: request permission, get
token, drop stale tokens) is fully implemented, but nothing can reach a
device until:

- `aps-environment` is added to the entitlements file.
- An APNs auth key is configured in the Firebase console.

## 3. ~~`sync` feature doesn't exist yet~~ — built

`features/sync/` now exists and everything hard rule 12 describes is wired:
auto-sync on sign-in, launch, resume and after logging an attack, all
unawaited; one row in Settings' "Your data" that runs a sync on tap and
carries its status; a scoped first-pull state on the History list.

**Four collections sync** — medications, then their reminders, then attacks,
then the notification list, in that order because each points at the one
before it. Export records deliberately stay local: `filePath` belongs to one
device, and uploading them would multiply the copies hard rule 8 has to
chase.

Automatic passes have a six-hour floor (`SyncController.automaticCooldown`);
`manual` and `record` triggers skip it. A pull decrypts the batch off the UI
isolate above 50 records.

They are **top-level collections tagged with `userId`**, not subcollections
of the user — the owner's call, for a layout that reads like SQL. That makes
`userId` the whole ownership boundary: `OwnedCollection` is the only thing
allowed to build a reference to them, because it is the only way the query
filter cannot be forgotten.

How the open questions were answered:

- **Dirty tracking** is a `revision` counter plus `syncedRevision` on each
  synced table, not a timestamp comparison. Drift stores dates as whole
  seconds, so an edit in the same second as the push before it would have
  looked unchanged; a counter also survives the clock stepping backwards.
  `updatedAt` remains, used only to settle which device's version wins.
  Deletions live in one `SyncTombstones` table keyed by collection, so a
  delete really deletes and only the opaque id survives to be propagated.
- **Encryption is server-assisted, and is NOT end-to-end.** The `getSyncKey`
  callable mints and holds a per-account AES-256 key in `sync_keys/{uid}`,
  denied to every client and reachable only through the Admin SDK. The
  client encrypts with AES-GCM and caches the key in memory for the session.
  Google infrastructure can decrypt; `loginPrivacyNote` and
  `accountDataNote` were rewritten to say "encrypted" and never "only you
  can read this". Keep it that way.
- **`updatedAt` is the one plaintext field** on each remote document, so
  both sides can compare versions and pull only what changed without
  decrypting everything. It reveals when a record was touched, not what is
  in it.
- **Conflicts are last-write-wins**, decided inside the local transaction so
  a pull cannot clobber an edit made while it was in flight; ties go to the
  server so two devices converge.

Deliberately not done, and worth knowing before extending this:

- **No key rotation.** `getSyncKey` returns a key, it never rolls one.
  Rotating would mean re-encrypting every document.
- **No conflict UI.** Last-write-wins is silent; the losing version is gone
  with no prompt.
- **Widget tests must never reach Firebase.** `pumpApp` overrides
  `syncKeyRepositoryProvider` and `remoteSyncRepositoryProvider` with the
  fakes in `test/helpers/sync_fakes.dart`, because the app root fires a sync
  on sign-in. Without those overrides the sync spinner renders and every
  `pumpAndSettle` waits out its full 10-minute timeout.
- **Reminders sync as rows, not as scheduled notifications.** A notification
  belongs to the OS of the device that made it, so a pull calls
  `RemindersController.rescheduleAll()` afterwards. Anything else that ends
  up device-local like this needs the same treatment.

## 4. Manual Firebase/Apple console setup still pending

Already documented in `CLAUDE.md` under "Pending setup"; re-verified against
the current repo state, still open:

- `.firebaserc` now names the project (`migraine-tracker-9f7b2`), but there is
  still no evidence `firestore.rules` or `firestore.indexes.json` have been
  deployed. Both are separate steps (`firebase deploy --only firestore:rules`
  and `--only firestore:indexes`), and the notification collection added to
  `SyncCollection` needs them or every pull dies on `permission-denied`.
- `functions/src/index.ts` now sends `data` + `content-available` on the
  pressure-alert push. That needs `firebase deploy --only functions` before
  alerts land in the in-app notification list.
- The `app_updates` collection doesn't exist yet — the first release record
  has to be created by hand in the Firebase console before force-update can
  ever fire (it fails open until then, which is safe but silent).
- HealthKit capability needs enabling on the App ID in the Apple Developer
  portal, plus a real-device test pass (Simulator has no HealthKit) and the
  App Privacy label (Health & Fitness, collected-but-not-linked).

## 5. The privacy policy is written but not published

`docs/PRIVACY_POLICY.md` and `docs/privacy.json` are current as of
7 Aug 2026 and agree with each other (hard rule 17). What is left is all
outside the repo:

- **Host it.** A HealthKit app needs a reachable privacy policy URL before
  submission. `site.url` in `privacy.json` is still `privacy.example.com`,
  and `storeLinks.appStore` is a placeholder id.
- **Fill `[ADDRESS/COUNTRY]`** in the markdown — the data controller's
  address is the owner's to supply and is a GDPR requirement.
- **The App Privacy label must match the policy**, and the policy now says
  more than the old draft did: Firebase Analytics and Crashlytics are used
  and are tied to the account identifier while signed in, so those are
  linked-to-identity, and synced health data is linked too. Only Apple
  Health sleep/steps stay collected-but-not-linked, because they never
  leave the device.
- Have a lawyer read it before submission.

## 6. ~~`main.dart` config-assert TODO~~ — done

`AppEnv.missingConfigKeys` (`lib/core/env/app_env.dart`) now walks every
required Firebase field plus the platform's own RevenueCat key and returns
the names still empty; `main.dart` asserts that list is empty in one place,
reporting every gap at once. Note this deliberately re-adds an `assert()` to
`main()` while the earlier "TestFlight crash traced to an assert" suspicion
is still under investigation (see `CLAUDE.md`'s RevenueCat section) — if that
crash resurfaces, this is the first thing to suspect and revert.

## 7. WeatherKit not swapped in yet

In-app weather source is still Open-Meteo (the documented temporary stand-in
behind `weatherRepositoryProvider`); WeatherKit REST is the target once a key
exists. Backend cron staying on Open-Meteo permanently is intentional, not
part of this item.

## Smaller, non-blocking

- Test coverage is thin in `alerts` (only `geohash_test.dart` — no test for
  `AlertsController` or the FCM permission/getToken registration flow) and
  `weather` (only the Open-Meteo datasource is tested, not the repository).
- The 4 testing priorities CLAUDE.md calls out explicitly — correlation
  engine, Drift migrations, pressure alert function, paywall entitlement
  gating — all already have dedicated tests. Nothing to do there.
- `l10n/app_en.arb` and `app_vi.arb` are fully in sync (468/468 keys,
  zero diff either direction).
- `firestore.indexes.json` now carries a composite index per synced
  collection (`userId` + `updatedAt`). Deploying is a SECOND step beside
  rules — `firebase deploy --only firestore:indexes` — and a missing index
  fails at runtime, not at build.

## Not an issue (checked, ruled out)

The `_DevPremiumTile` mock-premium switch in Settings
(`settings_screen_dev_premium_tile.dart`) is in-memory only, writes nothing
persistent, and is gated behind `!AppEnv.isProd` both for the row itself and
for `hasPremiumProvider` reading it — it cannot reach a prod build. No action
needed before ship.
