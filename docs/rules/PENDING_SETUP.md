# Pending setup — the owner does this by hand

None of this is in the repo, and none of it can be assumed to exist.

## The `app_config/current` document

**Nothing is configured until the owner creates it.** One document holds every
switch, and its absence is the normal state — premium stays on, nobody is
blocked, nobody is force-updated, and the cron fetches no extra accounts. Shape
and reasoning: `lib/features/app_config/CLAUDE.md`.

1. **`firestore.rules` must be deployed** for the app to read it at all. Until
   `firebase deploy --only firestore:rules` runs, every read is
   `permission-denied`, which the app logs and treats as "nothing configured".
2. **Create one document, id `app`, in `app_config`.** Every field is optional:

   | Field | Type | Notes |
   |---|---|---|
   | `premium_enabled` | boolean | Only an actual `false` turns premium off, app-wide, for bought and listed accounts alike. Absent means on. |
   | `force_update` | map | An `ios` and/or `android` section, each `store_link` / `build_name` / `build_number` / `enable_force_update`. |
   | `premium_emails` | array of strings | Premium in the app and alert targets. |
   | `dev_mode_emails` | array of strings | The Dev group in Settings on a prod build. |
   | `blocked_emails` | array of strings | The lock-out screen; signing out clears it. |

3. **The document is world-readable, so the three lists are public.** The
   force-update check runs before sign-in and rules cannot hide a field. Do not
   put anything on it that is worse to publish than an address already is.
4. **Addresses are matched trimmed and lower-cased on both sides**, so
   `Review@BaroEase.app` in the console still matches. They must be addresses
   Google or Apple sign-in actually produces — an anonymous session carries none
   and is on no list. For the cron, the account also has to have signed in at
   least once: it resolves the address through Firebase Auth, and logs
   `allow-listed address has no account` when it cannot.
5. **Force update blocks nobody until `enable_force_update` is `true` AND the
   installed build is older**, so flip it only once that build is actually live
   on both stores.
6. **No caching, deliberately.** Every entry into the app — cold start and each
   resume — is one read of this document. That is what makes an emergency
   un-block take effect immediately rather than after a reinstall.
7. **`PREMIUM_EMAIL` may still be sitting in `functions/.env` and in
   `env_assets/<flavor>-function.env`.** Nothing reads it any more; remove it
   the next time those files are touched.

### The document, as JSON

```json
{
  "premium_enabled": true,
  "force_update": {
    "ios": {
      "store_link": "https://apps.apple.com/app/id0000000000",
      "build_name": "1.4.0",
      "build_number": 41,
      "enable_force_update": false
    },
    "android": {
      "store_link": "https://play.google.com/store/apps/details?id=app.dd.migraine.tracker",
      "build_name": "1.4.0",
      "build_number": 41,
      "enable_force_update": false
    }
  },
  "premium_emails": ["review@baroease.app", "owner@baroease.app"],
  "dev_mode_emails": ["owner@baroease.app"],
  "blocked_emails": ["banned@example.com"]
}
```

Also checked in at `sample_json/firebase/app_config.json`.

## HealthKit — code and Xcode project done, portal side not

`ios/Runner/Runner.entitlements` (wired into all three Runner build configs), the
`com.apple.HealthKit` capability and both usage strings all exist.

**Both strings are mandatory even though the app only reads.**
`NSHealthUpdateUsageDescription` looks unnecessary — the plugin calls
`requestAuthorization(toShare: nil, …)` — but App Store Connect's validator keys
off the **entitlement**, not actual API usage: with
`com.apple.developer.healthkit` present it rejects the upload with `ITMS-90683 —
Missing purpose string in Info.plist`, and the build never reaches TestFlight. Do
not "clean up" that string.

1. **HealthKit on the App ID.** The App ID behind `PRODUCT_BUNDLE_IDENTIFIER`
   needs the capability enabled in the Apple Developer portal (automatic signing
   offers to do it on the first device build). Until then signing fails with
   "Provisioning profile doesn't include the com.apple.developer.healthkit
   entitlement".
