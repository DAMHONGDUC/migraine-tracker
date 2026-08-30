# Implemented work

Snapshot: 2026-08-30. This file records what exists; release blockers belong in
[`REMAINING_WORK.md`](REMAINING_WORK.md).

## Product

The v1.0 MVP is implemented. `PLAN.md` is the scope authority.

| Feature | Implemented |
|---|---|
| `attacks` | Offline 3-tap log, optional details, exertion and weather backfill |
| `weather` | WeatherKit callable, conditions and 48h forecast |
| `insights` | Pressure, sleep, steps and exertion correlations |
| `history` | Calendar, list and frequency charts |
| `alerts` | Threshold registration, FCM lifecycle and grouped pressure cron |
| `medications` | Medication details, effectiveness and local reminders |
| `notifications` | Synced reminder and pressure-alert inbox |
| `health` | Read-only HealthKit sleep and steps |
| `auth` | Anonymous use, linked Google/Apple sign-in and account screen |
| `sync` | AES-GCM rows, tombstones, revision tracking and last-write-wins |
| `premium` | RevenueCat entitlement, paywall, restore and feature gates |
| `settings` | Export history, JSON/CSV/PDF, wipe, contact and about |
| `dashboard` | Today summary, quick access and explore grid |
| `onboarding` | Threshold, coarse location and privacy explanation |
| `app_update` | Fail-open force-update gate |
| `home_widget` | App Group bridge and SwiftUI WidgetKit extension |
| `review` | Value-moment prompt with frequency caps |

## Platform and backend

| Area | Status |
|---|---|
| Firebase rules, indexes and functions | Deployed 2026-08-10 |
| WeatherKit app + cron paths | Live 2026-08-12 |
| Push, HealthKit and App Group capabilities | Enabled 2026-08-10 |
| APNs key | Uploaded to Firebase |
| Privacy policy | Published |
| GDPR deletion | Data-only and full-account paths implemented |
| Sync encryption | Server-assisted AES-256-GCM; not end-to-end |

## Delivery

| Asset | Purpose |
|---|---|
| `.github/workflows/ci.yml` | Analyze, test and build Cloud Functions |
| `.github/workflows/release-ios.yml` | Signed TestFlight build and upload |
| `ios/fastlane/` | Preflight, certificates and beta lanes |
| `packages/system_design/tool/build-ipa.sh` | Shared local/CI IPA build |
| `drift_schemas/` | Migration verification against prior schemas |
| Seven ARB files | Complete localization key set |

Tests mirror features under `test/features/`. Real-device behavior remains a
release check because HealthKit, APNs and WidgetKit cannot be proven by unit or
Simulator tests.
