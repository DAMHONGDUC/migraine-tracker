# Privacy, secrets and GDPR

Hard rules 1, 2, 8, 11, 13 and 17. These outrank convenience everywhere.

## 1. Local-first, account optional

Every feature except sync and alerts must work without an account.

- **Weather is free; PRESSURE is what is sold.** Owner's rule, and the line
  moved: not "weather free, alert premium" but "everything except pressure is
  free". `WeatherCard` gives every user conditions, UV, wind, rain, humidity
  and visibility, hourly across a week, signed in or not. Premium is the
  pressure chart **and** the alert — `PressureForecastBody` gates itself, the
  cron reads `users` where `premium == true`. The snapshot attached to a logged
  attack stays free and unconditional (hard rule 4 depends on it).
  - **So the weather card carries no pressure at all.** The same reading given
    away free on one card and sold on `/pressure` is what makes a paywall look
    arbitrary. `WeatherMetric` is iOS Weather's list minus pressure, and that
    omission is the rule.
  - **A free user issues no WeatherKit call for the forecast.**
    `PressureForecastBody` checks premium *before* watching
    `pressureForecastProvider`, so the locked branch costs nothing against the
    500k monthly quota. `WeatherCard`'s own fetch is separate and free.
- **The app signs in anonymously at launch**
  (`AppBootstrap._ensureAnonymousSession`): `getWeather` spends our WeatherKit
  key and will not serve a caller it cannot name. The user is never asked for
  anything. **Anonymous must be enabled in the Firebase console** — without it
  the call throws `admin-restricted-operation`, the guard swallows it, and
  weather is silently dead on every fresh install.
- **An account is required to buy premium** (`PurchaseIdentity` binds only when
  `isSignedIn`), **and premium is required for alerts.** Registration refuses a
  signed-out or anonymous device (`AlertRegistrationError.accountRequired`)
  rather than writing a token the cron can never read, and a free user is never
  shown the switch at all.

**What Firestore holds.** Signed out: geohash (5 chars, ~5km), FCM token, alert
threshold, timezone, premium flag — nothing else. Signing in adds account
fields to the same `users/{uid}` doc: display name, email, photo URL,
created/updated timestamps. Health data is uploaded only for signed-in users,
as encrypted payloads in the top-level `attacks` / `medications` /
`medication_reminders` collections tagged with `userId`, and sync must be
disclosed in the sign-in UI. **Any other path that uploads health data: stop
and flag it** — including `AppAnalytics`, whose events carry usage only, never
intensity, head location, medication names, attack timestamps or coordinates.

## 2. Location: While-Using and reduced accuracy only

Never request Always.

