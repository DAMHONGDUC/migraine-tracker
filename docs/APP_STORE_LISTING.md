<!--
  DRAFT App Store metadata for BaroEase. Character limits noted per field.
  Fill [BRACKET] placeholders (URLs) before submission. Copy must never
  promise diagnosis, treatment, or prevention (hard rule 10).
-->

# BaroEase — App Store Listing (draft)

## App name (max 30)
`BaroEase: Migraine Tracker`  *(26)*

## Subtitle (max 30)
`Barometric pressure alerts`  *(26)*

## Promotional text (max 170, editable without review)
> Weather-sensitive migraines? Log an attack in three taps and get a heads-up
> before barometric pressure drops. Private by design — your data stays on your
> device.

## Keywords (max 100, comma-separated, no spaces; don't repeat title/subtitle words)
`headache,weather,tracker,forecast,alert,barometer,log,diary,trigger,journal,storm,sinus`

## Description (max 4000)

BaroEase is a calm, private migraine tracker for people whose attacks flare
when the weather turns — especially when barometric pressure falls.

**Log in three taps**
Intensity → head location → medication. That's it. Logging works fully offline,
so you can record an attack the moment it hits, even with no signal.

**See your weather link**
Every attack is paired with the barometric pressure at that moment. Over time,
BaroEase shows what share of your attacks lined up with rapid pressure drops —
a pattern you can bring to your doctor.

**Get ahead of a pressure drop (Premium)**
Turn on alerts and BaroEase warns you before pressure is forecast to fall past
a threshold you choose — time to hydrate, rest, or take your usual steps early.

**Built for sensitive eyes**
Dark by default, no harsh white screens, no flashing. Designed for photophobia.

**Your data, your device**
BaroEase is local-first. Your attack history lives on your phone and is never
uploaded unless you choose to sign in and sync. No ads. No tracking. Coarse
(~city-scale) location only, and only while you're using the app.

**Premium unlocks**
• Pressure-drop push alerts
• 48-hour pressure forecast chart
• Trigger correlation analysis
• PDF doctor report
• Apple Health sleep correlation

Premium is available monthly ($4.99), yearly ($29.99, with a 7-day free trial),
or as a one-time lifetime purchase ($44.99). Prices may vary by region.

**Full control**
Export everything as JSON or CSV, or delete all your data — including your
account — from Settings, any time.

—

Medical disclaimer: BaroEase is a self-tracking tool and is not a substitute
for professional medical advice, diagnosis, or treatment. It does not diagnose,
treat, cure, or prevent any condition. Always consult a qualified clinician.

## What's New (v1.0)
> First release. Three-tap attack logging, barometric pressure pairing, history
> calendar and charts, pressure-drop alerts, correlation insights, and a PDF
> doctor report. Fully usable offline, dark by default.

## URLs
- Support URL: [https://baroease.app/support]
- Marketing URL: [https://baroease.app]
- Privacy Policy URL: [https://baroease.app/privacy]  *(see docs/PRIVACY_POLICY.md)*

## In-app purchases (App Store Connect)
| Product | Type | Price |
|---------|------|-------|
| Premium Monthly | Auto-renewable subscription | $4.99/mo |
| Premium Yearly | Auto-renewable subscription (7-day free trial) | $29.99/yr |
| Premium Lifetime | Non-consumable | $44.99 |

## App Privacy nutrition label (answers to draft in App Store Connect)

**Data used to track you:** None.

**Data linked to you** (only for account holders who enable sync):
- Health & Fitness → migraine/attack logs (encrypted sync payloads)
- Contact Info → email (from Sign in with Google/Apple)
- Identifiers → account/user ID

**Data not linked to you** (signed-out alert users):
- Coarse Location (city-scale geohash) — App Functionality
- Identifiers → push token — App Functionality

**Not collected:** Precise location, browsing history, search history,
advertising data, contacts, financial info (payments handled by Apple).

## Review notes (for App Review)
- The app is fully functional without an account; a reviewer can log attacks,
  view history, and export/delete data with no sign-in.
- Sign in with Apple is offered alongside Google (4.8) and upgrades the
  anonymous account via linkWithCredential.
- In-app account deletion is in Settings → Delete all data (5.1.1(v)).
- Location is requested While-Using at reduced accuracy only, solely to enable
  optional pressure alerts. Denying it leaves the rest of the app usable.
- Health (sleep) access is optional and read-only; the app functions without it.