2. **A real device.** HealthKit does not exist in the Simulator: the sheet never
   appears and reads come back empty, indistinguishable from a refusal. Never
   read "no sleep card" there as a bug.
3. **App Store privacy.** HealthKit apps need a privacy policy URL, and the App
   Privacy label must declare Health & Fitness as collected-but-not-linked (it
   never leaves the device). App Review also rejects apps whose usage string does
   not say what is read and why; the shipped one names sleep specifically.

**`aps-environment` in that file is `development`, deliberately.** One file
serves all three build configs, and the app-store export re-signs it to
`production` from the distribution profile; hardcoding `production` would break
push on every debug build. Push still cannot reach a device until an APNs auth
key is in Firebase and Push Notifications is enabled on the App ID — and
`getToken()` returns null on the Simulator (no APNs), which
`FirebaseAlertRegistrationRepository` maps to
`AlertRegistrationError.pushUnavailable`. Expected there, never a bug.

## Sign in with Apple — the app ships it, the portal and Firebase do not

`appleSignInImplementedProvider` is `true`, the entitlement is in
`Runner.entitlements`, and the whole Dart path (nonce, `linkWithCredential`, the
repository) is done and tested. Submission 1.0(11) was rejected under **App Store
4.8** for the state before that: offering Google obliges us to offer Apple, and a
button answering "coming soon" does not count.

**The order matters** — an entitlement the App ID does not carry breaks device
signing with an error naming the entitlement, not the missing portal step.

1. **The capability on the App ID.** Portal → Identifiers → the App ID behind
   `PRODUCT_BUNDLE_IDENTIFIER` → enable **Sign in with Apple**. Then a **Services
   ID**, a **Key ID** and its `.p8` — downloadable once, and a different key from
   the APNs and WeatherKit ones.
2. **The Apple provider in Firebase.** Console → Authentication → Sign-in method
   → **Apple**, filled with the Services ID, Team ID, Key ID and `.p8`. Until it
   exists the flow comes back `AuthError.notConfigured`, which looks like an app
   bug.
3. **Re-run `fastlane certificates force:true`** from the Mac so the profiles are
   re-created carrying the new capability:

   ```sh
   cd ios && bundle exec fastlane certificates force:true
   ```

   **`force:true` is the whole step.** Existing profiles do not gain a
   capability, and match without it installs the one already in the certificates
   repo — so step 1 appears to have done nothing. CI's match is `readonly: true`
   and can only install what this command pushed. `force` regenerates profiles
   only; the certificate is untouched, so Apple's limit of three is not in play.

   The release lane checks this before it builds: every key in
   `Runner.entitlements` and `BaroEaseWidget.entitlements` must appear in the
   matching installed profile, or it stops with the missing key named. Rehearse
   without a build: `cd ios && CI=true bundle exec fastlane preflight`.

If any of it slips, flip `appleSignInImplementedProvider` back to `false` rather
than shipping the failure — but that build cannot be submitted, which is the
point of the switch.

## App icon and launch screen — DONE

Submission 1.0(11) was rejected under **App Store 2.3.8** for shipping the
default Flutter logo. Closed: the owner supplied the artwork and
`flutter_launcher_icons` generates the set from
`assets/images/final_app_icon.png`, configured in the
`flutter_launcher_icons:` block at the bottom of `pubspec.yaml` — which is also
where the two traps are written down (the alpha channel, and the tool corrupting
the pbxproj on every run). Regenerate with `dart run flutter_launcher_icons`.

The white launch screen went with it on both platforms (`fix: branding - the
launch screen stops flashing white`). It was never a *launch image*: iOS ships
1×1 transparent placeholders, so the storyboard's `backgroundColor` was the only
thing ever on screen.

Two open decisions, neither blocking:

