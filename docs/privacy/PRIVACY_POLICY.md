<!--
  Keep this file and docs/privacy/privacy.json saying the same thing — the JSON is
  what the published site renders, this is the readable source.
  Four claims are load-bearing and must never soften:
  - sync is encrypted but NOT end-to-end (we hold the key),
  - the app does use Firebase Analytics and Crashlytics, with no in-app opt-out,
  - the step count for the day of an attack DOES leave the device, and
  - weather is Apple WeatherKit, called by our backend, never by the app.
  No placeholders left. Have a lawyer review before App Store submission.
-->

# BaroEase — Privacy Policy

**Effective date:** 7 August 2026
**Last updated:** 26 August 2026
**Developer / data controller:** Dam Hong Duc, Ho Chi Minh City, Viet Nam
**Contact:** ducdam.dev@gmail.com

BaroEase helps people who track migraine attacks and their possible link to
barometric-pressure changes. We built it local-first: your health data lives
on your device, and an account is optional. This policy explains what we
collect, why, where it goes, and the controls you have.

## 1. Our core principle: local-first

- Your migraine attacks, symptoms, triggers, notes, medications, reminders
  and notification history are stored **on your device**. They are never
  uploaded unless you sign in (see §4).
- The app is fully usable with **no account and no internet connection**.
  Logging an attack works entirely offline.
- Signing out or never signing in does not cost you any feature except
  cross-device sync.

## 2. What we collect and why

### a. Data that stays on your device

Attack logs (intensity, head location, time, physical exertion), symptoms,
triggers, notes, medications and their reminders, the weather snapshot
attached to each attack, and the in-app notification history. If you are not
signed in, we never receive any of it. You can export or delete it at any
time (§8).

If you turn on the **home screen widget** (Settings → Home screen widget), the
app also writes what the widget shows — the number of attacks you logged this
week and the most recent barometric pressure reading — into a container shared
between the app and the widget on your device. Nothing leaves the phone, and
switching the widget off empties that container immediately. A "delete all
data" clears it too.

### b. Data sent to our backend — even without an account

To deliver **pressure-drop alerts** (a premium feature you switch on), we
store a minimal record in our database, associated with the anonymous
account identifier your installation is given at first launch, not with your
name:

| Data | Purpose |
|------|---------|
| **Coarse location** — a ~5 km geohash (5 characters), never your precise coordinates | Group nearby users into one weather-forecast lookup and decide whether a pressure drop is coming |
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

Weather comes from **Apple WeatherKit**, and the app never calls it directly:
it asks our backend, and our backend asks Apple.

- The app sends its **reduced-accuracy** position to our weather function.
  That position is **rounded to a ~11 km cell** before anything else happens,
  so what reaches Apple is the centre of that cell, never where you are.
- The rounded cell is also what the forecast is cached against, for an hour,
  shared by everyone in it. That cache holds weather, not people: it carries
  no account identifier, no device identifier and no health data.
- Nothing about you travels with a weather request — no identifier, no attack,
  no symptom.

The place name shown on the weather card is resolved by **your device's own
geocoder** (Apple on iOS), from the same reduced-accuracy position. That
lookup goes from your phone to the platform, never through us.

### e. Diagnostics and usage analytics

BaroEase uses **Firebase Crashlytics** (crash reports and non-fatal errors)
and **Firebase Analytics** (how the app is used). Both are always on and the
app does not yet offer a switch to turn them off; if you want yours stopped or
erased, write to ducdam.dev@gmail.com and we will do it.

- Analytics records **actions, never content**: that an attack was logged,
  that the paywall was opened, that an export was shared. It never carries
  intensity, head location, medication names, attack times or coordinates.
- Crashlytics records the crash, the device model and the OS version.
- While you are signed in, both are tagged with your account identifier — an
  opaque ID, not your name or email — so a crash can be traced to one
  account. Signing out clears it.

## 3. Accounts and sign-in (optional)

