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
        screens/         # thin ConsumerWidgets: render state, call controllers
        widgets/
      providers.dart     # Riverpod wiring for the feature
functions/               # firebase cloud functions (typescript)
test/features/           # mirrors lib/features
```

Features: `attacks` (Attack entity + 3-tap log), `medications`, `weather`
(WeatherSnapshot + API clients), `history`, `insights` (correlation engine),
`alerts`, `auth` (Google/Apple, linkWithCredential), `sync`, `paywall`,
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

1. **Local-first, account optional.** Every feature except sync/alerts must work without an account. For users who are not signed in, Firestore stores ONLY: geohash (5 chars, ~5km), FCM token, alert threshold, timezone, premium flag. Attack data is uploaded ONLY for signed-in users, as encrypted payloads under `users/{uid}/attacks`, and sync must be clearly disclosed in the sign-in UI. Any other path that uploads health data: stop and flag it.
2. **Location**: request While-Using + reduced accuracy only. Never request Always.
3. **Dark mode is the default theme.** Users are photophobic. No pure white backgrounds anywhere; max brightness surface is `#1C1C1E`-family. No flashing animations.
4. **Attack logging must work fully offline.** Weather snapshot is fetched best-effort and backfilled later if offline.
5. **The 3-tap log flow is sacred**: intensity → head location → medication → saved. Any new required field in this flow needs explicit approval. Optional fields go behind "Add details".
6. Every user-facing string goes through `intl` ARB files. Two locales ship in v1: `app_en.arb` (template, with `@` descriptions) and `app_vi.arb` — every new key must be added to BOTH. Access strings via the `context.l10n` extension (`core/extensions/context_extensions.dart`), never `AppLocalizations.of(context)` directly. The user's language choice lives in `localeControllerProvider` (persisted via shared_preferences; null = follow system).
7. Pressure math: alerts trigger on **delta** (default ≥5 hPa drop within 24h forecast), not absolute values. Threshold is user-tunable and stored per-user.
8. GDPR: `settings/` must always keep working "Export all data (JSON/CSV)" and "Delete everything" (local wipe + Firestore doc + synced attacks delete + FCM token revoke + Firebase Auth account deletion). In-app account deletion is an App Store requirement (5.1.1(v)) now that accounts exist.
9. Cloud Functions: group users by geohash before calling weather APIs — one forecast call per cell, never per user. Dedupe alerts: max 1 push per user per 24h per pressure event.
10. Medical disclaimer must appear in onboarding and App Store description. Never generate copy that promises diagnosis, treatment, or prevention.

## Code style

- Small widgets, extract at ~80 lines. Prefer composition over config flags.
- No business logic in widgets. View state and orchestration (state machines, save/export/delete flows, filtering) live in a `presentation/controllers/` Notifier or a `Ref`-backed controller; screens are `ConsumerWidget`s that watch state and call controller methods. Dialogs/snackbars stay in the widget.
- Animations must be calm (fade/scale/slide, ≤400ms, gentle curves). Hard rule 3: never flashing or strobing. Use `core/widgets/PressableScale` for tactile button feedback.
- Responsive sizing via `flutter_screenutil` (design size 393×852, `minTextAdapt: true`): use `.w`/`.h` for paddings & spacing, `.r` for square/circular elements, plain `TextTheme` styles for text (screenutil already adapts them via ScreenUtilInit).
- Repositories: interface in `domain/`, impl in `data/`; return domain models, never Drift rows.
- Correlation engine stays pure Dart with unit tests (this is the "insight" users pay for — test edge cases: <15 attacks, all-same-weather, timezone shifts).
- Cloud Functions: idempotent, log with structured JSON, fail loud on weather API errors (retry with backoff), never silently skip a user cohort.
- Commit style: conventional commits (`feat:`, `fix:`, `chore:`).

## Testing priorities

1. `domain/correlation` — unit tests, high coverage
2. Drift migrations — test every schema change with migration tests
3. Pressure alert function — emulator tests: threshold edge cases, geohash grouping, dedupe window
4. Paywall entitlement gating — widget tests that free users never see premium data paths

## When unsure

- Product questions → check `PLAN.md` first
- Prefer boring, well-maintained pub.dev packages (>1k likes, recent commits) over clever solutions
- Ask before adding any new third-party service, SDK, or analytics tool