- **Two surfaces raise the prompt and no others**: the onboarding step and the
  dashboard weather card (`_LocationPrompt`, owner's call). Reading a position
  never prompts — `LocationSource` splits `currentPosition` from
  `requestPermission` for that reason, and `locationPermissionProvider` reads
  the status without asking. The card asks because a "Not now" in onboarding
  used to be final: nothing asked again, and the card said only that weather
  was unavailable, which reads as broken rather than declined. It goes through
  `AppPermission.ensure`, so a denial iOS will no longer prompt for falls
  through to `PermissionSettingsSheet` instead of a dead button.
- **The place name is the OS geocoder and must stay that way.**
  `GeocodingPlaceNameSource` hands the coarse position to `CLGeocoder` via the
  `geocoding` package: no API key, no service of ours, and the coordinate never
  reaches our backend sharper than the ~11km it already rounds to. A
  server-side reverse geocode would send a sharper position than the app has
  ever sent. The name is shown as-is and stored nowhere.
- Reduced accuracy is why the card promises a *place*, not a ward: from a
  ~1–20km region the geocoder usually names a district or a city, so `_name`
  widens from `subLocality` outwards. Never sharpen the accuracy request to
  make the label finer.

## 8. GDPR: two destructive actions, deliberately separate

**"Delete all data"** (Settings) clears the records — device, account copy,
past exports — and gives up the FCM token, geohash and threshold, but keeps the
account: someone clearing their history usually wants to carry on, and losing
the account would unbind their subscription with it.

**"Delete account"** (Account screen) is the whole teardown: local wipe,
Firestore doc, synced records, FCM token revoke, then Firebase Auth. App Store
5.1.1(v) requires it in-app now that accounts exist.

- **Its server half is the `deleteAccount` callable of necessity.**
  `firestore.rules` denies a client deleting `users/{uid}` (its write rule reads
  `request.resource.data`, absent on a delete) and denies `sync_keys/{uid}` to
  everyone.
- **The auth user goes last.** Delete it first and every remaining step is
  unauthorised, leaving records nobody can reach.
- The dialog says the subscription is **not** cancelled — a user who assumes
  otherwise keeps being charged.
- **Exports are health data on disk.** Each export is written to the app's
  documents directory and recorded so it can be re-shared later, so the wipe
  must delete the files and their rows too, or "delete everything" leaves
  copies in `Documents/exports/`. Anything new that persists health data
  inherits this.
- **The in-app export is Premium in full** (owner's call, 2026-08-19) — JSON and
  CSV as well as the PDF. The wipe is what stays free: deleting your own
  records is a right; selling the file that carries them out is not the same
  question. Portability is met by the support route the privacy policy names,
  which answers an export request by email at no cost — move both together if
  that route changes.
- **The wipe shows spinner and percentage.** It reaches the network, the OS
  scheduler and several tables, so it can run long enough that a row which only
  spins cannot tell slow from stuck — same widget as the sync row
  (`SettingsRowProgress`, `core/widgets/`, reading `commonProgressPercent`).
  `SettingsController` is a `Notifier<WipeStatus>`, so the indicator survives a
  rebuild and the dev reset gets it free.
  - **Progress counts `DataWipeService.steps`, never records.** Counting rows
    means discovering more work mid-wipe, and a bar that jumps backwards reads
    as a bug. A step added to `wipeAll` moves that constant in the same change;
    `data_wipe_service_test.dart` asserts 0..steps with nothing skipped.
  - The controller divides by `steps + 1`: the Apple Health disconnect after the
    service returns is one more step, and without it the bar sits at 100% while
    work continues.

## 11. Medical disclaimer

Must appear in onboarding and the App Store description. Never generate copy
promising diagnosis, treatment or prevention.

## 13. Never read `env/`

Not with Read, not with `cat`/`grep`/`sed`, not "just one field".
`env/dev.json` and `env/prod.json` hold live Firebase and RevenueCat keys, and
anything read there is copied into a transcript that outlives the session.
**There is no read small enough to be safe: the harm is the copy, not the
size.**

- **Use instead**: `env/*.example.json` are committed key-only templates — they
  answer "what keys exist" with no values. The Firebase project id is in
  `.firebaserc`, and `firebase use` prints it. Anything else, ask the owner.
- Reading the *names* of files in `env/` is fine. Writing is fine too —
  `melos run set-up` and `melos run prepare-env-dev|prod` create them, and they
  are the only things that should.
- **`ios/Flutter/Generated.xcconfig` is the same secret under another name.**
  Flutter writes every `--dart-define-from-file` value into its `DART_DEFINES=`
  line as base64: live keys in a form that looks like build config and reads
  back as plaintext. It was opened once while wiring the widget extension's
  version numbers, and the keys landed in a transcript. Nothing there is worth
  reading — `FLUTTER_BUILD_NAME` and `FLUTTER_BUILD_NUMBER` come from
  `pubspec.yaml`'s `version:` — and referencing it from an xcconfig is fine as
  long as nothing opens it. Same for `ios/Flutter/{Debug,Release,Profile}.xcconfig`,
  which `#include` it.
- `.claude/settings.json` denies the obvious paths, but `Bash` is broadly
  allowed and no pattern list can close every way a shell command could read the
  folder. **The rule is the guarantee; the deny list is only a guard rail.**

## 17. The privacy policy is two files saying one thing

`docs/privacy/PRIVACY_POLICY.md` is the readable source, `docs/privacy/privacy.json`
is what the published site renders. A change that moves data updates both in
the same change, effective/last-updated dates included.

- **The JSON is one app object at the top level**, in the sample's field order:
  `name`, `tagline`, `icon`, `accent`, `platforms`, `effectiveDate`,
  `lastUpdated`, `contactEmail`, `url`, `storeLinks`, `overview`, `summary`,
  `collects`, `notCollected`, `permissions`, `thirdParties`, `sections`.
  `{{app}}`, `{{publisher}}` and `{{email}}` are filled in by the site. **The
  schema has changed four times** — match the sample the owner last sent, not
  the file. `url` (`https://damhongduc.github.io/apps_privacy_policy`) is the
  owner's instruction and the only field not in the sample; keep it.
- **The site renders shared `defaults.sections` around this file** —
  who-we-are, how-we-use, retention, security, children, your-rights, changes,
  contact. So this file carries only what is specific to BaroEase and must not
  restate GDPR boilerplate.
  - **Reusing a `defaults` id in `sections` replaces that section for this app
    alone.** That is why `children` appears here: the shared default says under
    13, an EU-targeted health app needs 16. Never duplicate a section under a
    new id — both would render.
  - **If the shared boilerplate can no longer be overridden**, BaroEase's
    under-16 line sits beside the shared under-13 one rather than replacing it,
    and a health app must not ship both. Raise it with the owner.
- **`overview` is three short paragraphs (~100 words)** — the intro, not the
  policy. Facts go in `collects`/`permissions`/`thirdParties`, which render as
  tables; anything longer goes in `sections`. A schema revision once removed
  `sections` and all of it got crammed into `overview`, tripling it.
- **Two claims must never soften.** Sync is encrypted but **not** end-to-end —
  `getSyncKey` holds the key, so Google infrastructure can decrypt, and no
  wording may imply otherwise (the bar `loginPrivacyNote` and `accountDataNote`
  are held to). And the app **does** use Firebase Analytics and Crashlytics —
  the policy claimed "no third-party analytics" for months after they shipped,
  which is the drift this rule exists to stop.
- **What must be listed**, each being a flow a reader would not guess: the
  signed-out alert record, the signed-in account fields, the four synced
  collections with their plaintext `userId`/`updatedAt`, the two HealthKit
  permissions that never leave the device, export files kept on disk, the home
  screen widget's App Group (this week's attack count and latest pressure, on
  device, cleared by the wipe), and the two destructive actions being different.
- **A new data flow means editing both files before the feature is done.**
  Nothing enforces this, which is why it is written here.
- `[ADDRESS/COUNTRY]` in the markdown is the owner's to fill. The support
  address (`AppEnv.supportEmail`, default `support@baroease.app`) is a different
  thing from the privacy contact (`ducdam.dev@gmail.com`); don't collapse them.
