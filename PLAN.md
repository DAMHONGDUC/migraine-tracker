# BaroEase product plan

## Product

| Item | Decision |
|---|---|
| Audience | Adults with recurring, weather-sensitive migraines |
| Markets | US, UK, Canada, Australia and Northern Europe |
| Promise | Understand pressure-related risk before an attack |
| Main differentiators | 24–48h pressure warning and 3-tap attack logging |
| Experience | Offline-first, dark-first and usable during an attack |
| Languages | English, Vietnamese, Japanese, German, Spanish, French and Chinese |
| Positioning | “Know your storm before it hits.” |

Verify the BaroEase name, trademark, App Store availability and domain before
launch.

## Business model

| Tier | Price | Access |
|---|---:|---|
| Free | $0 | Core tracking with record limits |
| Premium monthly | $4.99/month | All premium features |
| Premium yearly | $29.99/year | Same access, 7-day trial |

There are no ads and no lifetime product. RevenueCat manages subscriptions.
[`docs/PREMIUM_RULES.md`](docs/PREMIUM_RULES.md) is the authority for every
price, limit and gate.

## MVP status

All planned v1.0 app features are implemented.

| Area | Included |
|---|---|
| Attack tracking | 3-tap log, optional details, exertion and weather snapshot |
| History | Calendar, list and charts |
| Insights | Pressure, sleep, step and exertion correlations |
| Weather | Current conditions and 48h pressure forecast |
| Alerts | Premium pressure-drop push alerts |
| Medication | Medication list, effectiveness and reminders |
| Health | Read-only HealthKit sleep and steps |
| Account | Optional Google/Apple sign-in and account deletion |
| Sync | Encrypted attacks, medications, reminders and notifications |
| Premium | RevenueCat paywall, restore and feature gates |
| Data | JSON, CSV and PDF exports; free GDPR deletion |
| Platform | Force update, onboarding, home widget and review prompt |
| Localization | Seven complete locales |

Release blockers are tracked only in
[`docs/REMAINING_WORK.md`](docs/REMAINING_WORK.md).

## Out of scope

| Later | Not planned |
|---|---|
| Android polish and release | Community/forum |
| Apple Watch app | Machine-learned attack prediction |
| More weather triggers | Coaching plans |

Work queued behind v1.0 — daily logging, cycle, trigger/protector maps, a
rule-based risk score and richer pressure warnings — lives in
[`docs/ROADMAP.md`](docs/ROADMAP.md). The risk score there is deterministic
weights the user can read, which is why it is not the row above.

## Architecture

| Layer | Technology | Responsibility |
|---|---|---|
| App | Flutter + Riverpod | UI and orchestration |
| Local data | Drift/SQLite | On-device source of truth |
| Navigation | go_router | App routes |
| Health | HealthKit via `health` | Read-only sleep and steps |
| Subscription | RevenueCat | Entitlement state |
| Backend | Firebase, europe-west1 | Auth, sync, alerts and config |
| Weather | WeatherKit REST | Backend-only weather source |
| Observability | Crashlytics + Analytics | Failures and non-health usage events |

### Firebase ownership

| Service | Purpose |
|---|---|
| Auth | Anonymous by default; optional linked Google/Apple credentials |
| Firestore | Profiles, encrypted sync rows, sync keys and app updates |
| Cloud Functions | Weather, pressure cron, sync key, deletion and webhook |
| FCM | Pressure alerts |
| Remote Config | Threshold defaults and flags |

### Pressure alert flow

| Step | Action |
|---:|---|
| 1 | Premium user enables alerts and saves coarse location + threshold |
| 2 | A 3-hour cron groups users by geohash |
| 3 | The backend requests one WeatherKit forecast per cell |
| 4 | A drop at or above the threshold sends FCM |
| 5 | Dedupe limits each user to 3 alerts a day, 8h apart, one per event |
| 6 | An alert landing in the user's local night (22:00-07:00) is sent silently |

## Privacy boundaries

| Boundary | Rule |
|---|---|
| Account | Optional; the app remains usable signed out |
| Device | Drift remains the source of truth |
| Sync | AES-256-GCM; server-assisted, not end-to-end encrypted |
| HealthKit | Sleep stays on-device; a step count attached to an attack may sync |
| Location | Coarse geohash only for alerts |
| Deletion | “Delete data” keeps the account; “Delete account” removes both |
| Medical use | Not a substitute for professional medical advice |

## Launch targets

| Metric | First 90 days |
|---|---:|
| Downloads | 1,000 |
| D30 retention | ≥20% |
| Free-to-trial | ≥5% |
| Trial-to-paid | ≥40% |
| App Store rating | ≥25 ratings, average ≥4.5 |

| Launch item | Direction |
|---|---|
| Keywords | Barometric pressure migraine, weather headache tracker, pressure headache alert |
| Store title | `BaroEase: Migraine Tracker` |
| Subtitle | `Barometric pressure alerts` |
| Channels | Migraine communities; recruit beta testers before promotion |
| Review prompt | After a doctor report or a correctly timed pressure alert |
