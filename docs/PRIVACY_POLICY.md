<!--
  DRAFT — review before publishing. Fill every [BRACKET] placeholder:
  legal entity/developer name, contact email, hosting URL, effective date.
  HealthKit sleep is documented here for the full v1 feature set; the
  §"Health data (Apple Health)" clause only applies once that feature ships.
  Have a lawyer review before App Store submission.
-->

# BaroEase — Privacy Policy

**Effective date:** [DATE]
**Developer / data controller:** [LEGAL NAME], [ADDRESS/COUNTRY]
**Contact:** [privacy@baroease.app]

BaroEase helps people who track migraine attacks and their possible link to
barometric-pressure changes. We built it local-first: your health data lives
on your device, and an account is optional. This policy explains what we
collect, why, where it goes, and the controls you have.

## 1. Our core principle: local-first

- Your migraine attacks, symptoms, triggers, notes, and medications are stored
  **only on your device** by default. They are never uploaded unless you
  create an account and the sync feature is enabled (see §4).
- The app is fully usable with **no account and no internet connection**.
  Logging an attack works entirely offline.

## 2. What we collect and why

### a. Data that stays on your device
Attack logs (intensity, head location, time), symptoms, triggers, notes,
medications, and any weather snapshot attached to an attack. We do not receive
this data. You can export or delete it at any time (§7).

### b. Data sent to our backend — even without an account
To deliver **pressure-drop alerts** (a premium feature you switch on), we store
a minimal record in our database, associated with a random device identifier
rather than your name:

| Data | Purpose |
|------|---------|
| **Coarse location** — a ~2–5 km geohash (5 characters), never your precise coordinates | Group nearby users into one weather-forecast lookup and decide whether a pressure drop is coming |
| **Push notification token** (FCM) | Deliver the alert to your device |
| **Alert threshold** (a pressure value you set) | Decide when an alert is warranted |
| **Time zone** | Time alerts sensibly |
| **Premium flag** | Confirm the alert entitlement is active |

We do **not** send attack or health data to the backend for this feature.

### c. Location precision
The app requests location **only While Using the app** and at **reduced
(coarse) accuracy**. We never request "Always" access and never store precise
coordinates. You can deny location; alerts simply won't be available.

### d. Weather data
To fetch forecasts we send a **coarse location** (city-scale) to a weather
provider — Apple WeatherKit and/or Open-Meteo. No identifier or health data is
sent with these requests. See their policies: Apple
(apple.com/legal/privacy) and Open-Meteo (open-meteo.com).

## 3. Accounts and sign-in (optional)

You may sign in with **Google** or **Apple** to sync your data across devices.
Sign-in is never required. When you sign in we receive a stable account
identifier and the email/name your provider releases (Apple lets you hide your
email via Private Relay). We use this only to authenticate you and link your
data to your account.

## 4. Encrypted sync (only for signed-in users)

If you sign in and enable sync, your attack history is uploaded as
**encrypted payloads** stored under your account. This is disclosed to you at
sign-in before any upload happens. Your on-device copy always remains the
source of truth. If you never sign in, nothing in this section applies.

## 5. Health data (Apple Health) — optional

If you grant permission, BaroEase reads your **sleep duration** from Apple
Health, **read-only**, to look for a correlation with your attacks. This
analysis runs **on your device**. We never write to Apple Health and never
upload Health data. You can revoke this in the iOS Health settings at any time.

## 6. Payments

Subscriptions and the lifetime purchase are processed by **Apple** and managed
through **RevenueCat**, our subscription infrastructure provider. We never see
or store your card details. RevenueCat receives a purchase identifier to tell
us whether your premium entitlement is active.

## 7. Your rights and controls (GDPR)

- **Export everything:** Settings → Export data (JSON or CSV).
- **Delete everything:** Settings → Delete all data. This wipes the local
  database and, if you have an account, deletes your backend record, your
  synced attacks, revokes your push token, and deletes your authentication
  account.
- You may also request access, correction, or deletion, or object to
  processing, by contacting us at [privacy@baroease.app].

## 8. Where data is stored

Backend data (the minimal alert record and any encrypted sync payloads) is
hosted on **Google Firebase** in the **European Union** (region
`europe-west1`). Google acts as our data processor.

## 9. What we do NOT do

- No advertising and no ad networks.
- No third-party analytics or tracking SDKs; we do not sell or share your data
  for marketing.
- No selling of personal data, ever.

## 10. Data retention

On-device data persists until you delete it or remove the app. Backend alert
records persist while the feature is enabled and are removed when you delete
your data or disable alerts. Encrypted sync payloads are removed when you
delete your data or your account.

## 11. Children

BaroEase is not directed to children under 16 and we do not knowingly collect
their data.

## 12. Changes

We will post any changes here and update the effective date. Material changes
will be surfaced in-app.

## 13. Medical disclaimer

BaroEase is a self-tracking tool. It is **not a substitute for professional
medical advice, diagnosis, or treatment**. It does not diagnose, treat, cure,
or prevent any condition. Always consult a qualified clinician about your
health.

---

*Contact: [privacy@baroease.app]*
