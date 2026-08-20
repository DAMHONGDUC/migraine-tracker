# Code style

How Dart in this repo is written. UI primitives are in `DESIGN_SYSTEM.md`;
anything feature-specific is in that feature's own `CLAUDE.md`.

## Widgets and structure

- Small widgets, extract at ~80 lines. Composition over config flags.
- **No business logic in widgets.** View state and orchestration — state
  machines, save/export/delete flows, filtering — live in a
  `presentation/controllers/` Notifier or a `Ref`-backed controller. Screens are
  `ConsumerWidget`s that watch state and call controller methods; dialogs and
  snackbars stay in the widget.
- **No `_buildX()` methods for UI.** Extract into a real widget class so Flutter
  can scope rebuilds (const, keys); a method split is a fake split.
- **No standalone top-level functions.** Every function lives in a class — a
  widget method, or a static on a `*Utils` class (`DateTimeUtils`,
  `StringUtils`, `ValidatorUtils`). The one sanctioned exception is
  a widget's `.show()` extension; the shared presenters
  `showSdDialogV2`/`showSdBottomSheetV2`/`showSdFilterSheetV2` stay as they are.
- **Split big presentation files with `part of`.** Private child widgets move to
  sibling files named `<main_file>_<widget>.dart` (`home_page.dart` +
  `home_page_header.dart` with `part of 'home_page.dart';`). `main.dart` is
  exempt.
- **One folder per screen under `presentation/screens/`**:
  `<name>_screen/` holds `<name>_screen.dart` and its parts. Screens never sit
  loose in `screens/`.
- **Never use `var`.** Explicit types everywhere, `final`/`const` preferred —
  reviews stay clear and type inference cannot surprise anyone.
- **No `abstract final class` — plain `final class`.** Static-only holders
  (`SdLogger`, `AppColors`, `AppTextStyle`, `AppTheme`, `SdSpacingConstant`,
  `AppEnv`, `AppRoutes`, `SdSnackBarUtilsV2`, `NavigationUtils`, …) are `final
  class`. `abstract interface class` is for contracts that are implemented:
  every `domain/repositories/` and `domain/services/` interface.
- **Declarations first, blank line, then logic.** Group declarations at the top
  of a method with no blank lines between them, one blank line, then conditions,
  loops, calls and `return`. Never declare, run logic, then declare again.
- Repositories: interface in `domain/`, impl in `data/`; return domain models,
  never Drift rows.
- The correlation engine stays pure Dart with unit tests — it is the insight
  users pay for. Cover the edges: <15 attacks, all-same-weather, timezone shifts.

## Logging

**Every action logs, and it logs the DATA with it.** Owner's rule, and the
widest of them; the rest sharpen it. Every API call, every tap, every submit: a
line in with what was sent, a line out with what came back.

- **A log without its data answers nothing.** "Sync failed" says a sync failed;
  "Sync failed — {collection: attacks, pushed: 12}" says which and how far. So
  `SdLogger.action` / `.info` always carry the payload, the id, the count.
- **An error logs the full error and the response**, not a message about it:
  `SdLogger.error(tag, message, error: …, stackTrace: …, data: …)`, where `data`
  is what the call was doing and `error` is the thrown object, unmodified. A
  `FirebaseFunctionsException`'s `code`/`details` and an `HttpsCallableResult`'s
  body are exactly what a hand-written string throws away.
- **Success is logged too.** An empty console must mean nothing ran, never
  "everything worked".
- **Every `catch` logs, wherever it sits** — data sources, repositories,
  `domain/services/`, launchers, the cipher, deep-link listeners. A block that
  turns a failure into `null`, `false` or a domain enum holds the only copy of
  what went wrong, so it calls `SdLogger.error` before returning the substitute.
  - Catch `catch (error, stackTrace)`, never `on Exception`: `Error` subtypes
    (`StateError`, `TypeError`, a failed cast) are not `Exception`s, so
    `on Exception` lets the unexpected ones through untouched *and* unlogged.
  - **A `catch` that maps or rethrows logs too**, with the **original** error and
    a `data` map carrying the fields it is about to drop — `code`, `message`,
    `details`, the provider id. Mapping a `FirebaseAuthException` to an
    `AuthException` destroys the only object that named the cause, and every log
    above it can then honestly say no more than "unknown". A `rethrow` is the
    same case: the caller logs a different frame at a different time, without
    this frame's arguments.
  - **Two lines for one failure is the intended cost.** The inner says what the
    platform returned, the outer what the app decided; only both together turn
    "sign-in failed" into a cause. Deduplicate by making the inner line specific,
    never by deleting it.
  - Two narrow exemptions: a widget re-catching what its controller already
    logged (say so in the comment, as `HomeWidgetSettingsTile` does), and a
    cancellation, which is not a failure — `LoginController` stays silent on
    `AuthError.cancelled`.
  - **Controllers log inline, then `rethrow`** — the log is an extra pair of
    eyes, never a replacement for the caller's error handling. No closure-taking
    wrapper (an `SdLogger.guard(action)` combinator hides the flow), never
    `print(...)`. Controllers that only hold state (`HistoryController`,
    `MedicationFiltersController`) have nothing to catch and stay bare.
