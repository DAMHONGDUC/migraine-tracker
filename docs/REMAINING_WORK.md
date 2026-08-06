# Remaining work (premium assumed done)

Snapshot taken with RevenueCat/premium treated as finished — the owner is
handling the App Store Connect side separately. This is what is left in the
codebase, ordered top to bottom by priority. Re-check before acting on an
item; this is a point-in-time survey, not a live tracker.

## 1. GDPR "Delete everything" is still incomplete (hard rule 8)

`DataWipeService.wipeAll()` (`lib/features/settings/domain/services/data_wipe_service.dart`)
now deletes the account's synced attacks (`users/{uid}/attacks`) before it
touches the device — that order matters, and a failure aborts the wipe, or
the next sync would pull every deleted attack back down. What is left:

- No deletion of the Firestore `users/{uid}` doc itself.
- No FCM token revocation on wipe. `AlertRegistrationRepository.unregister()`
  (`lib/features/alerts/domain/repositories/`) already does exactly this and
  just needs calling.
- No Firebase Auth account deletion — `AuthRepository`
  (`lib/features/auth/domain/repositories/auth_repository.dart`) doesn't
  even have a `deleteAccount()` method yet; add it to the interface and
  both implementations first.
- No deletion of the encryption key at `sync_keys/{uid}`. It is unreachable
  from any client (rules deny it outright), so this has to be a Cloud
  Function — most naturally the same one that deletes the account.

This also blocks App Store requirement 5.1.1(v) (in-app account deletion is
mandatory once accounts exist).

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

**Three collections sync** — medications, then their reminders, then
attacks, in that order because a reminder points at a medication. Export
records deliberately stay local: `filePath` belongs to one device, and
uploading them would multiply the copies hard rule 8 has to chase.

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

- `firestore.rules` exists in-repo but there's no `.firebaserc` and no
  evidence it's been deployed (`firebase deploy --only firestore:rules`).
- The `app_updates` collection doesn't exist yet — the first release record
  has to be created by hand in the Firebase console before force-update can
  ever fire (it fails open until then, which is safe but silent).
- HealthKit capability needs enabling on the App ID in the Apple Developer
  portal, plus a real-device test pass (Simulator has no HealthKit) and the
  App Privacy label (Health & Fitness, collected-but-not-linked).

## 5. ~~`main.dart` config-assert TODO~~ — done

`AppEnv.missingConfigKeys` (`lib/core/env/app_env.dart`) now walks every
required Firebase field plus the platform's own RevenueCat key and returns
the names still empty; `main.dart` asserts that list is empty in one place,
reporting every gap at once. Note this deliberately re-adds an `assert()` to
`main()` while the earlier "TestFlight crash traced to an assert" suspicion
is still under investigation (see `CLAUDE.md`'s RevenueCat section) — if that
crash resurfaces, this is the first thing to suspect and revert.

## 6. WeatherKit not swapped in yet

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
- `l10n/app_en.arb` and `app_vi.arb` are fully in sync (420/420 keys,
  zero diff either direction).
- `firestore.indexes.json` is empty; not a problem for the current simple
  queries, just worth checking before adding a more complex one.

## Not an issue (checked, ruled out)

The `_DevPremiumTile` mock-premium switch in Settings
(`settings_screen_dev_premium_tile.dart`) is in-memory only, writes nothing
persistent, and is gated behind `!AppEnv.isProd` both for the row itself and
for `hasPremiumProvider` reading it — it cannot reach a prod build. No action
needed before ship.
