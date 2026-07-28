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
```

Features: `app_update` (force-update gate), `attacks` (Attack entity + 3-tap log), `medications`, `weather`
(WeatherSnapshot + API clients), `history`, `insights` (correlation engine),
`alerts`, `auth` (Google/Apple + linkWithCredential, account screen, `users/{uid}` profile doc), `sync`, `paywall`,
`settings`. Create a layer folder only when it gets its first file — no empty
placeholder folders.

Dependency rule: `presentation → domain ← data` inside a feature. Across
features, import only another feature's `domain/` (or its `providers.dart`),
never its `data/` or `presentation/`. Drift tables live with their feature;
`core/db` only composes them.

## Commands

- `flutter run --dart-define-from-file=env/dev.json` — Firebase config comes from `env/dev.json` / `env/prod.json` (gitignored). Read config only through the `AppEnv` class (`lib/core/env/app_env.dart`) — it is the ONLY place `String.fromEnvironment` may appear; `firebase_options.dart` and everything else read `AppEnv.*`. VS Code launch configs already pass this flag (dev → `env/dev.json`, prod → `env/prod.json`).
- `flutter analyze` — must pass with zero warnings before considering any task done
- `flutter test` — run after changes to `domain/` or `data/`
- `dart run build_runner build --delete-conflicting-outputs` — after editing Drift tables or Riverpod codegen
- `cd functions && npm run build && npm test` — after touching Cloud Functions
- `firebase emulators:start` — test functions locally; never test cron against production

## Hard rules

1. **Local-first, account optional.** Every feature except sync/alerts must work without an account. For users who are not signed in, Firestore stores ONLY: geohash (5 chars, ~5km), FCM token, alert threshold, timezone, premium flag. Signing in adds account fields to the same `users/{uid}` doc — display name, email, photo URL, created/updated timestamps — and nothing else. Attack data is uploaded ONLY for signed-in users, as encrypted payloads under `users/{uid}/attacks`, and sync must be clearly disclosed in the sign-in UI. Any other path that uploads health data: stop and flag it. This includes analytics: `AppAnalytics` events carry usage only — never intensity, head location, medication names, attack timestamps or coordinates.
2. **Location**: request While-Using + reduced accuracy only. Never request Always.
3. **Dark mode is the default theme.** Users are photophobic. No pure white backgrounds anywhere; max brightness surface is `#1C1C1E`-family. No flashing animations.
4. **Attack logging must work fully offline.** Weather snapshot is fetched best-effort and backfilled later if offline.
5. **The 3-tap log flow is sacred**: intensity → head location → medication → saved. Any new required field in this flow needs explicit approval. Optional fields go behind "Add details".
6. Every user-facing string goes through `intl` ARB files. Two locales ship in v1: `app_en.arb` (template, with `@` descriptions) and `app_vi.arb` — every new key must be added to BOTH. Access strings via the `context.l10n` extension (`core/extensions/context_extensions.dart`), never `AppLocalizations.of(context)` directly. The user's language choice lives in `localeControllerProvider` (persisted via shared_preferences; null = follow system).
7. Pressure math: alerts trigger on **delta** (default ≥5 hPa drop within 24h forecast), not absolute values. Threshold is user-tunable and stored per-user.
8. GDPR: `settings/` must always keep working "Export all data (JSON/CSV)" and "Delete everything" (local wipe + Firestore doc + synced attacks delete + FCM token revoke + Firebase Auth account deletion). In-app account deletion is an App Store requirement (5.1.1(v)) now that accounts exist.
9. **Force update fails open.** The launch check (`app_update`) reads the public, read-only `app_updates` collection and blocks ONLY on an explicit `enable_force_update` against a strictly newer `build_number`. Offline, a missing record, an unreadable field or a malformed link must let the user in — someone mid-attack has to reach the log button. Compare `build_name` first (via `VersionUtils`, segment by segment as numbers — never as strings, `"1.10.0" < "1.9.0"` is true for a string), then `build_number` as the tiebreaker for two builds of the same version.
10. Cloud Functions: group users by geohash before calling weather APIs — one forecast call per cell, never per user. Dedupe alerts: max 1 push per user per 24h per pressure event.
11. Medical disclaimer must appear in onboarding and App Store description. Never generate copy that promises diagnosis, treatment, or prevention.

