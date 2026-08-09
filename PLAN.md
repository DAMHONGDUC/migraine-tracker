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
- Language: English and Vietnamese ship in v1 (Flutter `intl`, both ARB files kept in sync); add DE/FR later.

## 3. Monetization

| Tier | Price | Contents |
|------|-------|----------|
| Free | $0 | 40 logged attacks, 5 medications, 2 reminders across all medications; severity donut, weather snapshot attached to each log, physical exertion self-report + correlation, sleep/step summary cards, export + wipe |
| Premium monthly | $4.99/mo | Unlimited attacks/medications/reminders, pressure-drop push alerts, 48h pressure forecast chart, trigger correlation analysis, the other four history charts, PDF doctor report, HealthKit sleep + step-count correlation |
| Premium yearly | $29.99/yr | Same as monthly (50% discount framing) |
| Lifetime | $44.99 | Same, one-time (chronic illness communities love lifetime) |

- Managed via **RevenueCat** (free < $2.5k MRR). 7-day free trial on yearly.
- The full rules — every limit, why each number is what it is, and how a gate behaves — live in `docs/PREMIUM_RULES.md`, which is the authority.
- **No ads.** "No ads, we don't sell your data" is a selling point in this niche.

## 4. MVP Scope (v1.0)

### In scope

A checked box means the code is written and tested. The App Store Connect,
Apple Developer portal and Firebase console work that several of these still
need is tracked separately — `CLAUDE.md`'s "Pending setup" and
`docs/REMAINING_WORK.md`.

- [x] 3-tap attack log: intensity (1–10), pain location (head map), medication taken — plus one skippable exertion step
- [x] Optional detail fields (symptoms, triggers, notes) — collapsed by default
- [x] Auto-attach weather snapshot on each log: pressure, 24/48h pressure delta, humidity, temperature
- [x] History: calendar view + attack frequency chart
- [x] Correlation insight: "X% of your attacks occurred during rapid pressure drops", graded rather than withheld below 15 attacks
- [x] Pressure alert push notifications (premium) — backend cron, geohash-grouped
- [x] 48h pressure forecast chart (premium)
- [x] PDF export report for doctors (premium), with an export history that can be re-shared
- [x] Medication reminders (local notifications), 2 free across all medications (see `docs/PREMIUM_RULES.md`)
- [x] Notification list — reminders and pressure alerts, synced so every device shows the same list
- [x] HealthKit read: sleep hours (premium correlation)
- [x] Physical exertion self-report (free correlation) + HealthKit step count (premium correlation)
- [x] Onboarding: personal threshold setup, location permission (While Using, coarse), privacy explainer
- [x] Optional sign-in (Google / Apple) — app fully usable without it; signing in enables encrypted cloud sync across devices
- [x] In-app account deletion (App Store 5.1.1(v))
- [x] Force-update gate, fails open (`app_update`)
- [x] Paywall + RevenueCat integration
- [x] Settings: data export (JSON/CSV), delete all data (GDPR)
- [x] Two locales: English and Vietnamese

### Out of scope (v1.x+)
- Android release (build with Flutter anyway; ship iOS first)
- AI attack prediction, community/forum, coaching plans
- Apple Watch app, widgets (v1.1 — widgets are strong retention)
- Additional weather triggers (pollen, humidity heatmaps)

## 5. Architecture

```
Flutter app (local-first)
├── Local DB: Drift (SQLite) — attacks, weather snapshots, medications,
│   reminders, notifications, exports, sync tombstones
├── State: Riverpod
├── HealthKit via `health` package (sleep + steps, read-only)
├── RevenueCat via `purchases_flutter`
└── Firebase
    ├── Auth (anonymous by default; optional Google/Apple sign-in via
    │   linkWithCredential — upgrades the anonymous UID, never replaces it)
    ├── Firestore (region: europe-west1) — flat, relational-shaped
    │   ├── users/{uid}: geohash5, alertThreshold, fcmToken, premium, tz,
    │   │   plus account fields once signed in
    │   ├── attacks/{id}, medications/{id}, medication_reminders/{id},
    │   │   notifications/{id}: encrypted payload + plaintext userId and
    │   │   updatedAt. userId is the entire ownership boundary
    │   ├── sync_keys/{uid}: the account's AES key — denied to every client
    │   └── app_updates/{id}: public, read-only force-update records
    ├── Cloud Functions (TypeScript)
    │   ├── cron: pressureAlertJob (every 3h via Cloud Scheduler)
    │   ├── callable: getSyncKey (mints/returns the account key)
    │   ├── callable: deleteAccount (the server half of the teardown)
    │   └── webhook: revenuecatWebhook (premium status sync)
    ├── FCM (pressure alerts)
    ├── Crashlytics + Analytics (usage only, never health data)
    └── Remote Config (default threshold, feature flags)

Weather data
├── In-app: Open-Meteo today; WeatherKit REST once a key exists
└── Backend cron: Open-Meteo — 1 call per geohash cell, fan-out to users
```

### Pressure alert flow
1. Premium user enables alerts → app writes `{geohash5, fcmToken, threshold, premium: true}` to Firestore.
2. Cron every 3h: group users by geohash → 1 forecast call per cell.
3. If forecasted drop ≥ threshold (default 5 hPa / 24h, user-tunable) → FCM push.
4. Dedupe: max 1 alert per user per 24h window per event.

### Privacy rules
- Local-first: Drift on-device is the source of truth; the app never requires an account.
- Signed-out users: Firestore holds only coarse geohash + token + settings.
- Signed-in users: attacks, medications, reminders and notifications sync as
  encrypted payloads, disclosed at sign-in. Sync is automatic and has no
  toggle — signing in is the consent.
- **Encryption is server-assisted, not end-to-end.** The per-account AES-256
  key is minted and held by the `getSyncKey` callable in `sync_keys/{uid}`,
  denied to every client. Google infrastructure can therefore decrypt, so no
  copy anywhere may say "only you can read this". No key rotation.
- GDPR: two separate actions — "delete all data" keeps the account, "delete
  account" tears everything down (App Store 5.1.1(v)). Firestore region EU.
  Privacy policy must disclose Google/Apple sign-in data, sync, Crashlytics
  and Analytics. App Privacy label: account holders' health data is "linked
  to identity"; HealthKit sleep/steps never leave the device.
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