- **The icon is an AI-generated raster.** Visible mottled texture and soft edges
  at 1024, which App Store product pages show large. Rebuilding the design as
  vector would give flat exact colours from one source. Cosmetic, owner's call.
- **Android is on legacy mipmaps, not adaptive icons.** Adaptive reserves the
  outer 18 of 108dp for the launcher's mask, which crops the teal scale off this
  full-bleed design. Doing it properly needs a separately padded foreground —
  Android polish, not a blocker while the app ships iOS first.

## App Privacy labels — they claim tracking the app does not do

Submission 1.0(11) was rejected under **5.1.2(i)** for having no App Tracking
Transparency prompt while the labels declare Crash Data, Health and Fitness as
*Used to Track You*. **The labels are wrong, not the app**: `pubspec.yaml`
carries `firebase_analytics`, `firebase_crashlytics` and `firebase_messaging` and
nothing else — no ad network, no attribution SDK, no IDFA read, no
`AppTrackingTransparency` anywhere, nothing shared with a data broker.

Owner, in App Store Connect (Account Holder or Admin): App Privacy → untick
**Used to Track You** on those three, leaving them **collected**. Do not add ATT
to satisfy the label — a prompt asking permission to do something the app does
not do is its own rejection.

## WeatherKit — decided, nothing on the Apple side exists

Weather moves to WeatherKit, called only from Cloud Functions. Blocked on:

1. **A key with WeatherKit enabled** — Certificates, Identifiers & Profiles →
   Keys. Gives the `.p8` and a Key ID, downloadable once, and a different key
   from the APNs one.
2. **A Services ID** — Identifiers → Services IDs. This is the JWT's subject; the
   app's Bundle ID is not it.
3. **The `.p8` in Secret Manager**, never in the repo and never in `env/` (hard
   rule 13 covers why a build-time define is not a secret store).

Until all three land the backend has nothing to sign with and every weather read
fails — which the app already treats as "no weather", never as an error (hard
rule 4).

## Home screen widget — the target is checked in, the App ID is not

`ios/BaroEaseWidget/`, the `BaroEaseWidgetExtension` target, both entitlements
files and the whole Dart side are done, and the extension builds and embeds.

1. **The App Group on the App ID.** `group.app.dd.migraine.tracker` must be
   registered and enabled on the App ID behind `PRODUCT_BUNDLE_IDENTIFIER` **and
   on `….BaroEaseWidgetExtension`** — an app extension has its own App ID.
   Automatic signing offers to create both on the first device build. Until then
   a device build fails to sign the extension and the shared `UserDefaults`
   silently returns nothing. **The Simulator does not need any of this** — App
   Groups work there unprovisioned, which is why "it works on the Simulator" says
   nothing about the device.
2. **A widget placed on a home screen.** Nothing draws until the user adds it; an
   empty gallery entry after a fresh install is normal.

## TestFlight from CI — the workflow is checked in, none of the credentials are

`.github/workflows/release-ios.yml`, `ios/fastlane/*` and `ios/Gemfile` are in
the repo. How the pieces fit is in `COMMANDS.md`; **how each credential is
created, where it lives and every failure mode paid for so far is in
`docs/release/CREDENTIALS.md`, which is the authority.** This list is only the
register of what is outstanding.

**Do the HealthKit, App Group and Sign in with Apple items first.** A provisioning
profile carries whatever capabilities the App ID had when it was created, so
match can succeed and the build still fail to sign.

1. **An App Store Connect API key**, App Manager role. Downloadable once, and a
   different key from the APNs and WeatherKit ones.
2. **A private git repo for `match`** — e.g. `DAMHONGDUC/certificates`. It holds
   a real distribution certificate's private key, encrypted with the match
   passphrase. Private, and not this repo.
3. **A fine-grained PAT** scoped to that repo alone, Contents: Read-only.
4. **`fastlane certificates`, run once from the Mac** (`cd ios && bundle exec
   fastlane certificates`). It mints the distribution certificate and the two App
   Store profiles — app and widget extension — and pushes them to that repo. CI
   is `readonly: true` and can only install what already exists.
