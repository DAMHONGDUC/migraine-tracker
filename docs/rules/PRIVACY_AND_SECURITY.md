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
    away free on one card and sold on the pressure card is what makes a paywall look
    arbitrary. `WeatherMetric` is iOS Weather's list minus pressure, and that
    omission is the rule.
  - **A free user issues no WeatherKit call for the forecast.**
    `PressureForecastBody` checks premium *before* watching
    `pressureForecastProvider`, so the locked branch costs nothing against the
    500k monthly quota. `WeatherCard`'s own fetch is separate and free.
- **The app signs in anonymously at launch**
  (`AppBootstrap.ensureAnonymousSession`): `getWeather` spends our WeatherKit
  key and will not serve a caller it cannot name. The user is never asked for
  anything. **Anonymous must be enabled in the Firebase console** — without it
  the call throws `admin-restricted-operation`, the guard swallows it, and
  weather is silently dead on every fresh install.
- **An account is NOT required to buy premium** (App Store 5.1.1(v), and
  `docs/PREMIUM_RULES.md`): the purchase sits on RevenueCat's anonymous id, and
  `PurchaseIdentity` moves it onto the account at the first sign-in — binding
  only when `isSignedIn`, because an anonymous uid has nothing durable to carry
  it. **Premium is required for alerts**, though. Registration refuses a
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

## Local storage: the Keychain, and a reinstall starts clean