You may sign in with **Google** or **Apple**. Sign-in is never required. When
you sign in we receive a stable account identifier and the email, name and
photo your provider releases (Apple lets you hide your email via Private
Relay). We store these in your account record and use them only to
authenticate you and to show you which account you are in.

## 4. Sync (automatic once you sign in)

Signing in turns on cross-device sync — there is no separate switch, and the
sign-in screen says so before you sign in. From then on your attacks,
medications, medication reminders and notification history are uploaded as
**encrypted payloads** and pulled down on your other devices. Your on-device
copy always remains the source of truth, and no screen ever waits on a sync.

Two things travel with each record in readable form, because sync cannot work
without them: **which account owns it**, and **when it was last changed**.
Neither says anything about what is in the record.

**Important — this is encryption, not end-to-end encryption.** The key for
your account is generated and held by our backend so that a new device of
yours can be given it after you sign in. That means Google's infrastructure,
which hosts our backend, is technically able to decrypt these payloads. We do
not read them, and nothing in the app is designed to. But we will not claim
that only you can read them, because that would not be true.

Exports (see §8) deliberately never sync — they stay on the device that made
them.

## 5. Health data (Apple Health) — optional, iOS only

If you grant permission, BaroEase reads from Apple Health **read-only**:

- **Sleep**, to look for a correlation with your attacks.
- **Step count**, to look for a correlation with your attacks.

These are **two separate permissions with two separate switches** — allowing
one does not allow the other. The analysis runs **on your device** and we
never write to Apple Health.

**Sleep never leaves your device.** Your **step count** does, in one narrow
way: when you log an attack, BaroEase records how many steps you had taken
that day up to that moment and saves the number with the attack, because how
active you were before an attack is part of the record a doctor reads. It
travels with that attack — into your export, your doctor report, and your
encrypted sync if you are signed in (§4). Nothing else from Apple Health is
stored or uploaded, and you can revoke access at any time in the iOS Health
settings.

## 5b. What our App Store privacy labels say

Apple asks every developer to declare, on the App Store product page, what an
app collects, whether it is linked to your identity, and whether it is used to
track you. This is exactly what BaroEase declares, so you can hold the labels
and this policy against each other and see that they agree.

**"Tracking" has a specific meaning in Apple's rules**: linking data from this
app with third-party data for advertising or advertising measurement, or
sharing it with a data broker. BaroEase does none of that — no ad network, no
attribution SDK, no advertising identifier is read, and nothing is sold or
handed to a data broker. **Every item below is declared as not used for
tracking**, and the app contains no App Tracking Transparency prompt because
there is nothing to ask permission for.

| Data type | Purpose | Linked to you | Tracking | What it is |
|---|---|---|---|---|
| Name | App Functionality | Yes | **No** | From the account you sign in with |
| Email address | App Functionality | Yes | **No** | From the account you sign in with |
| Health | App Functionality | Yes | **No** | Your synced attack log, medications and reminders |
| Coarse location | App Functionality | Yes | **No** | A ~5 km area, never coordinates |
| User ID | App Functionality | Yes | **No** | The opaque account identifier |
| Device ID | App Functionality | Yes | **No** | The push token that delivers pressure alerts |
| Purchase history | App Functionality | Yes | **No** | Which subscription you hold, via RevenueCat |
| Product interaction | Analytics | Yes | **No** | Which screens and features get used |
| Crash data | App Functionality | Yes | **No** | Crashes and non-fatal errors |
| Fitness | App Functionality | Yes | **No** | The step count saved with an attack |

Your sleep is not declared at all, because it never leaves your device (§5).
Fitness **is** declared, because the step count for the day of an attack is
saved with that attack. Health **is** declared, because your attack log syncs
to our backend once you sign in (§4).

## 6. Notifications

- **Medication reminders** are scheduled by your device and never leave it.
- **Pressure alerts** are push notifications sent from our backend using the
  token described in §2b.

Both appear in the in-app notification list. For signed-in users that list
syncs like any other record (§4), so every device shows the same history.

## 7. Payments