- **`SdLogger` (`package:system_design/common.dart`) is the only logger.**
  `AppLogger` is gone: two loggers meant two consoles to grep and two places
  every rule had to be restated. Every call names its flow from
  `LogTagConstant` (`core/constants/`), never a string typed at the call site —
  `'Sign In'` and `'Sign-in'` read as one flow and filter as two. `SdLogger` is
  pure Dart, so `domain/` may call it.
- **Crash reporting is the same call.** `SdLogger.error` forwards to
  `SdCrashReporter.instance`, which `AppBootstrap` points at
  `FirebaseCrashReporter` (`core/logging/crash_reporter.dart`) once Crashlytics
  is up — so **a `CrashReporter.recordError` beside an `SdLogger.error` files the
  same failure twice**. What stays on the static `CrashReporter` is Crashlytics'
  alone: `init`, `log`, `setCustomKey`, `setCollectionEnabled`. The design system
  holds the contract and a no-op, never a vendor, so before `attach` runs —
  a unit test, `domain/`, anything before `main` — reporting is inert.
- **`.warning` prints and does not report; `.error` does both.** That is the whole
  of how a caught failure is graded. An expected, recoverable one (offline, a
  declined permission, a check that fails open) is a `warning`; putting it through
  `error` buries the real ones under it.
- **Written after three features failed silently at once**: WeatherKit answered
  every call `401` and the app said "no weather", `sendTestPush` was refused by
  the backend, and neither left a line anywhere. The mapping half was written
  after Apple sign-in, where `_recoverFromLinkFailure` collapsed three Firebase
  codes onto one `AuthError.notConfigured` and a console full of it could not say
  which. **A caught error is invisible by construction.**

## UI primitives

- **Snackbars: `SdSnackBarUtilsV2.success/error/info`** (`system_design`), never
  raw `ScaffoldMessenger.showSnackBar`. It draws the app's card (dark surface,
  accent icon and hairline edge, never a full-bleed fill), one message at a time.
  Pass a finished localized string; the kind picks the icon, and the icon always
  differs so colour is never the only signal.
  - **It draws into the root `Overlay`, not a `ScaffoldMessenger`.** A messenger
    renders into the nearest `Scaffold`, so a route without one (the paywall
    sheet) sent its messages to the screen underneath, where the sheet covered
    them. Widget tests missed it: `find.text` matches a widget the user cannot
    see — assert on `SdSnackBarCardV2`, the only public handle on what a static
    presenter drew.
  - Placement is a second prop: `SdSnackBarPlacementV2.bottom` is the default and
    what every screen wants; `top` is for a route that owns the bottom of the
    screen, today the paywall alone.
- **Dialogs: `showSdDialogV2` + `SdDialogV2`/`SdDialogOptionV2`**, never raw
  `showDialog`. **Sheets: `showSdBottomSheetV2`** — it uses the root navigator so
  sheets cover the bottom nav; raw `showModalBottomSheet` slides under it.
- Animations stay calm: fade/scale/slide, ≤400ms, gentle curves, and never
  flashing or strobing (hard rule 3). `SdPressableScaleV2` for button feedback.
- **Sizing via `flutter_screenutil`** (design size 393×852, `minTextAdapt: true`)
  but never as raw literals: every dimension goes through `SdSpacingConstant`
  (`w*` horizontal, `h*` vertical, `r*` square/radius, `sp*` font), every colour
  through `AppColors`.

## Analytics and startup

- **Every event goes through `AppAnalytics`** (`core/analytics/app_analytics.dart`)
  — a typed method per event, so the full inventory of what we send is one file.
  Never call `FirebaseAnalytics` directly, never type an event name at a call
  site. Events sit next to the matching `SdLogger.action` in a controller, never
  in a widget's build. Health data never becomes a parameter (hard rule 1).
- **`main.dart` holds `main()` and nothing else.** Startup work lives in
  `AppBootstrap` (`core/bootstrap/app_bootstrap.dart`), so the entry point reads
  as a list of what happens rather than how.
- **`AppBootstrap.init` guards each step separately, never the whole function.**
  One `try` around all of them lets the first failure skip everything after it,
  including the crash reporting that would have named it. **Firebase goes first**
  so Crashlytics is up before anything else can fail — it used to run last, which
  left a timezone failure reported nowhere. Anything added here runs *before*
  `runApp`, where an unhandled throw stops the app from starting at all, so it
  needs its own `try`/`catch` and a fallback that leaves the app usable.

