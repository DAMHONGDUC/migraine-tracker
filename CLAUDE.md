# CLAUDE.md — BaroEase (Migraine + Barometric Pressure Tracker)

Read `PLAN.md` for full product spec before making architectural decisions.

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
- **Weather**: WeatherKit REST in-app is the target; Open-Meteo is the temporary in-app source until the WeatherKit key is configured (swap inside `weatherRepositoryProvider` — everything depends on the `WeatherRepository` interface). Open-Meteo in backend cron permanently.
- **Charts**: fl_chart. **PDF**: `pdf` + `printing` packages. **Health**: `health` package (HealthKit sleep, read-only)
- **Observability**: Firebase Crashlytics (crashes + non-fatals) and Firebase Analytics (usage). Both are initialized in `main` and stay no-ops until then, so tests and pure-Dart paths never touch the SDKs.
- **Files out**: `share_plus` for the share sheet, `flutter_file_dialog` for "save to device" (the platform's own save picker). `flutter_file_dialog` is below the usual ">1k likes" bar and is a deliberate exception: `file_picker` is the popular choice but every version from 8.3.3 up pins `win32 ^5.9.0`, which `share_plus` >=13.1.0 (`win32 ^6.0.1`) cannot resolve against, and there is no stable `file_picker` 12. Do not "fix" this with a `win32` dependency override — the app ships iOS first and a resolution hack to satisfy a preference is the clever-over-boring trade CLAUDE.md warns against. Revisit only when `file_picker` ships a stable release on `win32 ^6`.
- **iOS builds on Swift Package Manager, not CocoaPods** — except `health`, which is a deliberate exception. Every other plugin the app uses resolves as a Swift Package (`flutter_file_dialog` included — Flutter adapts podspec-only plugins). If an `ios/Podfile` reappears for any OTHER reason, something added CocoaPods scaffolding the project does not need: run `pod deintegrate`, delete the `Podfile`, and drop the `#include?` lines from `ios/Flutter/{Debug,Release}.xcconfig`. `flutter build ios` prints this same advice when the integration is present.
  - `health: ^3.0.6` pins its old, unmaintained `device_info` dependency (last published 2021, no SPM support and none coming). `pod install`/`pod build` therefore stays required for `health` + `device_info` specifically; `ios/Podfile` and its `#include?` lines in `Debug.xcconfig`/`Release.xcconfig`/`Profile.xcconfig` are intentional, not leftover scaffolding — don't delete them per the rule above. **All three configs exist and each points at its own Pods xcconfig**: Flutter's template ships only two and maps Profile onto `Release.xcconfig`, which makes `pod install` warn that it never set the base configuration and leaves Profile builds using the *release* pod settings. The Podfile also declares `platform :ios, '15.0'` to match `IPHONEOS_DEPLOYMENT_TARGET`; without it CocoaPods picks its own default and says so every run. The build prints `"The following plugins do not support Swift Package Manager for ios: device_info, health"`; that warning is expected and non-fatal (every other plugin still resolves via SPM).
  - Do not "fix" the warning by bumping `health`: every version through the latest (13.3.1) caps its `device_info_plus` dependency below `win32 ^6`, which conflicts with `package_info_plus`/`share_plus`'s `win32 ^6.0.1` requirement — the same class of conflict as the `flutter_file_dialog`/`win32` note below. Don't override `win32` to force it through. Revisit only if `health` widens its `device_info_plus` range to `^13.0.0`+, or if `health` migrates off `device_info_plus` entirely.
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

- `melos run setup` — everything a fresh clone needs, in order: submodules,
  `pub get` for both packages, `gen-l10n`, `build_runner`, `env/*.json` from
  the templates, `npm ci` in `functions/`, and `pod install` on macOS.
  Idempotent — re-run it any time, and after `melos run clean`.
  **It puts each submodule on the branch named in `.gitmodules` (`main`) and
  fast-forwards it, rather than leaving it detached at the recorded gitlink.**
  So the design system is always editable in place — and what you build is
  whatever is on that branch, NOT what the parent commit pins. When the branch
  moves ahead, `packages/system_design` shows as modified; commit that gitlink
  deliberately, and never assume an old parent commit rebuilds byte-for-byte.
- `melos run gen` — after editing Drift tables, Riverpod codegen, or ARB files
- `melos run analyze` — `--fatal-infos`, exactly what CI runs. Must pass with
  zero findings before considering any task done.
- `melos run test` — run after changes to `domain/` or `data/`
- `melos run clean` — wipe Android + iOS build artefacts, then `setup`
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

## Code style

- Small widgets, extract at ~80 lines. Prefer composition over config flags.
- No business logic in widgets. View state and orchestration (state machines, save/export/delete flows, filtering) live in a `presentation/controllers/` Notifier or a `Ref`-backed controller; screens are `ConsumerWidget`s that watch state and call controller methods. Dialogs/snackbars stay in the widget.
- **Controllers log their own failures: process first, print the error if one lands.** Every `presentation/controllers/` method that touches a repository, service or platform plugin wraps its work in `try` / `catch (error, stackTrace)`, calls `AppLogger.error('<what failed>', error: error, stackTrace: stackTrace)` (`core/logging/app_logger.dart`), then `rethrow`s — the log is an extra pair of eyes, never a replacement for the caller's error handling. Plain `try`/`catch` inline, always: no closure-taking wrapper (an `AppLogger.guard(action)`-style combinator hides the flow), and never `print(...)`. Cancellation is not a failure — `LoginController` stays silent on `AuthError.cancelled`. Controllers that only hold state (`HistoryController`, `MedicationFiltersController`) have nothing to catch and stay bare.
- Snackbars: always `SdSnackBarUtilsV2.success/error/info` (`system_design`) — never raw `ScaffoldMessenger.showSnackBar`. It draws the app's own card (dark surface, accent icon + hairline edge, never a full-bleed colour fill) and shows one message at a time. Pass a finished localized string; the kind picks the icon and accent, and the icon always differs so colour is never the only signal.
- Dialogs: always `showSdDialogV2` + `SdDialogV2`/`SdDialogOptionV2` (`system_design`) — never raw `showDialog`. Sheets: always `showSdBottomSheetV2` (`system_design`) — it uses the root navigator so sheets cover the bottom nav; raw `showModalBottomSheet` slides under it.
- Animations must be calm (fade/scale/slide, ≤400ms, gentle curves). Hard rule 3: never flashing or strobing. Use `SdPressableScaleV2` (`system_design`) for tactile button feedback.
- Responsive sizing via `flutter_screenutil` (design size 393×852, `minTextAdapt: true`), but NEVER as raw literals in widgets — every dimension goes through `SdSpacingConstant` (`system_design`): `w*` horizontal, `h*` vertical, `r*` square/radius, `sp*` font. Colors likewise only via `AppColors` (`system_design`).
- **One card colour, and bottom sheets wear it: `AppColors.surface`.** Every card — dashboard, insights, `SdChartCardV2`, every `Card` via `cardTheme` — is `#1C1C1E`, and so is every `showSdBottomSheetV2` sheet: sheets are flat and opaque, never Liquid Glass, so a sheet opening over a card is never a second shade of dark. Anything that has to stay visible while sitting *on* a card or a sheet is one step up in `AppColors.surfaceElevated` (dialogs, snack bars, chart tooltips, the log flow's option tiles, filter chips) — a tile left on `surface` disappears the moment its sheet is that colour. Liquid Glass is for chrome — app bar, the shell's nav pill, the log flow's step bar, a sheet header's two `SdAppBarButtonV2`s — plus one deliberate surface: the **paywall** panel stays frosted glass, unlike every other sheet.
- Text: every style comes from `AppTextStyle` (`system_design`) — no inline `TextStyle(...)` and no `context.textTheme`/`Theme.of(context).textTheme` in widgets (the extension getter was removed on purpose). Font sizes go through `SdSpacingConstant.sp*` (screenutil); line heights are shared `_height*` ratio constants in `AppTextStyle`. Because of `.sp`, widget tests MUST pin the view to the 393×852 design size — `pumpApp` already does this; the default 800×600 test surface scales fonts ~2× and breaks layout. Use the `.secondary` / `.w600` helpers on `AppTextStyle` (the package's own are `.muted(context)` / `.semiBold`) for muted color and semi-bold; other tweaks via `copyWith`. `AppTheme` feeds `AppTextStyle` into `ThemeData.textTheme` so ambient defaults match.
- **Icons: every icon is an `SdIconV2`** (`system_design`) — never a raw `Icon(...)` in feature or core code (the only raw `Icon` lives inside `SdIconV2`). `SdIconV2` always resolves to a concrete size: it defaults to `SdSpacingConstant.r24`, and any other size is passed explicitly via `size:` (never let an icon inherit an ambient size). `color` falls back to the ambient `IconTheme` when omitted.
- Buttons: every labeled button is an `SdButtonV2` (`system_design`), and **the look is a prop, never a named constructor** — `SdButtonV2(variant: SdButtonVariantV2.primary, ...)`. Variants: `primary` (main CTA), `secondary` (tonal), `outlined`, `text` (low emphasis / dialog cancel), `destructive` (error-filled confirm), `positive` (teal additive). Never raw `FilledButton`/`OutlinedButton`/`TextButton` in feature code. **Icon-only actions in an app bar — leading back arrow and trailing actions alike — are `SdAppBarButtonV2`** (`system_design`), never a raw `IconButton`: `SdAppBarButtonV2.iconSize` (20) glyph inside an invisible `SdAppBarButtonV2.tapSize` (48) target, and a `SdPopScaleV2` swell on touch (it grows out from under the fingertip; a press-*in* would vanish under it). `SdAppBarV2` inserts one for any route that can pop, and wraps each `SdAppBarButtonV2` action in the glass circle — an action that is not one passes through undecorated. `IconButton` is still fine inside content (list rows, text-field suffixes). With an `icon`, `SdButtonV2` lays the content out itself — `SdButtonV2.iconSize` glyph, `SdButtonV2.iconGap`, then the label — and deliberately avoids Material's `.icon` constructors, whose per-variant padding is what made the filled Apple button and the outlined Google button sit differently. Placement is a second prop: `SdButtonIconPlacementV2.inline` (default) is a centred cluster that shrink-wraps, so a longer label pushes the glyph sideways; `aligned` is the same centred cluster with the label start-aligned in a slot of `SdButtonV2.alignedLabelWidth`, so **stacked buttons put their glyphs on the same x and start their labels on the same x whatever the label lengths** — that is what the login screen's Apple/Google pair uses. The slot is a minimum, not a cage: a label too long for it widens, then wraps, and never ellipses. The glyph is `SdButtonV2.defaultIconSize` unless a call site passes `iconSize` (an `SdSpacingConstant.r*`, never a raw number) to optically correct a brand mark — under `aligned` that resizes the glyph but not the slot it is centred in, so the pair stays lined up.
- **Analytics: every event goes through `AppAnalytics`** (`core/analytics/app_analytics.dart`) — a typed method per event, so the full inventory of what we send is one file. Never call `FirebaseAnalytics` directly and never type an event name at a call site. Events live next to the matching `AppLogger.action` in a `presentation/controllers/` Notifier, never in a widget's build. Health data never becomes a parameter (hard rule 1).
- **Crash reporting goes through `CrashReporter`** (`core/logging/crash_reporter.dart`): `recordError` for a caught failure worth seeing in production, alongside the `AppLogger.error` that serves the debug console. `domain/` stays pure Dart — report from the presentation/data layer that catches it.
- Repositories: interface in `domain/`, impl in `data/`; return domain models, never Drift rows.
- Correlation engine stays pure Dart with unit tests (this is the "insight" users pay for — test edge cases: <15 attacks, all-same-weather, timezone shifts).
- **HealthKit is read-only, iOS-only, and nothing it returns is persisted.** `health` reads `SLEEP_IN_BED` and only that: this plugin version maps IN_BED / ASLEEP / AWAKE onto the same `HKCategoryType.sleepAnalysis` and drops the category value before Dart sees it, so asking for all three returns the same samples three times and none can be told apart — take one type and union the intervals (`SleepNightAggregator`). Sleep is queried on demand for the analysis window and never written to Drift: HealthKit is already on-device storage, and a copy here would be one more pile of health data the wipe has to chase (hard rule 8). iOS never reports a *read* denial (that would leak which conditions a user has), so `requestAuthorization` returning true proves only that the sheet was answered — treat an empty read as "no access or no data" and never as an error. The connect switch lives in Settings and is the only place the prompt is raised; everything else reads `healthControllerProvider`.
- Cloud Functions: idempotent, log with structured JSON, fail loud on weather API errors (retry with backoff), never silently skip a user cohort.
- Commit style: conventional commits (`feat:`, `fix:`, `chore:`). No `Co-Authored-By` trailer.
- **PR descriptions are short bullets, never prose.** A one-line summary, then bulleted groups — one line per bullet, about a screen in total. No explanatory paragraphs, no quoting source in the body. The *why* belongs in the commit message and the code comment, which reviewers reach from the diff; a PR body they have to read twice gets skimmed instead.
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
- **Declarations first, blank line, then logic.** Group all variable/constant declarations at the top of a method with no blank lines between them, then one blank line before the logic block (conditions, loops, calls, `return`). Don't interleave — never declare, run logic, then declare again lower down.
- **No widget or class holds spacing logic — `SdContentPaddingV2` does, and nothing else.** Not `SdScaffoldV2`, not `SdAppBarV2`, not a screen: any inset another widget pads by is a static on that one class. Widgets keep only their own intrinsic size (`SdPinnedFilterBarV2.barHeight`, `SdAppBarV2.preferredSize`).
- **One spacing rule for all content, and one class that computes it: `SdContentPaddingV2`** (`system_design`). Content sits **`topGap` (8) below the app bar**, **`bottomGap` (16) above the safe area**, **`horizontal` (16) either side** — the two vertical gaps are separate fields, so the edge under the chrome and the edge above the thumb can move independently — `SdContentPaddingV2.screen(context)` is that, `fullBleed(context)` drops the gutter for rows that inset themselves (a `ListTile`), and `floatingNav: true` additionally clears the shell's nav pill on the five tab screens — `navBarOffset` + `floatingBarHeight` + `bottomGap`, so scrolling a tab screen to its end leaves exactly `bottomGap` of daylight between the last item and the pill. **`navBarOffset` is the pill's own rule and the one place it lives**: the home indicator's inset where there is one (the pill rests on it — that inset already IS the gap), a flat 16 where there is none, so it never hugs the edge of a Home-button phone. The log flow's step bar does not follow it — that one always rests on the safe area (`bottomBar`). `floatingBarHeight` (and `floatingBarRadius`, half of it) is the ONE height for both floating bars: the nav pill and the log flow's step bar read it, neither types its own, because the day they disagreed the difference was eaten out of the gap above them. **Bottom insets come off the view, not the ambient `MediaQuery`, exactly like `appBarInset` at the top**: `Scaffold` subtracts `padding.bottom` from its body's `viewPadding.bottom` whenever there is a `bottomNavigationBar`, so an ambient read inside the shell loses the home indicator entirely and the last row lands *under* the pill — a bug that costs 0 pixels in a test whose view has no insets. Never read `MediaQuery.paddingOf(...)` for content spacing at a call site and never re-add an inset the class already applied.
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

Missing config fails loud rather than silently making everyone free:
`main()` asserts on `AppEnv.hasPurchasesConfig`, and the paywall surfaces
`PurchaseError.notConfigured`. What the owner must do by hand:

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
