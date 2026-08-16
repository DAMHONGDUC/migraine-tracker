# Done work

Snapshot of 16 Aug 2026. What is **built and in the repo** — the counterpart
to `REMAINING_WORK.md`, which lists what is not.

The split is deliberate and is the whole point of having two files: almost
everything left is a console, a portal or a piece of paper, and almost
everything here is code. Reading one without the other gives the wrong
impression of how far the project is.

**Where the numbers come from:** the repo at commit `f43610a`, branch
`feature/ci-cd`. 801 commits since the first one on 8 Jul 2026 — five weeks.
Version `1.0.0+13`.

| | |
|---|---|
| Dart files in `lib/` | 481 |
| Test files in `test/` | 90 |
| Features | 17 |
| Screens | 22 |
| Drift schema version | 12 |
| ARB keys, each locale | 596 en / 596 vi, zero diff either direction |
| Cloud Functions sources | 11 TypeScript files |

## The MVP scope is closed

`PLAN.md`'s MVP list is **19 of 19 checked**, and `lib/` and `functions/src/`
carry no `TODO`, `FIXME` or `UnimplementedError`. That list is the authority;
it is not restated here, because a second copy of a checklist is a second
thing to keep true.

## What shipped, by feature

One row per feature directory under `lib/features/`. "Proven by" is what
would catch a regression — a test where the thing can be tested in pure Dart,
a device pass where it cannot.

| Feature | What is built | Proven by |
|---|---|---|
| `attacks` | 3-tap log (intensity, pain map, medication) plus a skippable exertion step; collapsed detail fields; detail screen; weather snapshot attached on log and backfilled later | `test/features/attacks/` |
| `weather` | WeatherKit through the `getWeather` callable — the app has no weather API of its own; day strip, metric picker, 48h forecast chart, Apple attribution as a real link | `test/features/weather/` |
| `insights` | Correlation engine (pressure, sleep, steps, exertion), graded rather than withheld below 15 attacks; one card at a time behind a tab switch, tabs keep their state | `test/features/insights/` |
| `history` | Calendar and list views, frequency chart, scoped first-pull state | `test/features/history/` |
| `alerts` | Pressure alert registration, threshold, FCM token lifecycle; the cron that sends them is geohash-grouped and lives in `functions/` | `alerts_controller_test.dart` + item 17 |
| `medications` | Per-medication screen, local reminder notifications, 2 free across all medications | `test/features/medications/` |
| `notifications` | The in-app notification list — reminders and pressure alerts together, synced so every device shows the same list | `test/features/notifications/` |
| `health` | HealthKit sleep and steps, read-only | Device only — no HealthKit on the Simulator |
| `auth` | Anonymous by default; Google and Apple via `linkWithCredential` so the anonymous UID is upgraded, never replaced; account screen; `users/{uid}` profile doc | `test/features/auth/` |
| `sync` | Four collections (medications → reminders → attacks → notifications), AES-GCM payloads, revision-counter dirty tracking, tombstones, last-write-wins | `test/features/sync/` |
| `premium` | RevenueCat entitlement reads, paywall, restore, per-gate pitches, the free-plan readout. No client-writable premium flag exists — `DebugPremiumRepository` was deleted on purpose | `test/features/premium/` |
| `settings` | Export (JSON/CSV/PDF) with a preview and a re-shareable history, delete-all-data, contact, about, dev-only rows behind `!AppEnv.isProd` | `test/features/settings/` |
| `dashboard` | Today section that shows a free user what is free, six quick-access tiles, explore grid | `test/features/dashboard/` |
| `onboarding` | Threshold setup, coarse location permission asked once where it is explained, privacy explainer | `test/features/onboarding/` |
| `app_update` | Force-update gate, fails open, no caching so an un-block lands on the next app open | `test/features/app_update/` |
| `home_widget` | The App Group bridge and the hand-written SwiftUI WidgetKit extension in `ios/BaroEaseWidget/`; builds and embeds | Builds — nothing has seen it drawn (item 17b) |
| `review` | The store review prompt `PLAN.md` §7 asks for, after one of two value moments: a doctor report shared, or an attack logged within 24h of a pressure alert. Capped at three asks and 120 days apart | `test/features/review/` |

## Platform and backend

- **Firebase deployed 10 Aug** via `melos run deploy-firebase` — rules,
  indexes and functions together, project `migraine-tracker-9f7b2`.
  `firebase firestore:indexes` reads back the `userId` + `updatedAt`
  composite index and the `payload`/`nonce`/`mac` field overrides for all four
  `SyncCollection` values.