## Extraction and constants

- **Specialised logic gets its own `*Utils` or helper class on its FIRST use.**
  A widget's job is layout and a controller's is orchestration, so a calculation
  in either is misplaced whether or not anything else needs it yet: date and
  duration math, string parsing and formatting, axis arithmetic, filename
  building. `core/utils/` when more than one feature could want it, the feature's
  `domain/services/` when it is really domain logic. What stays in a widget is
  reading providers, wiring callbacks and choosing what to build; in a
  controller, the call sequence and its error handling.
- **Anything shared gets extracted — the second copy is the trigger.**
  Duplicated UI becomes a widget, duplicated logic a static on a `*Utils` class.
  Same in `test/`: shared setup and navigation helpers live in `test/helpers/`.
- **A widget used by more than one feature lives in `core/widgets/`, and that is
  the only `widgets/` folder in `core/`.** `presentation/widgets/` is for
  widgets that one feature alone builds; the moment a second needs it, it moves.
  Otherwise the importer reaches into
  another feature's `presentation/` and breaks the dependency rule — how
  `PremiumGate` and `MedicationNameDialog` ended up cross-imported before they
  moved. A shared widget may import a feature's `domain/` or `providers.dart`
  (core → feature is fine; feature → feature `presentation/` is not). A sheet a
  subsystem shows (`permission_settings_sheet.dart`) goes in `core/widgets/` and
  imports back into its subsystem, never the reverse.
- **Constants live in their own class, never on a model, entity, controller or
  widget.** Owner's rule: a number a class does not itself use is not that
  class's business. `PremiumLimitConstant` (`core/constants/`) holds the free
  limits because the gate providers and the limit dialogs both read them. Reach
  for `core/constants/` when it is cross-cutting, a feature-local `*Constant`
  class otherwise — never a `static const` bolted onto whatever was nearby.
  - **The exception is a widget's own intrinsic size** —
    `SdPinnedFilterBarV2.barHeight`, `SdAppBarV2.preferredSize`,
    `SdBadgeV2.maxCount`, `DashboardExploreSection.cellAspectRatio`: that is what
    the widget *is*, not configuration about it. Spacing stays on
    `SdContentPaddingV2`, itself the constants class for that job.
  - `core/constants/` now holds `PremiumLimitConstant`, `PrefsKeyConstant` (every
    shared_preferences key, so a collision is visible rather than silent),
    `SyncConstant`, `ExportConstant` and `LogFlowConstant`. No entity, controller
    or widget in `lib/` carries a configuration constant any more.
  - **Two things were deliberately left.** A canonical empty instance
    (`SleepSummary.empty`, `StepSummary.empty`) is a value of the type, like
    `Duration.zero`. And constants inside `domain/services/` and `data/`
    (`ReminderOccurrenceMaterialiser.defaultWindow`,
    `AesGcmAttackCipher.isolateThreshold`, the payload codecs' `schemaVersion`,
    `DevSeedService.attackCount`) stay put: those classes *are* the algorithm the
    number belongs to. Raise it with the owner before widening that.
  - `SignedNumberUtils` is the one place a reading gets an explicit `+`, and it
    uses `toStringAsFixed` rather than `NumberFormat` on purpose: a locale-grouped
    number prints pressure as "1,008 hPa", which nothing else in the app does.
  - **All date and time arithmetic goes in `DateTimeUtils`**, never a second
    date-shaped utils class — clock formatting, month arithmetic and a chart's
    time axis are one subject, and two classes is how two call sites compute
    midnight differently. `ChartAxisUtils` keeps only the numeric half of an axis.
  - **`packages/system_design` is out of scope** — a separate repo with its own
    `WIDGET_RULES.md`, and its statics are widget-intrinsic.

## Comments

- **Short and plain.** One or two lines. Say *why*, not what the code already
  says, in the fewest words that still land.
- **Multi-point comments are bullet lists**, one `//` line per point, each
  starting with `-`. No run-on `// does X, and also Y, but watch out for Z`. A
  single-point comment stays one plain line, no dash.
- **Never more than 3 lines.** A 4th means the comment is doing too much: cut to
  the one reason that matters, or move the design rationale into the `///` doc
  comment of the function or class.

## Navigation

**Shared navigation lives in `NavigationUtils`** (`core/router/navigation_utils.dart`).
A plain "push this route" belongs at its call site; a move with a *rule*
attached — an order of screens, or a condition deciding where the user lands —
goes in `NavigationUtils` so the second caller cannot reimplement it without the
rule. `NavigationUtils.toLog` is that rule for the log flow: the free-plan attack
gate, then the flow reset, then the push. The dashboard button and the home
screen widget both go through it.
