# CLAUDE.md — BaroEase (Migraine + Barometric Pressure Tracker)

Read `PLAN.md` for full product spec before making architectural decisions.

## What this project is

Flutter iOS-first app for migraine sufferers sensitive to barometric pressure.
Local-first data, Firebase backend only for pressure alerts + premium sync.
Monetization: RevenueCat subscriptions ($5.99/mo, $39.99/yr, $79.99 lifetime). No ads.

## Tech stack

- **Flutter** (stable channel), Dart 3, iOS first (keep Android compiling, don't polish it yet)
- **State**: Riverpod (hooks_riverpod). No BLoC, no GetX.
- **Local DB**: Drift (SQLite). All health data lives on-device. This is a hard rule.
- **Navigation**: go_router
- **Backend**: Firebase — Firestore (region europe-west1), Cloud Functions (TypeScript, Node 20), Cloud Scheduler, FCM, Remote Config, anonymous Auth
- **Payments**: RevenueCat (`purchases_flutter`) — never call StoreKit directly, never trust client-side premium flags; premium state comes from RevenueCat entitlements
- **Weather**: WeatherKit REST in-app; Open-Meteo in backend cron
- **Charts**: fl_chart. **PDF**: `pdf` + `printing` packages. **Health**: `health` package (HealthKit sleep, read-only)

## Repo layout

```
lib/
  core/          # theme, router, constants, extensions
  data/          # drift db, repositories, weather api clients
  domain/        # models, correlation engine (pure dart, no flutter imports)
  features/
    logging/     # 3-tap attack log
    history/     # calendar + charts
    insights/    # correlation, pressure forecast
    alerts/      # alert settings, geohash registration
    paywall/     # revenuecat
    settings/    # export, delete, privacy
functions/       # firebase cloud functions (typescript)
test/
```

## Commands

- `flutter analyze` — must pass with zero warnings before considering any task done
- `flutter test` — run after changes to `domain/` or `data/`
- `dart run build_runner build --delete-conflicting-outputs` — after editing Drift tables or Riverpod codegen
- `cd functions && npm run build && npm test` — after touching Cloud Functions
- `firebase emulators:start` — test functions locally; never test cron against production

## Hard rules

1. **Health data never leaves the device** in v1. Firestore stores ONLY: geohash (5 chars, ~5km), FCM token, alert threshold, timezone, premium flag. If a task seems to require uploading attack logs, stop and flag it.
2. **Location**: request While-Using + reduced accuracy only. Never request Always.
3. **Dark mode is the default theme.** Users are photophobic. No pure white backgrounds anywhere; max brightness surface is `#1C1C1E`-family. No flashing animations.
4. **Attack logging must work fully offline.** Weather snapshot is fetched best-effort and backfilled later if offline.
5. **The 3-tap log flow is sacred**: intensity → head location → medication → saved. Any new required field in this flow needs explicit approval. Optional fields go behind "Add details".
6. Every user-facing string goes through `intl` ARB files (English only for now, but no hardcoded strings).
7. Pressure math: alerts trigger on **delta** (default ≥5 hPa drop within 24h forecast), not absolute values. Threshold is user-tunable and stored per-user.
8. GDPR: `settings/` must always keep working "Export all data (JSON/CSV)" and "Delete everything" (local wipe + Firestore doc delete + FCM token revoke).
9. Cloud Functions: group users by geohash before calling weather APIs — one forecast call per cell, never per user. Dedupe alerts: max 1 push per user per 24h per pressure event.
10. Medical disclaimer must appear in onboarding and App Store description. Never generate copy that promises diagnosis, treatment, or prevention.

## Code style

- Small widgets, extract at ~80 lines. Prefer composition over config flags.
- Repositories return domain models, never Drift rows, to features.
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