- **Cloud Functions** (TypeScript, Node 20, europe-west1): the alert cron and
  its geohash grouping, the `getWeather` and `getSyncKey` callables, account
  teardown, the RevenueCat webhook, the hourly weather cache.
- **WeatherKit finished 12 Aug, both halves** — the app reads through the
  backend and the alert cron reads WeatherKit too, so the 3am alert and the
  breakfast forecast can no longer disagree. `openMeteo.ts` is deleted. Live
  weather in the app is the proof: the callable cannot sign its JWT without
  the key, the Services ID and the `.p8` all being in place.
- **Apple portal, done 10 Aug**: Push Notifications, HealthKit and the App
  Group, the last on both App IDs — the app's and the widget extension's.
  APNs `.p8` uploaded to Firebase the same day.
- **Encrypted sync is server-assisted and is NOT end-to-end** — deliberately.
  `getSyncKey` holds a per-account AES-256 key in `sync_keys/{uid}`, denied to
  every client. Google infrastructure can decrypt, and the user-facing strings
  say "encrypted" and never "only you can read this". Keep it that way.
- **GDPR deletion, both halves**: "Delete all data" clears records but keeps
  the account so a subscription binding survives; "Delete account" tears the
  whole thing down through the `deleteAccount` callable in an order that
  cannot strand records. Covered by `data_wipe_service_test.dart`.

## Release engineering

The newest work, and the reason this branch exists.

- **`ci.yml`** — on every PR and every push to `main`: submodule check,
  `melos run analyze` with `--fatal-infos` (zero findings), `melos run test`,
  and the Cloud Functions build and tests as their own job. Capped at 30
  minutes so an undisposed widget tree costs half an hour, not the runner's
  six-hour default.
- **`release-ios.yml`** — manual `workflow_dispatch` with a flavor and a bump
  input: writes `env/<flavor>.json` from a secret, installs the signing
  identity through `match` in readonly mode, switches to manual signing inside
  the throwaway checkout, builds via the same `tool/build-ipa.sh` a developer
  runs by hand, uploads to TestFlight, sends the dSYMs to Crashlytics
  best-effort, then commits the build number **after** the upload succeeded.
  Capped at 60 minutes.
- **`ios/fastlane/`** — the `beta` lane, the `certificates` lane and the
  `Matchfile`. Fastlane never archives anything itself; it wraps the script.
- **`docs/RELEASE_PIPELINE.md`** is the map of all of it, as a diagram.

Every credential this needs is still outstanding — see `REMAINING_WORK.md`.
The workflow being checked in and the workflow being runnable are different
things.

## Documentation and rules

- `CLAUDE.md` split into an index plus 22 scoped files: `docs/rules/` for how
  the repo is worked in, one `CLAUDE.md` per feature, `docs/PREMIUM_RULES.md`
  as the single authority on prices and gates.
- `docs/` grouped by purpose — `rules/`, `setup/`, `release/`, `privacy/`,
  `archive/` — with `docs/README.md` as the map.
- `docs/privacy/PRIVACY_POLICY.md` and `privacy.json` agree with each other
  and the policy is **published and live** since 10 Aug.
- `docs/NEW_PROJECT_BOOTSTRAP_PROMPT.md` generalises these rules for the next
  project. It is a copy, not a source.

## Testing

90 test files mirroring `lib/features/`, plus `db_migration/` and a smoke
test. The four priorities `CLAUDE.md` names — correlation engine, Drift
migrations, pressure alert function, paywall entitlement gating — each have
dedicated tests. Twelve Drift schema versions are checked in under
`drift_schemas/`, so every migration is verified against a real prior schema
rather than against the current one.

**The one known gap is closed (16 Aug).**
`FirebaseAlertRegistrationRepository` now has 17 cases against the shipping
class. The gap had been read as a choice between extracting three interfaces
and adding a mocking package, both bigger than the gap; the third way is that
a class declaring `noSuchMethod` no longer has to implement the rest of its
interface — which is what a mocking package generates anyway. The fakes are
in `test/helpers/firebase_fakes.dart`, the production code did not change,
and nothing was added to the dependency list. Anything the repository is not
supposed to touch raises `NoSuchMethodError` naming the member.

A real-device pass (item 17) is still what proves push actually reaches a
phone — no fake can.

## What this file is not

It is not a changelog and not a plan. It says what exists **now**, so that
`REMAINING_WORK.md` can be read as a short list rather than as the whole
picture. When a remaining item closes, it moves here — one edit each, not a
new file.
