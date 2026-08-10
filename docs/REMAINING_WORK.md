# Remaining work

Snapshot of 10 Aug 2026. Re-check before acting on an item; this is a
point-in-time survey, not a live tracker.

**Nothing on this list is code any more.** Every open item is a console, a
portal or a piece of paper — the repo half of each one is built and tested.
The numbered sections below are the detail and the reasoning; the checklist
here is the whole of what is actually left to do.

## Owner checklist

Grouped by where the work happens, because that is how it gets done — one
console at a time. The "why it matters" column is what breaks if the item is
skipped, since several of these fail **silently**.

### Firebase (CLI + console)

| # | What | Why it matters if skipped |
|---|---|---|
| ~~1~~ | ~~firestore rules~~ | **Done 10 Aug**, via `melos run deploy-firebase`. |
| ~~2~~ | ~~firestore indexes~~ | **Done 10 Aug**, same run. `firebase firestore:indexes` reads back a composite index and field overrides for all four `SyncCollection` values. |
| ~~3~~ | ~~functions~~ | **Done 10 Aug**, same run. |
| ~~4~~ | ~~APNs auth key~~ | **Done 10 Aug.** A `.p8` key uploaded to `migraine-tracker-9f7b2`. One key serves the whole Apple team and both APNs environments, so there is nothing per-app or per-environment left to configure. |
| 5 | Create the first `app_updates` record by hand | Force-update can never fire. It fails open until then — safe, but silent, so "no sheet appeared" is not evidence it works. `create_date` **must** be a Firestore `timestamp`; a string sorts below every timestamp and the query never sees it. |

`melos run deploy-firebase` is the one command for 1-3: it sends rules and
indexes together, and the functions after their own tests pass.
`sync_collection_rules_test.dart` proves the two files agree with the enum; it
can never prove the project has them, which is what the deploy did.

### Apple Developer portal / App Store Connect

| # | What | Why it matters if skipped |
|---|---|---|
| ~~6~~ | ~~Push Notifications on the App ID~~ | **Done 10 Aug.** |
| ~~7~~ | ~~HealthKit on the App ID~~ | **Done 10 Aug.** |
| 20 | Create a **Key with WeatherKit enabled** (Keys → ＋ → tick WeatherKit) | The backend has nothing to sign its JWT with, so every weather read fails. Downloadable once, and a **different** key from the APNs one. |
| 21 | Register a **Services ID** (Identifiers → Services IDs) | It is the JWT's subject. The app's Bundle ID will not work in its place. |
| ~~7b~~ | ~~App Group on both App IDs~~ | **Done 10 Aug**, on the app's App ID and on `…​.BaroEaseWidgetExtension`. |
| 8 | Create the three products — monthly $4.99, yearly $29.99, lifetime $44.99 | The paywall correctly shows "no plans available". That is not a bug to chase. |
| 9 | Sign the Paid Apps Agreement | Products stay unavailable no matter what the dashboard says. |
| 10 | App Privacy label | Must match the policy, which now says more than the old draft: Analytics and Crashlytics are tied to the account identifier while signed in, so they are **linked to identity**, and synced health data is linked too. Only Apple Health sleep/steps are collected-but-not-linked, because they never leave the device. |
| 11 | Replace the placeholder `storeLinks.appStore` id in `docs/privacy.json` | The published policy links to nothing. |

### RevenueCat

| # | What | Why it matters if skipped |
|---|---|---|
| 12 | Real keys in `env/dev.json` and `env/prod.json` | An **empty** key is handled and safe. A plausible-looking placeholder (`test_...`) is **fatal**: RevenueCat's native SDK answers a wrong-prefix key with `fatalError`, which no Dart `catch` survives and which only appears in release — i.e. on TestFlight. `RevenueCatClient.isUsableKey` now rejects those before they reach `configure`, but the right fix is a real key. |
| 13 | Attach the three products to an offering | Same visible symptom as 8 — "no plans available". |

These two have no detail section below — the survey was taken with premium
treated as finished. `CLAUDE.md`'s RevenueCat section is their authority, and
it carries the full account of the TestFlight crash behind item 12.

### Outside every console