5. **`ios/fastlane/.env`** on the developer's Mac — six keys, gitignored.
6. **Repository secrets** (Settings → Secrets and variables → Actions):
   `ENV_PROD_JSON`, `ENV_DEV_JSON`, `GOOGLE_SERVICE_INFO_PLIST_PROD`,
   `GOOGLE_SERVICE_INFO_PLIST_DEV`, `ASC_KEY_ID`, `ASC_ISSUER_ID`,
   `ASC_KEY_CONTENT`, `MATCH_PASSWORD`, `MATCH_GIT_URL`, and **one of**
   `MATCH_GIT_BASIC_AUTHORIZATION` / `MATCH_GIT_BEARER_AUTHORIZATION`.
   The two plist secrets are base64 of each project's
   `ios/Runner/GoogleService-Info.plist` — gitignored, and a build input of the
   Runner target, so without one the archive fails rather than the app
   misbehaving. One per flavor because dev and prod are two Firebase projects,
   and the lane refuses a build whose plist is not the flavor's own.
   `FIREBASE_APP_ID_IOS` is optional (unset skips the Crashlytics symbol upload
   with a warning) but is checked against the plist when set; it is an env var
   rather than a plist read because that file is absent from a CI checkout.
7. **Fastlane on the Mac**, for step 4 and for a local run: `brew install
   fastlane`, or rbenv plus `cd ios && bundle install`. The system Ruby is 2.6
   and deprecated — gems there need sudo and are not worth the trouble.

`ios/Gemfile.lock` is deliberately not committed yet: it can only be generated
from a Ruby 3.x install. Commit it after the first local `bundle install`, then
turn on `bundler-cache: true` in the workflow to stop resolving gems every
release.

## RevenueCat — code is wired, the dashboard and store are not

`purchases_flutter` is in, `RevenueCatPremiumRepository` reads the entitlement,
`RevenueCatPurchaseRepository` sells and restores, and the paywall renders
whatever the offering returns. **There is no local premium repository any more** —
the old `DebugPremiumRepository` (a prefs flag with a `setPremium`) is deleted,
because a premium state the client can write is the one thing this project must
not ship. Tests override `premiumRepositoryProvider` with a fake; nothing else
may.

**One assert covers missing config.** `AppEnv.missingConfigKeys` walks every
required Firebase field plus the platform's RevenueCat key and returns the names
still empty; `main()` asserts that list is empty, reporting every gap in one
message instead of failing on the first field checked. It replaced the separate
`assert(AppEnv.hasFirebaseConfig, …)` and `assert(AppEnv.hasPurchasesConfig, …)`.

**The assert was never capable of causing the TestFlight crash — that suspicion
is closed.** Dart strips `assert()` from release builds, and TestFlight is
release. Note the shape of the trap: the one check meant to catch missing config
is compiled out in precisely the build where the mistake happens.

**The crash was RevenueCat, and it was a bad API key — `test_...` left in
`REVENUECAT_KEY_IOS`.** RevenueCat's native SDK answers a key carrying another
platform's prefix with `fatalError`, which kills the process. **No Dart `catch`
can survive that**, so the guards around `ensureConfigured` never applied — they
only ever caught Dart throws — and Swift keeps `fatalError` in release, so it
lands on TestFlight and nowhere else. `RevenueCatClient.isUsableKey` now rejects
such a key before `Purchases.configure`, turning an uncatchable crash back into
the already-handled `StateError` path. **An empty key is therefore safer than a
placeholder.** Keys with no prefix are let through — those are RevenueCat's
legacy keys, and it merely warns.

