# BaroEase — Barometric Pressure Migraine Tracker

> Name: **BaroEase** (Baro = pressure, Ease = relief). Verify App Store availability + trademark + domain before launch.

## 1. Product Vision

A migraine tracker for weather-sensitive sufferers in US/EU markets.
Two core differentiators vs Migraine Buddy and generic trackers:

1. **Automatic barometric pressure logging + advance warnings** — the app warns users 24–48h before a high-risk pressure drop.
2. **3-tap attack logging** — usable mid-attack. Dark mode by default (photophobia-friendly).

Positioning: *"Know your storm before it hits."*

## 2. Target Market

- Primary: US, UK, Canada, Australia, Northern EU (weather volatility + high subscription willingness).
- User: adults with recurring migraines who suspect weather triggers (~75% of weather-sensitive sufferers cite barometric pressure).
- Language: English first. i18n-ready from day 1 (Flutter `intl`), add DE/FR later.

## 3. Monetization

| Tier | Price | Contents |
|------|-------|----------|
| Free | $0 | Unlimited attack logging, basic history chart, weather snapshot attached to each log, physical exertion self-report + correlation |
| Premium monthly | $5.99/mo | Pressure-drop push alerts, 48h pressure forecast chart, trigger correlation analysis, PDF doctor report, HealthKit sleep + step-count correlation |
| Premium yearly | $39.99/yr | Same as monthly (44% discount framing) |
| Lifetime | $79.99 | Same, one-time (chronic illness communities love lifetime) |

- Managed via **RevenueCat** (free < $2.5k MRR). 7-day free trial on yearly.
- **No ads.** "No ads, we don't sell your data" is a selling point in this niche.

## 4. MVP Scope (v1.0)

### In scope
- [ ] 3-tap attack log: intensity (1–10), pain location (head map), medication taken
- [ ] Optional detail fields (symptoms, triggers, notes) — collapsed by default
- [ ] Auto-attach weather snapshot on each log: pressure, 24/48h pressure delta, humidity, temperature
- [ ] History: calendar view + attack frequency chart
- [ ] Correlation insight (after ≥15 attacks): "X% of your attacks occurred during rapid pressure drops"
- [ ] Pressure alert push notifications (premium) — backend cron, geohash-grouped
- [ ] 48h pressure forecast chart (premium)
- [ ] PDF export report for doctors (premium)
- [ ] Medication reminders (local notifications)
- [x] HealthKit read: sleep hours (premium correlation)
- [x] Physical exertion self-report (free correlation) + HealthKit step count (premium correlation)
- [ ] Onboarding: personal threshold setup, location permission (While Using, coarse), privacy explainer
- [ ] Optional sign-in (Google / Apple) — app fully usable without it; signing in enables encrypted cloud sync of attack history across devices
- [ ] In-app account deletion (App Store 5.1.1(v))
- [ ] Paywall + RevenueCat integration
- [ ] Settings: data export (JSON/CSV), delete all data (GDPR)

### Out of scope (v1.x+)
- Android release (build with Flutter anyway; ship iOS first)
- AI attack prediction, community/forum, coaching plans
- Apple Watch app, widgets (v1.1 — widgets are strong retention)
- Additional weather triggers (pollen, humidity heatmaps)

## 5. Architecture

```
Flutter app (local-first)
├── Local DB: Drift (SQLite) — attacks, meds, weather snapshots
├── State: Riverpod
├── HealthKit via `health` package
├── RevenueCat via `purchases_flutter`
└── Firebase
    ├── Auth (anonymous by default; optional Google/Apple sign-in via
    │   linkWithCredential — upgrades the anonymous UID, never replaces it)
    ├── Firestore (region: europe-west1)
    │   ├── users/{uid}: geohash5, alertThreshold, fcmToken, premium, tz
    │   └── users/{uid}/attacks/{attackId}: encrypted attack payload
    │       (written only when the user signed in and enabled sync)
    ├── Cloud Functions (TypeScript)
    │   ├── cron: pressureAlertJob (every 3h via Cloud Scheduler)
    │   └── webhook: revenuecatWebhook (premium status sync)
    ├── FCM (pressure alerts)
    └── Remote Config (default threshold, feature flags)

Weather data
├── In-app: WeatherKit REST (500k calls/mo free with Apple Developer)
└── Backend cron: Open-Meteo or WeatherKit — 1 call per geohash cell, fan-out to users
```

### Pressure alert flow
1. Premium user enables alerts → app writes `{geohash5, fcmToken, threshold, premium: true}` to Firestore.
2. Cron every 3h: group users by geohash → 1 forecast call per cell.
3. If forecasted drop ≥ threshold (default 5 hPa / 24h, user-tunable) → FCM push.
4. Dedupe: max 1 alert per user per 24h window per event.

### Privacy rules
- Local-first: Drift on-device is the source of truth; the app never requires an account.
- Signed-out users: Firestore holds only coarse geohash + token + settings.
- Signed-in users: attack history syncs as encrypted payloads, disclosed at sign-in. Encryption design (key management, cross-device recovery) decided in the sync phase.
- GDPR: in-app export + full delete incl. account deletion (App Store 5.1.1(v)). Firestore region EU. Privacy policy must disclose Google/Apple sign-in data + sync. App Privacy label: account holders' health data is "linked to identity".
- Medical disclaimer: "Not a substitute for professional medical advice" (App Store requirement for health apps).

## 6. Milestones

| Week | Deliverable |
|------|-------------|
| 1 | Project setup, CI, Drift schema, design system (dark-first), onboarding skeleton |
| 2–3 | Attack logging (3-tap + details), history calendar + charts |
| 4 | Weather snapshot integration (WeatherKit), correlation engine v1 |
| 5 | Firebase backend: cron + geohash grouping + FCM alerts; forecast chart |
| 6 | Auth (Google/Apple, optional) + encrypted attack sync + account deletion |
| 7 | RevenueCat paywall, PDF export, HealthKit sleep |
| 8 | Polish, App Store assets (ASO below), privacy policy, TestFlight beta |
| 9 | Beta feedback from r/migraine recruits → fixes → App Store submission |

## 7. ASO / Launch

- Keywords (long-tail): `barometric pressure migraine`, `weather headache tracker`, `pressure headache alert`, `migraine weather forecast`
- Title pattern: `BaroEase: Migraine Tracker` — subtitle: `Barometric pressure alerts`
- Launch channels: r/migraine (~200k), chronic illness FB groups — recruit beta testers first, don't cold-pitch
- Review prompt after "value moment": first PDF export or first correct pressure alert

## 8. Success Metrics (first 90 days)

- 1,000 downloads, D30 retention ≥ 20%
- Free → trial conversion ≥ 5%, trial → paid ≥ 40%
- ≥ 25 App Store ratings, avg ≥ 4.5