| # | What | Why it matters if skipped |
|---|---|---|
| ~~14~~ | ~~Publish the policy~~ | **Done**, verified live 10 Aug at `…/apps_privacy_policy/baro-ease/privacy_policy/`, effective 7 Aug 2026. Note the path — the App Store field wants the app's own page, not the directory index. |
| 25 | Add the Terms of Use (EULA) link to the App Description | **This is what the 10 Aug rejection was.** Auto-renewable subscriptions need a functional EULA link in the metadata; BaroEase uses Apple's standard EULA, so the link goes in the description rather than into the custom-licence field. `docs/APP_STORE_LISTING.md` carries the wording. |
| 26 | Put Terms of Use and Privacy Policy links on the paywall itself | The same guideline (3.1.2) requires them **in the binary**, not only in metadata, and the paywall has neither today — only the Restore button. Not what was rejected, but the same rule, so it is the next one to be caught on. |
| 27 | A working Support URL | Still the `baroease.app/support` placeholder, which resolves to nothing. A dead Support URL is its own rejection. |
| 15 | Fill `[ADDRESS/COUNTRY]` in `docs/PRIVACY_POLICY.md` | The data controller's address is a GDPR requirement and is the owner's to supply. |
| 16 | Have a lawyer read the policy | Before submission. |
| 23 | Decide the export-compliance classification, then set `ITSAppUsesNonExemptEncryption` to match | `Info.plist` still says `false`, which was accurate only before the encrypted sync shipped — its own comment says to revisit when that happened, and it has. `docs/APP_ENCRYPTION.md` has the facts. Answering `true` without the self-classification report in hand can block an upload, so decide and file before flipping it. |
| 24 | The French declaration to ANSSI | Apple's step 3 was answered **Yes** — the app is distributed in France — and France expects a declaration for the import and use of cryptography. Mass-market software on standard algorithms normally takes the simplified regime, but simplified is not none. Tied to availability: drop France and this goes away, along with the answer given. |
| 22 | Put the WeatherKit `.p8` in Secret Manager | Never in the repo, never in `env/` — a `--dart-define` is a build-time value, not a secret store (hard rule 13). |
| 17 | A real-device test pass | Neither HealthKit nor push exists in the Simulator: the health sheet never appears and `getToken()` returns null. Both look identical to a refusal, so the Simulator can never confirm either one works. |
| 17b | Place the home screen widget and look at it | The extension builds, embeds and receives its data, but nothing has ever seen it drawn — the SwiftUI layout is the one unverified part. Check the log button lands on the log flow while you are there. |

### Not blocking

| # | What | Why it can wait |
|---|---|---|
| 18 | Move weather to WeatherKit | **Decided 10 Aug**: WeatherKit for everything, called only from Cloud Functions. No longer a swap of one provider — the app loses its own weather API entirely and reads through the backend, because the signing key cannot ship in a binary. Blocked on 20 and 21. |
| 19 | `FirebaseAlertRegistrationRepository` has no test | It takes concrete `FirebaseAuth`, `FirebaseMessaging` and `FirebaseFirestore`, so covering it means extracting three interfaces or adding a mocking package. Both are bigger than the gap. Item 17 is what proves it works. |

### Order

4 → 6 → 17 is the push chain, and nothing before the end of it proves push
works. 1-4 and 6 are done, so **17 is all that is left of it**.

17 is now the gate on three separate things at once — push, HealthKit and the
widget's shared container — because none of them exists on the Simulator and
each fails there in a way that looks exactly like a refusal. Everything a
device build needs (6, 7, 7b) is in place, so the next device build should
sign.

8, 9, 12 and 13 are one errand; the paywall says the same thing whichever of
them is missing.

## Detail

The sections below are the survey the checklist was drawn from, kept because
each one carries *why* a decision went the way it did. Several are struck
through: those were open when the survey was written and have since been
built, and they stay here so a reader does not go looking for work that is
already done.

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

## 2. Push notifications — only the device test is left

Checklist item 17; items 4 and 6 are done. `ios/Runner/Runner.entitlements` now declares `aps-environment` alongside
HealthKit. It says `development` on purpose: one entitlements file serves all
three build configs, and the app-store export re-signs it to `production`
from the distribution profile — hardcoding `production` would break push on
every debug build instead.

Client code in `alerts` (`firebase_alert_registration_repository.dart`:
request permission, get token, drop stale tokens) was already complete. What
is left is outside the repo:

- ~~An APNs auth key configured in the Firebase console.~~ **Done 10 Aug.**
  A `.p8`, which covers sandbox and production together — the environment is
  decided by the build's own `aps-environment`, not by anything in Firebase.
- ~~**Push Notifications enabled on the App ID.**~~ **Done 10 Aug**, in the
  same visit to Identifiers as HealthKit and the App Group.