**Every local key-value the app keeps goes through `SecureStore`
(`core/storage/`), which is `flutter_secure_storage`** (owner's rule). Locale,
onboarding state, the alert threshold, the health toggles, sync cursors, the
review counters: all of it is health-adjacent, and none of it belongs in a plist
any file-level backup reads. Reads are synchronous off one snapshot taken at
startup, because controllers read them inside `build`; writes go to the Keychain
first and update the snapshot after.

| Where | What | Why there |
|---|---|---|
| Keychain (`SecureStore`) | Every setting and cursor | Encrypted at rest, `first_unlock_this_device` so it is readable in the background and never restored onto a second device |
| `shared_preferences` | `PrefsKeyConstant.lastEnv`, and nothing else | iOS deletes it with the app, so the value names the environment AND its absence says this install is new |
| Drift | The records themselves | The source of truth, and far too big for a Keychain item |

**Deleting the app and installing it again must look like a first install**
(owner's rule), **and so must a build that talks to another environment.** iOS
keeps the Keychain across a delete, so the Firebase session came back and the
user was still signed in on what they thought was a clean install; dev and prod
share one bundle id, so installing either over the other leaves the new binary
reading the old one's session and cached documents. `SdFreshInstall.run` answers
both — it lives in `system_design` (`core/common/`), over three things this app
supplies: `PrefsInstallStore` (`SdInstallScopedStore`, deleted with the app),
`SecureDeviceStore` (`SdDeviceScopedStore`, survives it) and `AppFreshInstall`
(`SdFreshInstallHost` — the sign-out and the Firestore cache clear).

**One stamp, one comparison.** The stamp is the flavour name in
`shared_preferences`, and what it says decides the launch:

| On the device | What it is | What runs |
|---|---|---|
| Stamp equals this build | Normal launch | Nothing |
| Stamp is another flavour | Environment changed | Wipe |
| No stamp, other prefs keys | Update from a build that predates it | Keys carried into the Keychain, session kept |
| No stamp, Keychain not empty | Reinstall | Wipe |
| No stamp, nothing anywhere | First install | Nothing |

- **The update row is checked before the reinstall row.** An update leaves both
  stores full and only the install-scoped keys tell them apart. **An update
  keeps its settings and its session** (owner's rule): nothing was deleted, so
  there is nothing to make fresh — and wiping there would sign out every
  existing user on the update that ships this.
- **The wipe is sign out → clear the Firestore cache → clear the Keychain →
  clear `shared_preferences`.** Each step is guarded on its own; only the
  Keychain clear halts the rest, because on a reinstall it is the only thing
  there is to remove.
- **It runs behind `FreshInstallGate`, above the whole app.**
  `clearPersistence` throws `failed-precondition` once anything has opened a
  Firestore stream, and `_BaroEaseAppView`'s first frame opens several — so the
  gate holds that widget back and shows the splash dots meanwhile.
- **The stamp is written last**, after the wipe cleared the store it lives in,
  so a wipe that halted is repeated on the next launch rather than recorded as
  done.
- **It never throws**: before the first frame an uncaught throw is not an error
  screen but an app that does not start. Every branch logs what it decided
  under `LogTagConstant.freshInstall`.
- **The `baroease` database is never wiped.** `DECISIONS.md` has the reason.
- **RevenueCat needs nothing here** — its anonymous id lives in
  `NSUserDefaults`, which iOS already deletes with the app. A premium user who
  reinstalls signed-in gets the entitlement back automatically; one who bought
  anonymously has to tap Restore. See the README's premium identity table.

## 2. Location: While-Using and reduced accuracy only

Never request Always.

- **Two surfaces raise the prompt and no others**: the onboarding step and the
  dashboard weather card (`_LocationPrompt`, owner's call). Reading a position
  never prompts — `LocationSource` splits `currentPosition` from
  `requestPermission` for that reason, and `locationPermissionProvider` reads
  the status without asking. The card asks because a denial in onboarding used
  to be final: nothing asked again, and the card said only that weather was
  unavailable, which reads as broken rather than declined. It goes through
  `AppPermission.ensure`, so a denial iOS will no longer prompt for falls
  through to `PermissionSettingsSheet` instead of a dead button.
- **An explainer in front of the prompt may not steer the answer** (App Store
  5.1.1(iv), which submission 1.0(20) was rejected under). Two rules, both
  learned the hard way:
  - **Its button is worded neutrally — "Continue", never "Enable location".**
    A button that names the grant makes the custom screen read as the consent,
    which is the OS dialog's job.
  - **It offers no way past the prompt.** Onboarding's location page used to
    carry a "Not now" beside the ask; it is one button now, and the OS dialog
    always follows it. Declining stays entirely possible — in iOS's own dialog,
    which is where the decision belongs.
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

## 8. GDPR: one destructive action

**"Delete all data" is gone from Settings for users** (owner's call,
2026-09-05). The row, its confirm dialog, its progress indicator and the
`AppFeature.wipe` marketing line are deleted; `DataWipeService` stays, because
account deletion and the three dev tiles still call it. **Do not put the row
back for users without the owner asking** — it is back in the Dev group only
(owner's call, 2026-09-06), behind `showDevSettingsProvider`, which no
production user reaches unless the owner puts their address on
`dev_mode_emails`. Note what went with the user-facing row: a signed-out user has no in-app way to clear the backend
alert record beyond giving up the token (`unregister`), so the privacy policy
answers that by email instead. Moving `unregister` to `forgetRegistration` would
close it in code, and is the owner's call to make.

**"Delete account"** (Account screen) is now the only teardown: `wipeAll` for the
device and the account copy, Firestore doc, synced records, FCM token revoke,
then Firebase Auth. App Store 5.1.1(v) requires it in-app now that accounts
exist.

- **Its server half is the `deleteAccount` callable of necessity.**
  `firestore.rules` denies a client deleting `users/{uid}` (its write rule reads
  `request.resource.data`, absent on a delete) and denies `sync_keys/{uid}` to
  everyone.
- **The auth user goes last.** Delete it first and every remaining step is
  unauthorised, leaving records nobody can reach.
- **Deleting one account never reaches into another** (owner's rule). Deleting
  the Google account deletes Google; deleting the Apple account deletes Apple.
  The Apple revoke is where this went wrong: `revokeAppleTokenIfLinked` has to
  re-open the Apple sheet for a fresh authorization code, and that sheet answers
  for whichever Apple ID is signed in **on the device** — not for the one linked
  to the account being deleted. Handing that code to
  `revokeTokenWithAuthorizationCode` took the app authorization away from a
  bystander's Apple ID.
  - `FirebaseAuthRepository.isSameAppleIdentity` compares the sheet's
    `userIdentifier` against the `apple.com` entry in `providerData` — both are
    Apple's `sub`, so they match when it is the same person. **No match, no
    revoke**: the account still goes, it just stops speaking for an identity
    that never asked it to. A missing identifier on either side is a no, not a
    maybe.
  - A Google-only account never reaches the sheet at all — the provider guard
    above it returns first.
- The dialog says the subscription is **not** cancelled — a user who assumes
  otherwise keeps being charged.
- **Exports are health data on disk.** Each export is written to the app's
  documents directory and recorded so it can be re-shared later, so the wipe
  must delete the files and their rows too, or deleting the account leaves
  copies in `Documents/exports/`. Anything new that persists health data
  inherits this.
- **The in-app export is Premium in full** (owner's call, 2026-08-19) — JSON and
  CSV as well as the PDF. Portability is met by the support route the privacy
  policy names, which answers an export request by email at no cost — move both
  together if that route changes. Account deletion is free and always will be.
- **`DataWipeService` has four callers, all of them still real**: account
  deletion (`AccountController.deleteAccount`), the dev delete-all, the dev
  reset and the dev seed.
  Its progress callback lost its only display when the Settings row went —
  `SettingsRowProgress`, `WipeStatus` and `commonProgressPercent` are deleted
  with it — but `onProgress` stays, because the step count is what
  `data_wipe_service_test.dart` asserts against.
  - **`DataWipeService.steps` counts awaits, never records.** A step added to
    `wipeAll` moves that constant in the same change; the test asserts 0..steps
    with nothing skipped.
  - **The Apple Health disconnect is the controller's, not the service's.**
    Nothing from HealthKit is stored, so there is nothing to delete — but
    leaving it connected keeps the app reading sleep after the wipe.

## 11. Medical disclaimer

Must appear in onboarding and the App Store description. Never generate copy
promising diagnosis, treatment or prevention.

## 13. Never read `env/` — or `env_assets/`

Not with Read, not with `cat`/`grep`/`sed`, not "just one field".
`env/dev.json` and `env/prod.json` hold live Firebase and RevenueCat keys, and
anything read there is copied into a transcript that outlives the session.
**There is no read small enough to be safe: the harm is the copy, not the
size.**

- **Use instead**: `env/*.example.json` are committed key-only templates — they
  answer "what keys exist" with no values. The Firebase project id is in
  `.firebaserc`, and `firebase use` prints it. Anything else, ask the owner.
- Reading the *names* of files in `env/` is fine. Writing is fine too —
  `make set-up` and `packages/script-tools/flutter/prepare_env.sh dev|prod` create them, and they
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
- **`env_assets/` is the same folder one step upstream, and it is covered by
  every word above.** It holds `dev.json`, `prod.json`, both
  `GoogleService-Info.plist`s, both `google-services.json`s, the two
  `function.env` files and `fastlane.env` — the originals that
  `prepare-env` copies *into* `env/`. It is gitignored for that reason.
- **Do not WRITE there either, whatever the reason.** The bullet above says
  writing is fine; it means `set-up` and `prepare-env` writing, and nothing
  else. This was tested the hard way on 2026-09-17: the iOS Flutter GPU key was
  missing, the owner had been asked to add it, and a session added it with
  `plutil -insert` instead — reasoning that inserting a boolean reads nothing
  out. `plutil` rewrites the whole file, and both `*-Info.plist`s lost every
  XML comment they carried, with no git copy to restore from. The values
  survived; the documentation did not.
  - The lesson is not "use a gentler tool". It is that a file this session may
    not read is a file it may not edit, because an edit it cannot verify is an
    edit it cannot undo. **Anything needed in `env_assets/` is handed to the
    owner as the exact lines to paste.**
- **`ios/Runner/Info.plist` is off limits too** (owner's rule, 2026-10-05):
  no edit, `git add`, commit or `git restore`. It is tracked, but
  `make env-<flavor>` writes the flavor's Google reversed client id into its
  URL scheme, so the working copy always differs from the committed `...`
  placeholder.

  | Action | Result |
  |---|---|
  | commit it | the flavor's client id lands in the branch, right for one flavor only |
  | restore it | sign-in builds, then drops its callback at runtime |
  | edit it | the next `make env-<flavor>` overwrites the edit |

  A key it needs is handed to the owner as lines to paste, as for `env_assets/`.
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
  the file. `url` (`https://damhongduc.github.io/personal_work_space`) is the
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
  device, cleared by the wipe), and what a signed-out user can and cannot have
  deleted without an account.
- **A new data flow means editing both files before the feature is done.**
  Nothing enforces this, which is why it is written here.
- `[ADDRESS/COUNTRY]` in the markdown is the owner's to fill. The support
  address (`AppEnv.supportEmail`, default `support@baroease.app`) is a different
  thing from the privacy contact (`ducdam.dev@gmail.com`); don't collapse them.