## Code style

- Small widgets, extract at ~80 lines. Prefer composition over config flags.
- No business logic in widgets. View state and orchestration (state machines, save/export/delete flows, filtering) live in a `presentation/controllers/` Notifier or a `Ref`-backed controller; screens are `ConsumerWidget`s that watch state and call controller methods. Dialogs/snackbars stay in the widget.
- Snackbars: always `AppSnackBarUtils.success/error/info` (`core/widgets/app_snack_bar.dart`) — never raw `ScaffoldMessenger.showSnackBar`. It draws the app's own card (dark surface, accent icon + hairline edge, never a full-bleed colour fill) and shows one message at a time. Pass a finished localized string; the kind picks the icon and accent, and the icon always differs so colour is never the only signal.
- Dialogs: always `showAppDialog` + `AppDialog`/`AppDialogOption` (`core/widgets/app_dialog.dart`) — never raw `showDialog`. Sheets: always `showAppBottomSheet` (`core/widgets/app_bottom_sheet.dart`) — it uses the root navigator so sheets cover the bottom nav; raw `showModalBottomSheet` slides under it.
- Animations must be calm (fade/scale/slide, ≤400ms, gentle curves). Hard rule 3: never flashing or strobing. Use `core/widgets/PressableScale` for tactile button feedback.
- Responsive sizing via `flutter_screenutil` (design size 393×852, `minTextAdapt: true`), but NEVER as raw literals in widgets — every dimension goes through `AppSpacingConstant` (`core/constants/app_spacing_constant.dart`): `w*` horizontal, `h*` vertical, `r*` square/radius, `sp*` font. Colors likewise only via `AppColors` (`core/theme/app_colors.dart`).
- Text: every style comes from `AppTextStyle` (`core/theme/app_text_style.dart`) — no inline `TextStyle(...)` and no `context.textTheme`/`Theme.of(context).textTheme` in widgets (the extension getter was removed on purpose). Font sizes go through `AppSpacingConstant.sp*` (screenutil); line heights are shared `_height*` ratio constants in `AppTextStyle`. Because of `.sp`, widget tests MUST pin the view to the 393×852 design size — `pumpApp` already does this; the default 800×600 test surface scales fonts ~2× and breaks layout. Use the `.secondary` / `.w600` helpers for muted color and semi-bold; other tweaks via `copyWith`. `AppTheme` feeds `AppTextStyle` into `ThemeData.textTheme` so ambient defaults match.
- **Icons: every icon is an `AppIcon`** (`core/widgets/app_icon.dart`) — never a raw `Icon(...)` in feature or core code (the only raw `Icon` lives inside `AppIcon`). `AppIcon` always resolves to a concrete size: it defaults to `AppSpacingConstant.r24`, and any other size is passed explicitly via `size:` (never let an icon inherit an ambient size). `color` falls back to the ambient `IconTheme` when omitted.
- Buttons: every labeled button is an `AppButton` (`core/widgets/app_button.dart`) — `.primary` (main CTA), `.secondary` (tonal), `.outlined`, `.text` (low emphasis / dialog cancel), `.destructive` (error-filled confirm). Never raw `FilledButton`/`OutlinedButton`/`TextButton` in feature code. Icon-only actions may still use `IconButton`.
- **Analytics: every event goes through `AppAnalytics`** (`core/analytics/app_analytics.dart`) — a typed method per event, so the full inventory of what we send is one file. Never call `FirebaseAnalytics` directly and never type an event name at a call site. Events live next to the matching `AppLogger.action` in a `presentation/controllers/` Notifier, never in a widget's build. Health data never becomes a parameter (hard rule 1).
- **Crash reporting goes through `CrashReporter`** (`core/logging/crash_reporter.dart`): `recordError` for a caught failure worth seeing in production, alongside the `AppLogger.error` that serves the debug console. `domain/` stays pure Dart — report from the presentation/data layer that catches it.
- Repositories: interface in `domain/`, impl in `data/`; return domain models, never Drift rows.
- Correlation engine stays pure Dart with unit tests (this is the "insight" users pay for — test edge cases: <15 attacks, all-same-weather, timezone shifts).
- Cloud Functions: idempotent, log with structured JSON, fail loud on weather API errors (retry with backoff), never silently skip a user cohort.
- Commit style: conventional commits (`feat:`, `fix:`, `chore:`).
- **No standalone top-level functions.** Every function lives inside a class — a widget method, or a static/instance method on a utility class (`DateUtils`, `StringUtils`, `ValidatorUtils`). Never a floating `void doSomething() {}` at file scope. The one sanctioned exception is a widget's `.show()` extension (see "Bottom sheets" below); the shared `core/widgets` primitives `showAppDialog`/`showAppBottomSheet`/`showAppFilterSheet` stay as-is (they are the low-level presenters those extensions call).
- **Bottom sheets and dialogs: widget + `.show()` extension, never a top-level `showX()`.** A sheet/dialog is a widget class (`FooSheet extends StatelessWidget`, public so callers can construct it), and its opener is an extension on that widget exposing `Future<T?> show(BuildContext context) => showAppBottomSheet<T>(context, builder: (_) => this);` (sheets) or `showAppDialog<T>(...)` (dialogs). Name the extension `<Widget>Ext`. Call it as `FooSheet(...).show(context)` — never `showFooSheet(context, ...)`. This keeps presentation off file-scope functions (rule 1) while still routing through `showAppBottomSheet`/`showAppDialog` (root navigator, calm animation). A sheet/dialog opener with no dedicated widget (a thin wrapper over the generic `showAppFilterSheet`) is dead weight — inline the generic presenter at the call site instead.
- **No `_buildX()` methods for UI.** Do not split `build()` into helper methods like `Widget _buildHeader()` / `Widget _buildList()` inside a `State`. Extract UI into a separate widget class (`StatelessWidget`/`StatefulWidget`) so Flutter can scope rebuilds (const, keys) instead of rebuilding the whole parent — a method split is a fake split.
- **Split big presentation files with `part of`.** When a screen/page under `presentation/` accumulates many private child widgets, move them into sibling files joined via `part of` (not one giant file; `main.dart` is exempt). Name child files `<main_file>_<widget>.dart` — e.g. `home_page.dart` + `home_page_header.dart` with `part of 'home_page.dart';`.
- **One folder per screen under `presentation/screens/`.** Each screen gets its own subfolder named after the screen file: `presentation/screens/<name>_screen/` holds `<name>_screen.dart` and all of its `part` files. Screens never sit loose directly in `screens/`.
- **Never use `var`.** Always declare explicit types (`final String name = ...`, `int count = 0`, `List<Item> items = []`). Prefer `final`/`const` with an explicit type. Explicit types keep reviews clear and prevent silent type-inference bugs.
- **Anything shared gets extracted — a widget, or a `*Utils` class.** The second copy is the trigger, not a later cleanup: duplicated UI becomes a widget in `core/widgets/` (or the feature's `presentation/widgets/` if only that feature uses it), duplicated logic becomes a static method on a `*Utils` class (`NavigationUtils`, `AppSnackBarUtils`). Same in `test/` — shared setup and navigation helpers live in `test/helpers/`, never re-declared per file.
- **Comments: short and plain.** One or two lines. Say *why*, not what the code already says — and say it in the fewest words that still land. No paragraphs, no essays, no restating the diff.
- **Declarations first, blank line, then logic.** Group all variable/constant declarations at the top of a method with no blank lines between them, then one blank line before the logic block (conditions, loops, calls, `return`). Don't interleave — never declare, run logic, then declare again lower down.
- **No widget or class holds spacing logic — `AppContentPadding` does, and nothing else.** Not `AppScaffold`, not `MainAppBar`, not a screen: any inset another widget pads by is a static on that one class. Widgets keep only their own intrinsic size (`PinnedFilterBar.barHeight`, `MainAppBar.preferredSize`).
- **One spacing rule for all content, and one class that computes it: `AppContentPadding`** (`core/constants/app_content_padding.dart`). Content sits **`topGap` (8) below the app bar**, **`bottomGap` (16) above the safe area**, **`horizontal` (24) either side** — the two vertical gaps are separate fields, so the edge under the chrome and the edge above the thumb can move independently — `AppContentPadding.screen(context)` is that, `fullBleed(context)` drops the gutter for rows that inset themselves (a `ListTile`), and `floatingNav: true` additionally clears the shell's nav pill on the five tab screens. Never read `MediaQuery.paddingOf(...)` for content spacing at a call site and never re-add an inset the class already applied.
- **`AppScaffold` adds no padding at all** — no SafeArea, no insets. Every screen pads its own scrollable via `AppContentPadding`, applied **inside** the scrollable so content still scrolls *behind* the frosted bar. A scaffold-level SafeArea plus a body that also clears a floating bar is how insets used to get applied twice.
- **Insets come off the window, not the ambient `MediaQuery`.** `Scaffold` strips its body's top padding when there is an app bar (and its bottom under `extendBody`), so the same read returns different numbers above vs inside the body. `AppContentPadding` reads the view; feature code reads `AppContentPadding`. The default test view has no notch, so a bug here costs 0 pixels in every widget test — see `test/core/constants/app_content_padding_test.dart`, which gives the view one.
- **Every `Text` carries an explicit `style:`.** Never lean on the ambient `ThemeData.textTheme`, even where it would look identical — the default is invisible at the call site and silently drifts when a theme changes. Use the style the surface already implies: app-bar titles `AppTextStyle.titleLarge`, `ListTile.title` `bodyLarge`, `ListTile.subtitle` `bodyMedium.secondary`, `SnackBar.content` `bodyMedium`.
- **Screens with content plus a bottom action: `AppActionView`** (`core/widgets/app_action_view.dart`), passed straight as `AppScaffold.body` — never hand-rolled. It is content on top, `actions` hugging the bottom edge, `spaceBetween` between them, and it owns the two things every such screen otherwise forgets: the vertical insets (straight from `AppContentPadding`) and the minimum height that gives `spaceBetween` its free space. Nothing inside `content` adds a top gap of its own — the view already applied the screen's. `actions` is a stretched `Column`, so buttons come out full width and equal to each other. It scrolls itself — long locales and large accessibility text sizes overflow a fixed `Column`, and a bare `ListView` is wrong here because under short content the buttons drift up into the middle. Used by `login_screen`, `account_screen`, `premium_screen`.
- **The bottom action sits 16 above the safe area, never twice.** On a screen that is `AppContentPadding`'s business, the class has already applied it — don't add the inset again, and don't leave the button flush against the home indicator. Sheet routes still take `MediaQuery.paddingOf(context).bottom + h16` themselves (they are not screens). Floating chrome (the shell's nav pill, the log flow's step bar) is exempt: those sit at exactly the safe area so they line up with each other.
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

## Testing priorities

1. `domain/correlation` — unit tests, high coverage
2. Drift migrations — test every schema change with migration tests
3. Pressure alert function — emulator tests: threshold edge cases, geohash grouping, dedupe window
4. Paywall entitlement gating — widget tests that free users never see premium data paths

## When unsure

- Product questions → check `PLAN.md` first
- Prefer boring, well-maintained pub.dev packages (>1k likes, recent commits) over clever solutions
- Ask before adding any new third-party service, SDK, or analytics tool