**Separately, never archive from Xcode.** Product > Archive knows nothing about
`--dart-define-from-file`, so the archive carries empty config;
`Firebase.initializeApp` throws, `main()` swallows it, and the app dies on the
first `FirebaseAuth.instance` with `[core/no-app] No Firebase App '[DEFAULT]' has
been created`. Always build with `sh packages/system_design/tool/build-ipa.sh prod` (or `build-ipa-dev`),
or let the Release iOS workflow do it — the fastlane lane calls the same script.

The paywall still surfaces `PurchaseError.notConfigured` when a purchase runs
without a key, because every call site catches the `RevenueCatClient.apiKey`
`StateError`. What the owner must do by hand:

1. **Keys in `env/dev.json` / `env/prod.json`** (gitignored, placeholders already
   added): `REVENUECAT_KEY_IOS`, `REVENUECAT_KEY_ANDROID`, and optionally
   `REVENUECAT_ENTITLEMENT` (defaults to `premium`) and `REVENUECAT_OFFERING`
   (empty = whatever the dashboard marks current).
2. **Products in App Store Connect** — monthly $4.99 and yearly $29.99 — plus
   the Paid Apps Agreement, then the same two attached to a RevenueCat
   offering. Until an offering exists the paywall correctly shows "no
   plans available"; that is not a bug. **Submission 1.0(11) was rejected under
   App Store 2.1(b) for exactly that screen**, so the checklist, in order:
   - the Paid Apps Agreement signed and *active*;
   - both IAPs in **Ready to Submit** and attached to the build at
     submission;
   - in RevenueCat, both products in **one offering marked Current**, under
     entitlement id `premium`;
   - `REVENUECAT_KEY_IOS` a real `appl_...` key (a `test_...` one is the fatal
     crash above, not an empty paywall);
   - bought once in **sandbox on a real device** before resubmitting.

   A reviewer sees "no plans available" as a non-functional app, and no amount of
   correct client code answers it.
3. **Prices are never formatted in Dart.** `PremiumOffer.priceLabel` is the
   store's own string: currency, position and decimal separator belong to the
   customer's storefront.

Only `PackageType.monthly` / `annual` are rendered; anything else the dashboard
adds — a leftover `lifetime` included — is skipped rather than drawn blind.
Purchases are bound to the Firebase UID via `PurchaseIdentity`, so an
entitlement follows the person, not the install.

## The attack Live Activity

Written, wired and committed, but **never built or run** — this machine has no
iOS build in the loop, so everything below is unverified.

| Check | Why it matters |
|---|---|
| It compiles | `BaroEaseAttackActivity.swift` was added to the extension target by hand-editing `project.pbxproj` (file ref `7B41…0009`, build file `7B41…0017`), following the numbering already there. Open the target in Xcode once and confirm the file is a member. |
| The bundle takes two widgets | `if #available(iOS 16.1, *)` inside `@WidgetBundleBuilder` — see `DECISIONS.md` for why this one is expected to work where an earlier one did not. |
| The card appears | Log an attack on a real iOS 16.1+ device. A wrong `ActivityAttributes` name creates the activity and shows nothing, which looks identical to a failure to start. |
| It ends | Record the attack as ended, then delete one, then run the GDPR wipe. All three must clear the card. |
| The App Group matches | `HomeWidgetConstant.appGroupId`, `BaroEaseWidgetStore.appGroupId` and both `.entitlements` files. The plugin reads its values from that suite. |
| `permission_handler` | Arrived as a transitive dependency of `live_activities` and asks for the Android notification permission at init. Harmless on iOS; check it does not add an unexpected Android prompt if Android is ever polished. |

## The display name in `env_assets/`

`ios/Runner/Info.plist` now says `BaroEase` where it used to say "Migraine
Tracker" — the name iOS puts in every permission dialog and on the home screen.
That file is one of the six `prepare-env` overwrites, so **the copy in
`env_assets/` has to carry the same string** or the next
`melos run prepare-env-<flavor>` puts the old name back. The repo copy is the
one CI builds from; the `env_assets/` copy is the one a local release build
does.