- **A real-device test pass.** `getToken()` returns null on the Simulator (no
  APNs), which the repository already maps to
  `AlertRegistrationError.pushUnavailable` — so a Simulator refusal is
  expected behaviour, not a bug to chase.

  `sendTestPush` is what proves it, and it refuses three ways, each naming a
  different cause: `unauthenticated` (not signed in), `permission-denied`
  (signed in anonymously — an account is required), and `failed-precondition`
  (signed in, but this device never registered an `fcmToken`, so turn alerts
  on once first). The dev row that calls it is behind `!AppEnv.isProd`, so the
  build has to be the dev flavour. Premium is not required — only the cron
  filters on it.

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

## 4. Manual Firebase/Apple console setup — both consoles are done

Checklist items 4-7b and 17. Also documented in `CLAUDE.md` under "Pending
setup"; re-verified against the current repo state:

- **Rules, indexes and functions were deployed on 10 Aug** with
  `melos run deploy-firebase` (project `migraine-tracker-9f7b2`).
  `firebase firestore:indexes` reads back the `userId` + `updatedAt`
  composite index and the `payload`/`nonce`/`mac` field overrides for all
  four `SyncCollection` values, which is what proves it landed — the repo
  test can only prove the files agree with the enum.
- The `app_updates` collection doesn't exist yet — the first release record
  has to be created by hand in the Firebase console before force-update can
  ever fire (it fails open until then, which is safe but silent).
- **Push, HealthKit and the App Group were all enabled on 10 Aug**, in one
  visit to Identifiers — the App Group on both App IDs, the app's and the
  widget extension's own. What each of them still owes is a real-device pass
  (item 17): the Simulator has no APNs and no HealthKit, and App Groups work
  there unprovisioned, so it cannot confirm any of the three.
- The App Privacy label (Health & Fitness, collected-but-not-linked) is
  separate and still open — see item 10.

## 5. The privacy policy is written but not published

Checklist items 10, 11, 14, 15 and 16. `docs/PRIVACY_POLICY.md` and
`docs/privacy.json` are current as of 7 Aug 2026 and agree with each other
(hard rule 17). What is left is all outside the repo:

- **Host it.** A HealthKit app needs a reachable privacy policy URL before
  submission. `privacy.json` now points at
  `https://damhongduc.github.io/apps_privacy_policy`, but nothing is
  published there yet, and `storeLinks.appStore` is still a placeholder id.
- **Fill `[ADDRESS/COUNTRY]`** in the markdown — the data controller's
  address is the owner's to supply and is a GDPR requirement.
- The shared `defaults.sections` on the site supply retention, your rights,
  security and the rest; `privacy.json` carries only BaroEase's own sections
  and overrides `children` to read 16 rather than the shared 13.
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

Checklist item 18. In-app weather source is still Open-Meteo (the documented
temporary stand-in behind `weatherRepositoryProvider`); WeatherKit REST is the
target once a key exists.

**The pressure-alert cron is in scope too.** An earlier version of this section
said the backend would stay on Open-Meteo permanently and that this was
intentional. That is wrong — the owner's rule is one provider for the whole
app, backend included, so `functions/src/weather/openMeteo.ts` is replaced
rather than kept. Two providers would let the 3am alert disagree with the
forecast the app draws at breakfast, and the alert is the thing being paid for.

So the swap is two call sites, not one:

- `weatherRepositoryProvider` in the app, which after this reads through the
  backend rather than calling any weather API itself.
- `fetchHourlyPressure` in `functions/src/index.ts`, the cron's own source.

Both are blocked on the same three credentials (items 20, 21, 22) — the key,
the Services ID, and the `.p8` in Secret Manager.

`docs/WEATHERKIT_SETUP.md` is the step-by-step, in dependency order, and
carries two things this list does not: the JWT's exact claims (the Services ID
is the `sub`, and a Bundle ID in its place returns a bare 401), and the two
requirements that are easy to finish the migration without — rate-limiting the
callable the app can reach, and Apple's mandatory weather attribution.

## Smaller, non-blocking

- ~~Test coverage is thin in `alerts` and `weather`~~ — closed for the parts
  that can be tested in pure Dart. `alerts_controller_test.dart` covers the
  toggle, the threshold and the failure path (a failed registration must not
  leave prefs saying alerts are on), and
  `open_meteo_weather_repository_test.dart` covers the null-location branch
  both methods share — no position means no network call at all.
  `FirebaseAlertRegistrationRepository` is still untested (checklist item 19)
  and stays that way while there is no mocking package: it takes concrete
  `FirebaseAuth`, `FirebaseMessaging` and `FirebaseFirestore`, so covering it
  means either extracting interfaces for all three or adding
  `mockito`/`fake_cloud_firestore` — both bigger than the item. The
  real-device pass (item 17) is what proves it.
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
