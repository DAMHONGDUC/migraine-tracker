# Remaining work (premium assumed done)

Snapshot taken with RevenueCat/premium treated as finished — the owner is
handling the App Store Connect side separately. This is what is left in the
codebase, ordered top to bottom by priority. Re-check before acting on an
item; this is a point-in-time survey, not a live tracker.

## 1. GDPR "Delete everything" is incomplete (hard rule 8)

`DataWipeService.wipeAll()` (`lib/features/settings/domain/services/data_wipe_service.dart`)
only wipes local data: attacks, medications, notifications, export files +
their DB rows. Its own doc comment already flags this:

> v1 wipes the on-device database; the auth/sync and alerts phases MUST
> extend this with Firestore doc + synced attacks deletion, FCM token
> revocation, and account deletion.

Now that `auth` and `alerts` both exist, the gap is real, not theoretical:

- No deletion of the Firestore `users/{uid}` doc or `users/{uid}/attacks`.
- No FCM token revocation on wipe.
- No Firebase Auth account deletion — `AuthRepository`
  (`lib/features/auth/domain/repositories/auth_repository.dart`) doesn't
  even have a `deleteAccount()` method yet; add it to the interface and
  both implementations first.

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

## 3. `sync` feature doesn't exist yet

No `features/sync/` folder, no Firestore code anywhere under
`features/attacks/` (confirmed by grep). Encrypted attack sync for signed-in
users is described in `PLAN.md` as its own phase and hasn't been started.
Decide whether it's in scope for this release before treating the app as
done — right now signed-in users get an auth profile but no attack sync.

**UX contract is decided** (see hard rule 12 in `CLAUDE.md`): never blocks
UI, auto-sync in the background (sign-in, app launch/resume, after logging
an attack), plus a manual "Sync now" button and a progress indicator at the
top of the Account screen — nowhere else. Still open before this can be
built:

- **Dirty-tracking columns on `Attacks`** — no `updatedAt`/`isSynced`/
  `syncedAt` column exists today (`attack_tables.dart`). Needed so a partial
  push/pull (including one interrupted by the app being killed mid-sync) can
  resume idempotently: mark an attack synced only after Firestore confirms
  the write, never before, so a kill mid-sync just means a harmless re-push
  next launch, not a lost or duplicated attack.
- **Encryption design** — `PLAN.md:94` explicitly defers key management and
  cross-device recovery to "the sync phase"; no algorithm or library is
  chosen anywhere in the repo. Hard blocker before anything can be pushed to
  `users/{uid}/attacks`.
- **Trigger wiring** — the natural hook is the existing
  `ref.listen(authUserProvider, ...)` in `bare_ease_app.dart` that already
  fires `syncProfile()`/`purchaseIdentityProvider.sync()`; attack sync should
  slot into the same listener, unawaited, best-effort.
- **Pull-down case UI** — signing into an account that already has remote
  data (the `_recoverFromLinkFailure` path in
  `firebase_auth_repository.dart`) leaves local Drift empty until the first
  pull completes. Consider a scoped loading state on the History list for
  this one case only — not a blocking screen — so the list doesn't read as
  "no data" while the pull is in flight.
- **`DataWipeService` extension** — once sync exists, "delete everything"
  must also delete the Firestore doc + synced attacks and revoke the FCM
  token (already flagged in item 1).

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
