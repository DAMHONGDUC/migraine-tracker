# CLAUDE.md — BaroEase (Migraine + Barometric Pressure Tracker)

Read `PLAN.md` for full product spec before making architectural decisions.

**Every rule the owner states goes into this file, in the same turn it is
stated.** A rule that lives only in a chat is gone by the next session — write
it into the section it belongs to, with the reason, before doing the work it
governs.

## What this project is

Flutter iOS-first app for migraine sufferers sensitive to barometric pressure.
Local-first data; Firebase backend for pressure alerts, optional sign-in (Google/Apple), and encrypted attack sync for signed-in users.
Monetization: RevenueCat subscriptions ($5.99/mo, $39.99/yr, $79.99 lifetime). No ads.

## Tech stack

- **Flutter** (stable channel), Dart 3, iOS first (keep Android compiling, don't polish it yet)
- **State**: Riverpod (hooks_riverpod). No BLoC, no GetX.
- **Local DB**: Drift (SQLite). Source of truth for health data is always on-device; cloud is a synced copy, never the only copy.
- **Navigation**: go_router
- **Backend**: Firebase — Firestore (region europe-west1), Cloud Functions (TypeScript, Node 20), Cloud Scheduler, FCM, Remote Config
- **Auth**: anonymous by default (app fully usable without an account). Optional sign-in via Google (`google_sign_in`) and Apple (`sign_in_with_apple`) using `linkWithCredential` so the anonymous UID is upgraded, never replaced. Sign in with Apple is mandatory because Google login is offered (App Store 4.8).
- **Payments**: RevenueCat (`purchases_flutter`) — never call StoreKit directly, never trust client-side premium flags; premium state comes from RevenueCat entitlements
- **Sync crypto**: `cryptography` (AES-GCM, pure Dart) for record payloads, `cloud_functions` to fetch the account key from the `getSyncKey` callable. The key is server-held, so this is not end-to-end encryption — see hard rule 12.
- **Weather**: WeatherKit REST in-app is the target; Open-Meteo is the temporary in-app source until the WeatherKit key is configured (swap inside `weatherRepositoryProvider` — everything depends on the `WeatherRepository` interface). Open-Meteo in backend cron permanently.
- **Charts**: fl_chart. **PDF**: `pdf` + `printing` packages. **Health**: `health` package (HealthKit sleep, read-only)
- **Observability**: Firebase Crashlytics (crashes + non-fatals) and Firebase Analytics (usage). Both are initialized in `main` and stay no-ops until then, so tests and pure-Dart paths never touch the SDKs.
- **Files out**: `share_plus` for the share sheet, `flutter_file_dialog` for "save to device" (the platform's own save picker). `flutter_file_dialog` is below the usual ">1k likes" bar and is a deliberate exception: `file_picker` is the popular choice but every version from 8.3.3 up pins `win32 ^5.9.0`, which `share_plus` >=13.1.0 (`win32 ^6.0.1`) cannot resolve against, and there is no stable `file_picker` 12. Do not "fix" this with a `win32` dependency override — the app ships iOS first and a resolution hack to satisfy a preference is the clever-over-boring trade CLAUDE.md warns against. Revisit only when `file_picker` ships a stable release on `win32 ^6`.
- **iOS builds on CocoaPods, not Swift Package Manager.** Every plugin resolves as a pod; nothing uses SPM. Turned off in `pubspec.yaml` under `flutter: config: enable-swift-package-manager: false` — **per-project on purpose**, because `flutter config` is a per-machine setting that CI and the next clone would not inherit. (Note the key moved: `disable-swift-package-manager: true` at the `flutter:` level is the old spelling and Flutter now refuses `pub get` until it is updated.)
  - **The owner chose this deliberately**, knowing the trade. What it costs: a cold build went from ~80s to ~390s, because CocoaPods compiles all 60 pods from source where SPM had already resolved most of them. What it buys: one dependency manager instead of two, and no more of the `exact:` pin conflicts that made the whole Firebase plugin family break at once whenever one of them bumped `firebase-ios-sdk` (see the commits fixing 12.15 vs 12.17).
  - **Turning SPM back on is not just flipping that flag.** The Xcode project's SPM integration was stripped out: `XCLocalSwiftPackageReference`, `XCSwiftPackageProductDependency`, their `packageReferences`/`packageProductDependencies` lists and the `FlutterGeneratedPluginSwiftPackage` file/build-file entries are all gone from `project.pbxproj`, and both `Package.resolved` files were deleted. Flutter regenerates those when the flag is on, but check the diff rather than assuming.
  - `ios/Podfile` and its `#include?` lines in `Debug.xcconfig`/`Release.xcconfig`/`Profile.xcconfig` are load-bearing — never delete them. **All three configs exist and each points at its own Pods xcconfig**: Flutter's template ships only two and maps Profile onto `Release.xcconfig`, which makes `pod install` warn that it never set the base configuration and leaves Profile builds using the *release* pod settings. The Podfile also declares `platform :ios, '15.0'` to match `IPHONEOS_DEPLOYMENT_TARGET`; without it CocoaPods picks its own default and says so every run.
  - The build still prints `"The following plugins do not support Swift Package Manager for ios: device_info, health"`. That is Flutter reporting on the plugins themselves, not on how this project builds — expected, non-fatal, and unrelated now that nothing here uses SPM.
  - Do not "fix" that warning by bumping `health`: every version through the latest (13.3.1) caps its `device_info_plus` dependency below `win32 ^6`, which conflicts with `package_info_plus`/`share_plus`'s `win32 ^6.0.1` requirement — the same class of conflict as the `flutter_file_dialog`/`win32` note below. Don't override `win32` to force it through. Revisit only if `health` widens its `device_info_plus` range to `^13.0.0`+, or if `health` migrates off `device_info_plus` entirely.
  - If `ios/Podfile` is ever missing (e.g. after a clean checkout), `pod install` fails at the post-install hook with `Flutter.xcframework must exist`. Run `flutter precache --ios` first, then `pod install` in `ios/`.

## Repo layout

Feature-based clean architecture. Layers inside every feature use fixed
subfolder names:

```
lib/
  core/                  # cross-cutting only, NO business logic
    db/                  # AppDatabase (composes feature-owned tables), converters
    router/ theme/
  l10n/                  # ARB files (+ generated gen/)
  features/
    <feature>/
      domain/            # pure Dart, no Flutter imports
        entities/        # immutable models / value objects
        enums/
        repositories/    # abstract repository interfaces
        services/        # real domain logic (e.g. correlation engine)
      data/
        tables/          # Drift table definitions (owned here, composed in core/db)
        repositories/    # Drift/API implementations of domain interfaces
        datasources/     # API clients (e.g. WeatherKit) when needed
      presentation/
        controllers/     # Riverpod Notifiers holding view state + orchestration
        screens/         # one subfolder PER screen (see below)
          <name>_screen/ # <name>_screen.dart + its part files, together
        widgets/
      providers.dart     # Riverpod wiring for the feature
functions/               # firebase cloud functions (typescript)
test/features/           # mirrors lib/features
packages/
  system_design/      # the design system, its own git repo (submodule)
```

Features: `app_update` (force-update gate), `attacks` (Attack entity + 3-tap log), `medications`, `weather`
(WeatherSnapshot + API clients), `history`, `insights` (correlation engine),
`alerts`, `auth` (Google/Apple + linkWithCredential, account screen, `users/{uid}` profile doc), `sync`, `paywall`,
`settings`, `health` (HealthKit sleep, read-only). Create a layer folder only when it gets its first file — no empty
placeholder folders.

Dependency rule: `presentation → domain ← data` inside a feature. Across
features, import only another feature's `domain/` (or its `providers.dart`),
never its `data/` or `presentation/`. Drift tables live with their feature;
`core/db` only composes them.

## `system_design` — the design system is a separate package

String-free widgets and spacing primitives live in `packages/system_design`, a
**separate git repo checked out here as a submodule**, wired in as a path
dependency. There is exactly one import, and it is the index:

```dart
import 'package:system_design/index.dart';
```

Every widget is `Sd<Name>V2` in its own folder `v2/sd_<name>_v2/`. Adding one
is a folder, a file and one `export` line in `v2/index.dart` — see
`packages/system_design/WIDGET_RULES.md`, which is the authority on what may
go in and how it must be written. Read it before adding to the package.

`v2` is the widget generation, and everything with a look lives there. The
package's `core/` holds only what belongs to no generation — today that is
`SdSpacingConstant`, the screenutil dimensions, which is why it alone carries
no `V2` suffix.

**The palette is NOT in the package — this app owns it.** `AppColors`,
`AppTextStyle`, `AppTheme` and `AppScrollBehavior` stay in `lib/core/theme/`.
`AppTheme.dark` hands the design system its colours by registering an
`SdThemeV2` on `ThemeData.extensions`; package widgets then read
`context.colorScheme`, `context.textTheme` and `context.sdTheme` and never
name a colour. **A widget test that pumps a bare `MaterialApp` will assert** —
pass `theme: AppTheme.dark` (which `pumpApp` already does).

**A widget may move into the package only if it takes every user-facing
string as a parameter and imports nothing from this app** — no `context.l10n`,
no provider, no repository, no router, no domain entity. That is the whole
rule, and it is what keeps the package droppable into the next project.

Which is why these stay in `lib/core/widgets/`: `AppTimePickerSheet`,
`MedicationNameDialog`, `PermissionSettingsSheet` (localized copy),
`PremiumGate` (watches a provider), `SeverityBreakdownChart` (owns the app's
severity bands, then composes `SdDonutChartV2`), and `sections/` (settings
rows bound to auth / alerts / health / premium).

`context.l10n` stays in the app (`core/extensions/context_extensions.dart`);
`context.theme` / `.colorScheme` / `.textTheme` / `.sdTheme` come from the
package. A file needing both imports both — that is normal, not a smell.

Run `flutter analyze` inside `packages/system_design` too: it must pass on
its own, without the app.

## Commands

**Melos is the task runner** (`melos.yaml`). Installed once per machine at the
version `pubspec.yaml` pins — `dart pub global activate melos 6.3.3`. The
global and local versions must match exactly or melos runs one version's code
against the other's asset templates and bootstrap dies; that is why the
dependency is pinned, not caret-ranged. **Melos 6, not 7/8, on purpose** —
`melos.yaml` explains the two costs of the workspace-based versions.

- `melos run set-up` — **always wipes first** (`tool/_clean.sh`: `flutter
  clean`, gradle, pods), then everything a clone needs, in order: submodules,
  `pub get` for both packages, `gen-l10n`, `build_runner`, `env/*.json` from
  the templates, `npm ci` in `functions/`, and `pod install` on macOS.
  Idempotent — re-run it any time.
  **The wipe is unconditional on purpose**: setup is the one answer to "it
  built yesterday and not today". Don't reach for it when `melos run gen`
  would do.
  **It puts each submodule on the branch named in `.gitmodules` (`main`) and
  fast-forwards it, rather than leaving it detached at the recorded gitlink.**
  So the design system is always editable in place — and what you build is
  whatever is on that branch, NOT what the parent commit pins. When the branch
  moves ahead, `packages/system_design` shows as modified; commit that gitlink
  deliberately, and never assume an old parent commit rebuilds byte-for-byte.
- `melos run gen` — after editing Drift tables, Riverpod codegen, or ARB files
- `melos run analyze` — `--fatal-infos`, exactly what CI runs. Must pass with
  zero findings before considering any task done.
- `melos run test` — the whole suite. **Never run the whole suite to verify a change, no exception** — not even one that touches shared code (theme, spacing, the design system) and not "just before a commit" either. Always scope to what changed: `flutter test test/features/<x>/<y>_test.dart`, narrowed with `--plain-name` when one case is failing. The full suite is minutes of wall clock through the harness to re-learn what one scoped file already tells you — that cost is why this is absolute, not a judgment call per change.
- `melos run deep-set-up` — setup, plus **Xcode's DerivedData**. The only
  difference, and the reason it is separate: clearing that cache costs a full
  cold build every time. Reach for it when a build fails in a way the code
  cannot explain — a precompiled module Xcode refuses to reuse ("has been
  modified since the module file was built"), a header resolving to a version
  you no longer depend on, a failure that comes and goes on one commit —
  which is almost always right after a native dependency moved.
  **DerivedData is matched on the workspace path each cache records, never on
  the folder name**: every Flutter app builds a target called `Runner`, so
  deleting `Runner-*` would take other projects' caches with it.
- **There are exactly two entry points, `set-up` and `deep-set-up`.** The wipe
  itself is `tool/_clean.sh`, underscore-prefixed like `_common.sh` because it
  is not a command — it is never run on its own, and `melos.yaml` does not
  name it. Don't add a third clean-shaped command; the choice is only ever
  "with DerivedData or without".
- `flutter run --dart-define-from-file=env/dev.json` — Firebase config comes from `env/dev.json` / `env/prod.json` (gitignored; `env/*.example.json` are the committed key-only templates). Read config only through the `AppEnv` class (`lib/core/env/app_env.dart`) — it is the ONLY place `String.fromEnvironment` may appear; `firebase_options.dart` and everything else read `AppEnv.*`. VS Code launch configs already pass this flag (dev → `env/dev.json`, prod → `env/prod.json`).
- `cd functions && npm run build && npm test` — after touching Cloud Functions
- `firebase emulators:start` — test functions locally; never test cron against production

**Every script's body lives in `tool/<name>.sh`; `melos.yaml` only names it.**
Melos echoes the whole `run:` block before AND after each run, with no flag to
turn it off, so a multi-line body buries the output it introduces. A file is
also the only version that can be linted and run directly. Adding a command is
a `tool/*.sh` plus one line in `melos.yaml`.

Those scripts are **POSIX sh, not bash**: melos runs them through `/bin/sh`,
which is dash on Linux, where `set -o pipefail`, `[[ ]]` and `local` are
syntax errors. macOS will not catch this — its `/bin/sh` is bash under
another name — so check a change with `dash -n tool/<name>.sh`.

`tool/_common.sh` is sourced by all of them and holds the two things they
share: the SDK resolution (`fvm flutter` when `.fvmrc` and fvm are both
present, plain `flutter` otherwise — a shell alias is invisible inside a
script), and `step`/`warn`/`done_msg`, which colour their output only when
stdout is a terminal so CI logs stay readable.

## Hard rules

1. **Local-first, account optional.** Every feature except sync/alerts must work without an account. For users who are not signed in, Firestore stores ONLY: geohash (5 chars, ~5km), FCM token, alert threshold, timezone, premium flag. Signing in adds account fields to the same `users/{uid}` doc — display name, email, photo URL, created/updated timestamps — and nothing else. Attack data is uploaded ONLY for signed-in users, as encrypted payloads under `users/{uid}/attacks`, and sync must be clearly disclosed in the sign-in UI. Any other path that uploads health data: stop and flag it. This includes analytics: `AppAnalytics` events carry usage only — never intensity, head location, medication names, attack timestamps or coordinates.
2. **Location**: request While-Using + reduced accuracy only. Never request Always.
3. **Dark mode is the default theme.** Users are photophobic. No pure white backgrounds anywhere; max brightness surface is `#1C1C1E`-family. No flashing animations.
4. **Attack logging must work fully offline.** Weather snapshot is fetched best-effort and backfilled later if offline.
5. **The 3-tap log flow is sacred**: intensity → head location → medication → saved. Any new required field in this flow needs explicit approval. Optional fields go behind "Add details".
6. Every user-facing string goes through `intl` ARB files. Two locales ship in v1: `app_en.arb` (template, with `@` descriptions) and `app_vi.arb` — every new key must be added to BOTH. Access strings via the `context.l10n` extension (`core/extensions/context_extensions.dart`), never `AppLocalizations.of(context)` directly. The user's language choice lives in `localeControllerProvider` (persisted via shared_preferences; null = follow system).
7. Pressure math: alerts trigger on **delta** (default ≥5 hPa drop within 24h forecast), not absolute values. Threshold is user-tunable and stored per-user.
8. GDPR: `settings/` must always keep working "Export all data (JSON/CSV)" and "Delete everything" (local wipe + Firestore doc + synced attacks delete + FCM token revoke + Firebase Auth account deletion). In-app account deletion is an App Store requirement (5.1.1(v)) now that accounts exist. Export lives on its own screen and keeps a history: each export is written to the app's documents directory and recorded, so it can be re-shared or saved to the device later. That makes past exports full copies of the user's health data on disk — **the wipe MUST delete the export files and their rows too**, or "delete everything" leaves the data sitting in `Documents/exports/`. Anything new that persists a copy of health data inherits the same obligation.
9. **Force update fails open.** The launch check (`app_update`) reads the public, read-only `app_updates` collection and blocks ONLY on an explicit `enable_force_update` against a strictly newer `build_number`. Offline, a missing record, an unreadable field or a malformed link must let the user in — someone mid-attack has to reach the log button. Compare `build_name` first (via `VersionUtils`, segment by segment as numbers — never as strings, `"1.10.0" < "1.9.0"` is true for a string), then `build_number` as the tiebreaker for two builds of the same version.
10. Cloud Functions: group users by geohash before calling weather APIs — one forecast call per cell, never per user. Dedupe alerts: max 1 push per user per 24h per pressure event.
11. Medical disclaimer must appear in onboarding and App Store description. Never generate copy that promises diagnosis, treatment, or prevention.
12. **Sync (signed-in users) never blocks UI — automatic, with one manual control in Settings.** Sync runs silently in the background: triggered on sign-in, on app launch/resume, and after logging a new attack, same best-effort/retry-on-next-launch shape as `WeatherAttachService` — no screen, especially the log flow, ever waits on it (hard rule 4). **Three kinds of record sync**, in this order and for this reason: medications, then their reminders (a reminder points at a medication, so the other order hits a foreign key that is not there yet), then attacks. Export records deliberately do NOT sync — `filePath` is local to one device, and uploading them would multiply the copies hard rule 8 has to chase.
    - **The one visible control is a row in Settings' "Your data"** (`SyncSettingsTile`, `core/widgets/sections/sync_settings_tile.dart`), sitting with export and delete because sync is one more thing that happens to the user's data. Tapping it runs a sync; the row's trailing slot is a spinner while one is in flight (`SdSpacingConstant.r20` box, `CircularProgressIndicator(strokeWidth: 2)`, same as `_DevResetTile`), and otherwise carries the status — when it last finished, "Not synced yet", or "Didn't finish". The row is absent without an account. **Nothing about sync appears on the Account screen**, and no other row anywhere shows an indicator.
    - The History list has ONE extra, scoped to the very first pull after signing in on a device: an empty list there says "getting your attacks" instead of "you have none", because it is empty only because the history has not arrived yet. No flow is ever gated on sync completing.
    - **Built. Sync is encrypted but NOT end-to-end, and the copy must never imply otherwise.** The `getSyncKey` callable mints and holds a per-account AES-256 key in `sync_keys/{uid}`, which `firestore.rules` denies to every client — only the Admin SDK behind that function reaches it, and anonymous callers are refused (hard rule 1). Google infrastructure can therefore decrypt. `loginPrivacyNote` and `accountDataNote` say "encrypted" and deliberately never say "only you can read them"; keep any new copy to that bar.
    - **Local change tracking is a `revision` counter, never a timestamp.** Drift stores dates as whole seconds, so an edit in the same second as the push before it looks unchanged and silently never syncs; a counter also survives the clock stepping backwards. `updatedAt` still exists on each synced table but only settles which device's version wins. Deleting really deletes the row and leaves a `SyncTombstones` entry holding the opaque id and its collection — no intensity, note or medication name may outlive a delete, and reads then need no filter that could be forgotten. **Deleting a medication tombstones its reminders too**: the FK cascade removes them on every device that pulls the deletion, but the server's copies belong to no cascade.
    - **Mark synced only after the server confirms, and pull before pushing.** A kill mid-pass must cost a re-push, never a lost record. Pull goes first because the other order re-downloads everything it just uploaded (a device signing in has no cursor). A payload that will not decrypt is counted and skipped, never retried forever — one bad record must not wedge every later one behind it. Each collection keeps its own cursor, so a pull that failed on reminders cannot look finished because attacks got through.
    - **Reminders sync as rows; their OS notifications do not.** A notification is registered with the device that made it, so a reminder pulled from another phone would sit in the list and never fire. A pull that brought reminders down calls `RemindersController.rescheduleAll()`, which reads its strings through `lookupAppLocalizations` — there is no `BuildContext` in a background sync.
    - **A payload codec refuses only versions NEWER than it knows, never merely different**, and ignores fields it does not recognise. The first bump would otherwise orphan every record already uploaded, and adding an optional field would stop two builds in the wild reading each other.
    - **`pumpApp` overrides `syncKeyRepositoryProvider` and `remoteSyncRepositoryProvider`** with the fakes in `test/helpers/sync_fakes.dart`, because the app root fires a sync on sign-in. Without them a widget test reaches for Firebase, the sync spinner renders, and every `pumpAndSettle` waits out its full 10-minute timeout — the suite goes from 30 seconds to 10 minutes.
    - **The GDPR wipe deletes the account's synced records BEFORE the device's**, and a failure there aborts the whole wipe. The other order leaves the cloud copy with nothing left to say it should go, and the next sync pulls every deleted record back down. What the wipe still misses is listed in `docs/REMAINING_WORK.md`.

## Code style

- Small widgets, extract at ~80 lines. Prefer composition over config flags.
- No business logic in widgets. View state and orchestration (state machines, save/export/delete flows, filtering) live in a `presentation/controllers/` Notifier or a `Ref`-backed controller; screens are `ConsumerWidget`s that watch state and call controller methods. Dialogs/snackbars stay in the widget.
- **Controllers log their own failures: process first, print the error if one lands.** Every `presentation/controllers/` method that touches a repository, service or platform plugin wraps its work in `try` / `catch (error, stackTrace)`, calls `AppLogger.error('<what failed>', error: error, stackTrace: stackTrace)` (`core/logging/app_logger.dart`), then `rethrow`s — the log is an extra pair of eyes, never a replacement for the caller's error handling. Plain `try`/`catch` inline, always: no closure-taking wrapper (an `AppLogger.guard(action)`-style combinator hides the flow), and never `print(...)`. Cancellation is not a failure — `LoginController` stays silent on `AuthError.cancelled`. Controllers that only hold state (`HistoryController`, `MedicationFiltersController`) have nothing to catch and stay bare.
- Snackbars: always `SdSnackBarUtilsV2.success/error/info` (`system_design`) — never raw `ScaffoldMessenger.showSnackBar`. It draws the app's own card (dark surface, accent icon + hairline edge, never a full-bleed colour fill) and shows one message at a time. Pass a finished localized string; the kind picks the icon and accent, and the icon always differs so colour is never the only signal. **It draws into the root `Overlay`, not a `ScaffoldMessenger`** — a messenger renders into the nearest registered `Scaffold`, so a route without one (the paywall sheet) sent its messages to the screen *underneath*, where the very sheet that raised them covered them up. Widget tests did not catch it: `find.text` matches a widget the user cannot see. Placement is a second prop — `SdSnackBarPlacementV2.bottom` is the default and what every screen wants, `top` is for a route that owns the bottom of the screen, which today is the paywall alone. Assert on `SdSnackBarCardV2`, the only public handle on what a static presenter drew.
- Dialogs: always `showSdDialogV2` + `SdDialogV2`/`SdDialogOptionV2` (`system_design`) — never raw `showDialog`. Sheets: always `showSdBottomSheetV2` (`system_design`) — it uses the root navigator so sheets cover the bottom nav; raw `showModalBottomSheet` slides under it.
- Animations must be calm (fade/scale/slide, ≤400ms, gentle curves). Hard rule 3: never flashing or strobing. Use `SdPressableScaleV2` (`system_design`) for tactile button feedback.
- Responsive sizing via `flutter_screenutil` (design size 393×852, `minTextAdapt: true`), but NEVER as raw literals in widgets — every dimension goes through `SdSpacingConstant` (`system_design`): `w*` horizontal, `h*` vertical, `r*` square/radius, `sp*` font. Colors likewise only via `AppColors` (`system_design`).
- **One modal colour, and bottom sheets and dialogs both wear it: `AppColors.surfaceModal` (`#161618`).** A dialog opening over a sheet must never be a second shade of dark, so they read the same `SdThemeV2.surfaceModal` slot — the sheet used to take `colorScheme.surface` and the dialog `surfaceElevated`, which is exactly the drift this closes. It sits a step *below* the card rather than above it: a modal already separates itself with the barrier scrim and its rounded corners, and going darker keeps a card placed on it reading as the nearer layer. `ThemeData.dialogTheme` carries the same colour so a raw `showDialog` cannot come out different.
- **Every card is an `SdCardV2`** (`system_design`) — never a raw `Material` `Card` in feature or core code. It is the card colour and the card radius (`SdCardV2.radius`) and nothing else: **no padding and no margin**, because Material's `Card` carries an invisible `EdgeInsets.all(4)` that made a list whose separator said 8 come out 16, and sit 8 narrower than the list on the next tab. Spacing between cards belongs to whoever places them, the inset inside belongs to whatever they hold, and `onTap` on the card clips its own ink to the radius. `SdChartCardV2` and `SdBannerV2` compose it. `ThemeData.cardTheme` stays as a backstop for any `Card` Flutter builds internally, on the same colour and the same zero margin.
- **One card colour: `AppColors.surface`.** Every card — dashboard, insights, `SdChartCardV2`, every `Card` via `cardTheme` — is `#1C1C1E`. Sheets are flat and opaque, never Liquid Glass, but they take the darker modal colour above, not this one. Anything that has to stay visible while sitting *on* a card, a sheet or a dialog is a step up in `AppColors.surfaceElevated` (snack bars, chart tooltips, the log flow's option tiles, filter chips) — a tile left on `surface` disappears the moment its sheet is that colour. Liquid Glass is for chrome — app bar, the shell's nav pill, the log flow's step bar, a sheet header's two `SdAppBarButtonV2`s — plus one deliberate surface: the **paywall** panel stays frosted glass, unlike every other sheet.
- **The app ships no UI font — `AppTextStyle` sets no `fontFamily`, on purpose.** Flutter falls through to the platform's own: SF Pro on iOS, Roboto on Android. That is the right default for an iOS-first app (SF Pro has optical sizing, full Dynamic Type and correct Vietnamese diacritics), and Apple's licence forbids bundling SF Pro anyway. A missing `fontFamily` here is the decision, not an oversight. `assets/fonts/noto_sans/` is **not** a UI font: `ExportController` loads it through `rootBundle` for the PDF report, which needs a font it can embed — don't register it under `fonts:` and don't delete it as unused. Shipping one font for both platforms means Inter, not Roboto (Roboto reads as Android on an iPhone), and means re-checking the type scale: Inter's x-height is taller than SF Pro's, so the same `fontSize` renders larger.
- Text: every style comes from `AppTextStyle` (`system_design`) — no inline `TextStyle(...)` and no `context.textTheme`/`Theme.of(context).textTheme` in widgets (the extension getter was removed on purpose). Font sizes go through `SdSpacingConstant.sp*` (screenutil); line heights are shared `_height*` ratio constants in `AppTextStyle`. Because of `.sp`, widget tests MUST pin the view to the 393×852 design size — `pumpApp` already does this; the default 800×600 test surface scales fonts ~2× and breaks layout. Use the `.secondary` / `.w600` helpers on `AppTextStyle` (the package's own are `.muted(context)` / `.semiBold`) for muted color and semi-bold; other tweaks via `copyWith`. `AppTheme` feeds `AppTextStyle` into `ThemeData.textTheme` so ambient defaults match.
- **Icons: every icon is an `SdIconV2`** (`system_design`) — never a raw `Icon(...)` in feature or core code (the only raw `Icon` lives inside `SdIconV2`). `SdIconV2` always resolves to a concrete size: it defaults to `SdSpacingConstant.r24`, and any other size is passed explicitly via `size:` (never let an icon inherit an ambient size). `color` falls back to the ambient `IconTheme` when omitted.
- Buttons: every labeled button is an `SdButtonV2` (`system_design`), and **the look is a prop, never a named constructor** — `SdButtonV2(variant: SdButtonVariantV2.primary, ...)`. Variants: `primary` (main CTA), `secondary` (tonal), `outlined`, `text` (low emphasis / dialog cancel), `destructive` (error-filled confirm), `positive` (teal additive). Never raw `FilledButton`/`OutlinedButton`/`TextButton` in feature code. **Icon-only actions in an app bar — leading back arrow and trailing actions alike — are `SdAppBarButtonV2`** (`system_design`), never a raw `IconButton`: `SdAppBarButtonV2.iconSize` (20) glyph inside an invisible `SdAppBarButtonV2.tapSize` (48) target, and a `SdPopScaleV2` swell on touch (it grows out from under the fingertip; a press-*in* would vanish under it). `SdAppBarV2` inserts one for any route that can pop, and wraps each `SdAppBarButtonV2` action in the glass circle — an action that is not one passes through undecorated. `IconButton` is still fine inside content (list rows, text-field suffixes). With an `icon`, `SdButtonV2` lays the content out itself — `SdButtonV2.iconSize` glyph, `SdButtonV2.iconGap`, then the label — and deliberately avoids Material's `.icon` constructors, whose per-variant padding is what made the filled Apple button and the outlined Google button sit differently. Placement is a second prop: `SdButtonIconPlacementV2.inline` (default) is a centred cluster that shrink-wraps, so a longer label pushes the glyph sideways; `aligned` is the same centred cluster with the label start-aligned in a slot of `SdButtonV2.alignedLabelWidth`, so **stacked buttons put their glyphs on the same x and start their labels on the same x whatever the label lengths** — that is what the login screen's Apple/Google pair uses. The slot is a minimum, not a cage: a label too long for it widens, then wraps, and never ellipses. The glyph is `SdButtonV2.defaultIconSize` unless a call site passes `iconSize` (an `SdSpacingConstant.r*`, never a raw number) to optically correct a brand mark — under `aligned` that resizes the glyph but not the slot it is centred in, so the pair stays lined up. **Padding is one fixed value for every variant, not a per-variant default**: `SdContentPaddingV2.button`, so a filled, outlined and text button never sit a different size next to each other. `size` (`SdButtonSizeV2.small` / `medium` / `large`, scale 0.75 / 1 / 1.25) multiplies that padding plus the icon and icon gap together, so a smaller button is a scaled-down version of the same shape, never a differently-proportioned one — `medium` is the default and unscaled. **A labeled `SdButtonV2` placed in an app bar's actions (`SdScaffoldV2.actions`) is always `size: SdButtonSizeV2.small`** — see `LogScreen`'s "Next" button. `compact` (chrome-sized app-bar buttons) forces this scale on its own regardless of what `size` a call site passes, so the two can never disagree; a plain `size: small` without `compact` still gets the scaled icon/padding but not `compact`'s own tighter fixed padding and `h34` minimum height.
- **Analytics: every event goes through `AppAnalytics`** (`core/analytics/app_analytics.dart`) — a typed method per event, so the full inventory of what we send is one file. Never call `FirebaseAnalytics` directly and never type an event name at a call site. Events live next to the matching `AppLogger.action` in a `presentation/controllers/` Notifier, never in a widget's build. Health data never becomes a parameter (hard rule 1).
- **Crash reporting goes through `CrashReporter`** (`core/logging/crash_reporter.dart`): `recordError` for a caught failure worth seeing in production, alongside the `AppLogger.error` that serves the debug console. `domain/` stays pure Dart — report from the presentation/data layer that catches it.
- Repositories: interface in `domain/`, impl in `data/`; return domain models, never Drift rows.
- Correlation engine stays pure Dart with unit tests (this is the "insight" users pay for — test edge cases: <15 attacks, all-same-weather, timezone shifts).
- **HealthKit is read-only, iOS-only, and nothing it returns is persisted.** `health` reads `SLEEP_IN_BED` and only that: this plugin version maps IN_BED / ASLEEP / AWAKE onto the same `HKCategoryType.sleepAnalysis` and drops the category value before Dart sees it, so asking for all three returns the same samples three times and none can be told apart — take one type and union the intervals (`SleepNightAggregator`). Sleep is queried on demand for the analysis window and never written to Drift: HealthKit is already on-device storage, and a copy here would be one more pile of health data the wipe has to chase (hard rule 8). iOS never reports a *read* denial (that would leak which conditions a user has), so `requestAuthorization` returning true proves only that the sheet was answered — treat an empty read as "no access or no data" and never as an error. The connect switch lives in Settings and is the only place the prompt is raised; everything else reads `healthControllerProvider`.
- Cloud Functions: idempotent, log with structured JSON, fail loud on weather API errors (retry with backoff), never silently skip a user cohort.
- Commit style: conventional commits (`feat:`, `fix:`, `chore:`). No parenthetical scope — write the scope inline after the colon, then a dash: `feat: medications - a screen per medication`, never `feat(medications): a screen per medication`. No `Co-Authored-By` trailer. **The scope is never `claude`** (e.g. never `chore: claude - listItemGap covers item spacing`) — the scope names the part of the app touched, not who or what made the change; a handful of earlier commits on this repo got this wrong and are grandfathered, not a pattern to continue.
- **Commit freely; never push.** Every commit (app repo and the `system_design` submodule alike) stays local until the owner explicitly asks for a push — the owner reviews and pushes themselves. Don't run `git push` (or `git push --force*`) on your own initiative, even after a commit that would previously have been pushed as a matter of course.
- **Any edit to this file gets its own commit, right away** — a CLAUDE.md change never rides along uncommitted or folded into an unrelated commit. Message: `docs: update docs - detail is <what changed>`.
- **PR descriptions are short bullets, never prose.** A one-line summary, then bulleted groups — one line per bullet, about a screen in total. No explanatory paragraphs, no quoting source in the body. The *why* belongs in the commit message and the code comment, which reviewers reach from the diff; a PR body they have to read twice gets skimmed instead. **No mention of Claude anywhere in a PR description** — no attribution footer (e.g. "Generated with Claude Code"), no "Claude did X" phrasing, nothing naming the tool at all; the description reads like the person who owns the repo wrote it.
- **No standalone top-level functions.** Every function lives inside a class — a widget method, or a static/instance method on a utility class (`DateUtils`, `StringUtils`, `ValidatorUtils`). Never a floating `void doSomething() {}` at file scope. The one sanctioned exception is a widget's `.show()` extension (see "Bottom sheets" below); the shared `core/widgets` primitives `showSdDialogV2`/`showSdBottomSheetV2`/`showSdFilterSheetV2` stay as-is (they are the low-level presenters those extensions call).
- **A sheet with actions wears `SdSheetHeaderV2`** (`system_design`): X on the left that leaves, title centred, commit on the right — both are `SdAppBarButtonV2`s wearing `SdAppBarButtonSurfaceV2.glassCircle` (the sheet is a flat opaque panel, so a frosted disc on it has real background to refract), the commit's glyph tinted `AppColors.secondary` so the action that writes something still reads differently from the one that abandons. Its glyph is a tick for `SdSheetActionV2.confirm` (answering something for the first time) or a pencil for `SdSheetActionV2.edit` (overwriting a value that already exists). It brings its own insets; nothing pads around it. `SdSheetContentV2` (`system_design`) is that header plus content that scrolls under a ceiling of 85% of the screen and an optional pinned footer — pass `isScrollControlled: true` when showing it or the route caps itself near half the screen and the ceiling never applies.
- **Bottom sheets and dialogs: widget + `.show()` extension, never a top-level `showX()`.** A sheet/dialog is a widget class (`FooSheet extends StatelessWidget`, public so callers can construct it), and its opener is an extension on that widget exposing `Future<T?> show(BuildContext context) => showSdBottomSheetV2<T>(context, builder: (_) => this);` (sheets) or `showSdDialogV2<T>(...)` (dialogs). Name the extension `<Widget>Ext`. Call it as `FooSheet(...).show(context)` — never `showFooSheet(context, ...)`. This keeps presentation off file-scope functions (rule 1) while still routing through `showSdBottomSheetV2`/`showSdDialogV2` (root navigator, calm animation). A sheet/dialog opener with no dedicated widget (a thin wrapper over the generic `showSdFilterSheetV2`) is dead weight — inline the generic presenter at the call site instead.
- **No `_buildX()` methods for UI.** Do not split `build()` into helper methods like `Widget _buildHeader()` / `Widget _buildList()` inside a `State`. Extract UI into a separate widget class (`StatelessWidget`/`StatefulWidget`) so Flutter can scope rebuilds (const, keys) instead of rebuilding the whole parent — a method split is a fake split.
- **Split big presentation files with `part of`.** When a screen/page under `presentation/` accumulates many private child widgets, move them into sibling files joined via `part of` (not one giant file; `main.dart` is exempt). Name child files `<main_file>_<widget>.dart` — e.g. `home_page.dart` + `home_page_header.dart` with `part of 'home_page.dart';`.
- **One folder per screen under `presentation/screens/`.** Each screen gets its own subfolder named after the screen file: `presentation/screens/<name>_screen/` holds `<name>_screen.dart` and all of its `part` files. Screens never sit loose directly in `screens/`.
- **No `abstract final class` — plain `final class`.** Static-only holders (`AppLogger`, `AppColors`, `AppTextStyle`, `AppTheme`, `SdSpacingConstant`, `AppEnv`, `AppRoutes`, `SdSnackBarUtilsV2`, `NavigationUtils`, …) are declared `final class`. `abstract` is reserved for contracts that are actually implemented: every `domain/repositories/` and `domain/services/` interface stays `abstract interface class`.
- **Never use `var`.** Always declare explicit types (`final String name = ...`, `int count = 0`, `List<Item> items = []`). Prefer `final`/`const` with an explicit type. Explicit types keep reviews clear and prevent silent type-inference bugs.
- **Anything shared gets extracted — a widget, or a `*Utils` class.** The second copy is the trigger, not a later cleanup: duplicated UI becomes a widget in `core/widgets/` (or the feature's `presentation/widgets/` if only that feature uses it), duplicated logic becomes a static method on a `*Utils` class (`NavigationUtils`, `SdSnackBarUtilsV2`). Same in `test/` — shared setup and navigation helpers live in `test/helpers/`, never re-declared per file.
- **A widget used by more than one feature lives in `core/widgets/`, always — and that is the only `widgets/` folder in `core/`.** The moment a second feature needs it, it moves: `presentation/widgets/` is for widgets that feature alone builds. Otherwise the importer reaches into another feature's `presentation/` and breaks the dependency rule — that is how `PremiumGate` (insights + settings + premium) and `MedicationNameDialog` (attacks + medications) ended up cross-imported before they moved. A shared widget may import a feature's `domain/` or `providers.dart` (`premium_gate.dart` watches `hasPremiumProvider`; `charts/severity_breakdown_chart.dart` reads `chart_analytics.dart`) — core → feature is fine, feature → feature `presentation/` is not. Never open a `widgets/` folder elsewhere under `core/`: a sheet a subsystem shows (`permission_settings_sheet.dart`) goes in `core/widgets/` and imports back into its subsystem, not the reverse.
- **Comments: short and plain.** One or two lines. Say *why*, not what the code already says — and say it in the fewest words that still land. No paragraphs, no essays, no restating the diff.
- **Multi-point comments are bullet lists, one `//` line per point, each starting with `-`.** The moment a comment needs more than one point, it stops being a sentence with a conjunction and becomes a list — no run-on `// does X, and also Y, but watch out for Z`. Each bullet stays short and plain per the rule above; a single-point comment stays a single plain line, no dash.
- **A comment is never more than 3 lines**, bulleted or not. If it needs a 4th, the comment is doing too much — cut to the one reason that matters, or split it: a "why" for the line it sits on stays here, a longer "how"/design rationale moves into the doc comment (`///`) of the function or class it belongs to.
- **Declarations first, blank line, then logic.** Group all variable/constant declarations at the top of a method with no blank lines between them, then one blank line before the logic block (conditions, loops, calls, `return`). Don't interleave — never declare, run logic, then declare again lower down.
- **Every list in the app puts the same gap between its items: `SdContentPaddingV2.listItemGap` (8).** One value, never a per-screen `SdSpacingConstant.h8` — the attack list, the calendar day's attacks and the medications list each spelled the same 8 out separately, and three copies of a number is three chances to disagree. Lists of `ListTile`s are a different mechanic and take no gap at all: those rows carry their own insets and sit flush (Settings, the export history). **This is the one gap for all item spacing, not a per-list convention** — any place that spaces one item from the next uses `listItemGap`, never a raw `SdSpacingConstant.h*` typed in again. **The gap from a filter row down to the list below it is the same `listItemGap`, not a screen's own spacing value** — a filter sits above its list like one more item above the first, so it takes the item gap, not a bespoke number.
- **A different gap for stacking whole cards/sections on a screen: `SdContentPaddingV2.sectionGap` (20).** Dashboard's mixed cards (banner, week summary, severity, explore) and Insights' correlation/forecast/sleep cards both read this — one value, so the two screens' section rhythm cannot drift apart, same reasoning as `listItemGap` one level up. Not the same thing as `listItemGap`: a section is a distinct card, not one row of a repeated list, so it gets the roomier number. Never a raw `SdSpacingConstant.h*` at a call site for this.
- **No widget or class holds spacing logic — `SdContentPaddingV2` does, and nothing else.** Not `SdScaffoldV2`, not `SdAppBarV2`, not a screen: any inset another widget pads by is a static on that one class. Widgets keep only their own intrinsic size (`SdPinnedFilterBarV2.barHeight`, `SdAppBarV2.preferredSize`).
- **One spacing rule for all content, and one class that computes it: `SdContentPaddingV2`** (`system_design`). Content sits **`topGap` (8) below the app bar**, **the bottom depends on what is below**: a tab screen clears the nav pill and then `bottomGap` (16), while every other screen takes `detailBottom` — the device's safe area floored at `minDetailBottom` (20), with no gap stacked on top, because a device reporting 34 already gives more room than the floor asks for, **`horizontal` (16) either side** — the two vertical gaps are separate fields, so the edge under the chrome and the edge above the thumb can move independently — `SdContentPaddingV2.screen(context)` is that, `fullBleed(context)` drops the gutter for rows that inset themselves (a `ListTile`), and `floatingNav: true` additionally clears the shell's nav pill on the five tab screens — `navBarOffset` + `floatingBarHeight` + `bottomGap`, so scrolling a tab screen to its end leaves exactly `bottomGap` of daylight between the last item and the pill. **`navBarOffset` is the pill's own rule and the one place it lives**: the device's own bottom inset, clamped between `minNavBarOffset` (16) and `maxNavBarOffset` (20). The floor covers a device asking for too little — no indicator at all (a Home-button phone, most Androids, the default test view) or a shallow one (an iPad, landscape). The ceiling keeps a deep inset from pushing the pill up the screen, and **costs system clearance on a portrait iPhone**: its indicator inset is 34, so the pill lands 14 short and its lower edge sits inside the strip iOS reserves for the indicator and the edge-swipe gesture. Deliberate — raise `maxNavBarOffset` to 34 to give that back. The log flow's step bar does NOT clamp: it rests on the full inset, so the two bars legitimately differ. The log flow's step bar does not follow it — that one always rests on the safe area (`bottomBar`). `floatingBarHeight` (and `floatingBarRadius`, half of it) is the ONE height for both floating bars: the nav pill and the log flow's step bar read it, neither types its own, because the day they disagreed the difference was eaten out of the gap above them. **Bottom insets come off the view, not the ambient `MediaQuery`, exactly like `appBarInset` at the top**: `Scaffold` subtracts `padding.bottom` from its body's `viewPadding.bottom` whenever there is a `bottomNavigationBar`, so an ambient read inside the shell loses the home indicator entirely and the last row lands *under* the pill — a bug that costs 0 pixels in a test whose view has no insets. Never read `MediaQuery.paddingOf(...)` for content spacing at a call site and never re-add an inset the class already applied.
- **`SdScaffoldV2` adds no padding at all** — no SafeArea, no insets. Every screen pads its own scrollable via `SdContentPaddingV2`, applied **inside** the scrollable so content still scrolls *behind* the frosted bar. A scaffold-level SafeArea plus a body that also clears a floating bar is how insets used to get applied twice.
- **Insets come off the window, not the ambient `MediaQuery`.** `Scaffold` strips its body's top padding when there is an app bar (and its bottom under `extendBody`), so the same read returns different numbers above vs inside the body. `SdContentPaddingV2` reads the view; feature code reads `SdContentPaddingV2`. The default test view has no notch, so a bug here costs 0 pixels in every widget test — see `test/core/constants/app_content_padding_test.dart`, which gives the view one.
- **Every `Text` carries an explicit `style:`.** Never lean on the ambient `ThemeData.textTheme`, even where it would look identical — the default is invisible at the call site and silently drifts when a theme changes. Use the style the surface already implies: app-bar titles `AppTextStyle.titleLarge`, `ListTile.title` `bodyLarge`, `ListTile.subtitle` `bodyMedium.secondary`, `SnackBar.content` `bodyMedium`.
- **A filter over a scrolling list: `SdCollapsingFilterScaffoldV2`** (`system_design`), used in place of `SdScaffoldV2` — never hand-rolled, and never a `Stack` + `SdPinnedFilterBarV2` assembled at the call site again. It gives the screen one behaviour: the filter row sits in a frosted strip under the app bar while reading, and as soon as the list scrolls on it **lifts into the app bar, whose `title` and `actions` step aside**; scroll back the other way (or reach the top) and everything returns. Pass the filter as a **bare row of chips** — both places supply the horizontal scrolling, so a scroll view of your own nests two. `filter: null` is "nothing to filter yet" (an empty export history): no strip, no hand-off. `collapsible: false` pins it all in place for a bar that something else owns (the medications tab while its search field is up). **The body pads its own top and that inset must not change with the collapse** — `SdContentPaddingV2.belowPinnedFilterBar` throughout, so the reserved strip height (only ever visible while expanded) can't make content jump mid-scroll. Used by `medications_screen` and `export_screen`; History's own pill lives IN its list and is a different mechanic.
- **Screens with content plus a bottom action: `SdActionViewV2`** (`system_design`), passed straight as `SdScaffoldV2.body` — never hand-rolled. It is content on top, `actions` hugging the bottom edge, `spaceBetween` between them, and it owns the two things every such screen otherwise forgets: the vertical insets (straight from `SdContentPaddingV2`) and the minimum height that gives `spaceBetween` its free space. Nothing inside `content` adds a top gap of its own — the view already applied the screen's. `actions` is a stretched `Column`, so buttons come out full width and equal to each other. It scrolls itself — long locales and large accessibility text sizes overflow a fixed `Column`, and a bare `ListView` is wrong here because under short content the buttons drift up into the middle. Used by `login_screen`, `account_screen`, `premium_screen`.
- **The bottom action sits 16 above the safe area, never twice.** On a screen that is `SdContentPaddingV2`'s business, the class has already applied it — don't add the inset again, and don't leave the button flush against the home indicator. Sheet routes still take `MediaQuery.paddingOf(context).bottom + h16` themselves (they are not screens). Floating chrome is exempt and each one has its own line: the shell's nav pill sits `SdContentPaddingV2.navBarOffset` off the bottom edge, the log flow's step bar rests on the safe area.
- **Shared navigation lives in `NavigationUtils`** (`core/router/navigation_utils.dart`). A plain "push this route" belongs at its call site; a move with a *rule* attached — an order of screens, or a condition deciding where the user lands — goes in `NavigationUtils` so the second caller cannot reimplement it without the rule.
- **Two doors, and every gate uses one of them.** A premium-locked surface opens the paywall sheet via `NavigationUtils.toPaywall`, signed in or not; the paywall itself asks the account question ("Sign in to continue" → `NavigationUtils.toLogin`, then it comes back offering the purchase). The Settings sign-in row is the only other way in, also `toLogin`. Never `pushNamed(AppRoutes.paywall...)` at a call site, and never put a login screen in front of a paywall the user has not been shown yet — the pitch comes first.

## Pending setup — the owner does this by hand, don't assume it exists

Force update (`app_update`) is coded and tested, but nothing on the Firebase
side is done yet. Until all three land, the launch check reads nothing and
fails open — which is the safe state, and also a silent one, so don't read
"no sheet appeared" as "it works".

1. **`firestore.rules` is not deployed.** The `app_updates` block exists in
   the repo only. Until `firebase deploy --only firestore:rules` runs, the
   client read returns `permission-denied` and the check silently fails open.
2. **The `app_updates` collection does not exist.** Records are published by
   hand from the Firebase console — schema and field types are documented on
   `AppUpdateMapper`. `create_date` MUST be a Firestore `timestamp`: Firestore
   orders mixed types by type, so one record saved as a string sorts below
   every timestamp and `orderBy(create_date, desc).limit(1)` will never see
   it. Publish a NEW document per release; never edit the previous one.
   Flip `enable_force_update` to true only once that build is live on both
   stores.
3. **No caching — deliberately.** Every entry into the app (cold start and
   each resume) is one Firestore document read. That is what makes an
   emergency un-block take effect on the next app open, unlike Remote
   Config's 12h cache. If the read volume ever matters, cache the record in
   memory and refetch after N minutes — decide the N against how fast an
   un-block has to reach users, and never cache the "blocked" verdict longer
   than the "not blocked" one.

Also note `env/dev.json` and `env/prod.json` point at the SAME Firebase
project, so a blocking record written while testing hits real users too.
Fix that with a separate dev project, or wire the Firestore emulator behind
`!AppEnv.isProd` before testing a blocking record post-launch.

### HealthKit — code and Xcode project are done, the portal side is not

`ios/Runner/Runner.entitlements` (checked in, wired into all three Runner
build configs), the `com.apple.HealthKit` target capability and BOTH health
usage strings all exist. What is NOT in the repo, because it cannot be:

**Both strings are mandatory even though the app only reads.**
`NSHealthUpdateUsageDescription` looks unnecessary — the plugin calls
`requestAuthorization(toShare: nil, …)`, so nothing is ever written and iOS
never shows that string. But App Store Connect's validator keys off the
**entitlement**, not off actual API usage: with `com.apple.developer.healthkit`
present it rejects the upload with `ITMS-90683 — Missing purpose string in
Info.plist … should contain a NSHealthUpdateUsageDescription key`, and the
build never reaches TestFlight. Do not "clean up" that string as dead config.

1. **HealthKit on the App ID.** The App ID behind
   `PRODUCT_BUNDLE_IDENTIFIER` needs the HealthKit capability enabled in the
   Apple Developer portal (Xcode's
   automatic signing will offer to do it on the first device build with the
   enrolled team selected). Until it is, signing fails with "Provisioning
   profile doesn't include the com.apple.developer.healthkit entitlement".
2. **A real device.** HealthKit does not exist in the iOS Simulator: the
   authorization sheet never appears and reads come back empty, which is
   indistinguishable from a refusal. Never read "no sleep card" on the
   Simulator as a bug.
3. **App Store privacy.** HealthKit apps need a privacy policy URL and the
   App Privacy label must declare Health & Fitness data as collected-but-
   not-linked (it never leaves the device — sleep is read for the analysis
   and nothing is stored or uploaded). App Review also rejects HealthKit
   apps whose usage string doesn't say what is read and why; the shipped one
   names sleep specifically.

Note the entitlements file is new, so it currently declares HealthKit and
nothing else — **push notifications (`aps-environment`) are still missing**,
which the `alerts` feature will need before FCM can deliver anything on a
real device. Add that key when wiring push, don't assume it is there.

### RevenueCat — code is wired, the dashboard and store are not

`purchases_flutter` is in, `RevenueCatPremiumRepository` reads the
entitlement, `RevenueCatPurchaseRepository` sells and restores, and the
paywall renders whatever the offering returns. **There is no local premium
repository any more** — the old `DebugPremiumRepository` (a prefs flag with a
`setPremium`) is deleted, because a premium state the client can write is the
one thing this project must not ship. Tests override
`premiumRepositoryProvider` with a fake instead; nothing else may.

Missing config used to fail loud via `assert(AppEnv.hasFirebaseConfig, …)` and
`assert(AppEnv.hasPurchasesConfig, …)` in `main()`; both were removed (owner
call: a TestFlight build crashing on launch was suspected to trace back to
one of them; under investigation) and have now been **replaced with one
assert** — `AppEnv.missingConfigKeys` walks every required Firebase field
plus the platform's own RevenueCat key and returns the names still empty;
`main()` asserts that list is empty, reporting every gap in one message
instead of failing on the first field checked. This is a deliberate re-add of
an `assert()` in `main()` despite the still-open investigation above — if the
TestFlight crash resurfaces, this is the first place to suspect and revert.
The paywall still surfaces `PurchaseError.notConfigured` when a purchase
action runs without a key, because every RevenueCat call site catches the
`RevenueCatClient.apiKey` `StateError` — that guard is unchanged. What the
owner must do by hand:

1. **Keys in `env/dev.json` / `env/prod.json`** (gitignored, placeholders
   already added): `REVENUECAT_IOS_KEY`, `REVENUECAT_ANDROID_KEY`, and
   optionally `REVENUECAT_ENTITLEMENT` (defaults to `premium`) and
   `REVENUECAT_OFFERING` (empty = whatever the dashboard marks current).
2. **Products in App Store Connect** — monthly $5.99, yearly $39.99,
   lifetime $79.99 — plus the Paid Apps Agreement, then the same three
   attached to a RevenueCat offering. Until an offering exists the paywall
   correctly shows "no plans available"; that is not a bug.
3. **Prices are never formatted in Dart.** `PremiumOffer.priceLabel` is the
   store's own string, because the currency, its position and the decimal
   separator belong to the customer's storefront.

Only `PackageType.monthly` / `annual` / `lifetime` are rendered; anything else
the dashboard adds is skipped rather than drawn blind. Purchases are bound to
the Firebase UID via `PurchaseIdentity` so an entitlement follows the person,
not the install.

## Testing priorities

1. `domain/correlation` — unit tests, high coverage
2. Drift migrations — test every schema change with migration tests
3. Pressure alert function — emulator tests: threshold edge cases, geohash grouping, dedupe window
4. Paywall entitlement gating — widget tests that free users never see premium data paths

## When unsure

- Product questions → check `PLAN.md` first
- Prefer boring, well-maintained pub.dev packages (>1k likes, recent commits) over clever solutions
- Ask before adding any new third-party service, SDK, or analytics tool