Subscriptions and the lifetime purchase are processed by **Apple** and
managed through **RevenueCat**, our subscription infrastructure provider. We
never see or store your card details. RevenueCat receives a purchase
identifier and, once you are signed in, your account identifier — so your
entitlement follows you rather than one installation.

## 7b. Sharing an attack

From an attack's detail screen you can share it as an **image** — to a
partner, a family member, or anyone else you choose.

- **What the image carries:** when the attack started, how intense it was,
  how long it lasted, and where on your head it hurt.
- **What it never carries:** your notes, your symptoms, your triggers, the
  medication you took, or your location. You see the exact image before you
  send it, because what gets shared is the preview you are looking at.
- **Where it goes:** only where you send it. The image is handed to the iOS
  share sheet and goes to the app you pick. It is never uploaded to us, we
  never see it, and it never reaches our backend.
- **The file:** written to the app's temporary storage so the share sheet can
  read it. **"Delete all data" clears it** along with the database, your past
  exports, the daily pressure readings and the widget's container — iOS would
  reclaim that storage eventually, but "eventually" is not a deletion you
  asked for.

## 8. Your rights and controls (GDPR)

- **Export everything:** Settings → Export data (JSON, CSV or a PDF doctor
  report). The in-app export is a **Premium** feature; if you do not have
  Premium, write to ducdam.dev@gmail.com and we will send you your data free
  of charge, as below. Past exports are kept in the app so you can re-share
  them; they are full copies of your data and are deleted along with
  everything else below.
- **Delete all data:** Settings → Delete all data. Wipes the local database,
  past export files, any shared attack image and the home screen widget's
  shared container, deletes
  your synced records and your backend alert record, and gives up your push
  token, geohash and threshold. **Your account stays**, so your subscription
  binding survives.
- **Delete your account:** Account screen → Delete account. The whole
  teardown: synced records, your account record, your encryption key, then
  the login itself. This does **not** cancel your subscription — that lives
  in the App Store and only you can cancel it there.
- You may also request access, correction, export, deletion, or object to or
  restrict processing, by writing to ducdam.dev@gmail.com. We respond within
  30 days.

## 9. Where data is stored

Backend data — the minimal alert record, your account record, the encrypted
sync payloads and your account's encryption key — is hosted on **Google
Firebase** in the **European Union** (region `europe-west1`). Google acts as
our data processor. Crash and analytics data is processed by Google under the
Firebase terms.

## 10. Third parties

| Provider | What it handles |
|----------|-----------------|
| **Google Firebase** (Auth, Firestore, Cloud Functions, Cloud Messaging) | Accounts, the alert record, encrypted sync payloads, push delivery |
| **Firebase Crashlytics** | Crash and error reports |
| **Firebase Analytics** | Usage events (§2e) |
| **RevenueCat** | Subscription and entitlement state |
| **Apple WeatherKit** | Weather forecasts, requested by our backend for a ~11 km cell |
| **Google Sign-In / Sign in with Apple** | Authentication, only if you use them |

## 11. What we do NOT do

- No advertising and no ad networks.
- No selling or sharing of personal data for marketing, ever.
- No advertising profiles, and no health data in any analytics event.

## 12. Data retention

On-device data persists until you delete it or remove the app. Backend alert
records persist while the feature is enabled and are removed when you delete
your data or disable alerts. Encrypted sync payloads and your account's
encryption key are removed when you delete your data or your account. Crash
and analytics data is retained under Google's own Firebase retention policy.

## 13. Children

BaroEase is not directed to children under 16 and we do not knowingly collect
their data. If you believe a child has provided us with personal information,
write to ducdam.dev@gmail.com and we will delete it.

## 14. Changes

We will post any changes here and update the date at the top. Material
changes will be surfaced in-app before they take effect.

## 15. Medical disclaimer

BaroEase is a self-tracking tool. It is **not a substitute for professional
medical advice, diagnosis, or treatment**. It does not diagnose, treat, cure,
or prevent any condition. Always consult a qualified clinician about your
health.

---

*Contact: ducdam.dev@gmail.com*
