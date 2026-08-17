# Pending setup — the owner does this by hand

None of this is in the repo, and none of it can be assumed to exist.

Force update (`app_update`) is coded and tested, but nothing on the Firebase
side is done yet. Until all three land, the launch check reads nothing and
fails open — which is the safe state, and also a silent one, so don't read
"no sheet appeared" as "it works".

1. **`firestore.rules` is not deployed.** The `app_updates` block exists in
   the repo only. Until `firebase deploy --only firestore:rules` runs, the
   client read returns `permission-denied` and the check silently fails open.
2. **The `app_updates` collection does not exist.** Records are published by
   hand from the Firebase console — schema and field types are documented on
   `AppUpdateMapper`. `create_date` MUST be a Firestore `timestamp`: Firestore
   orders mixed types by type, so one record saved as a string sorts below
   every timestamp and `orderBy(create_date, desc).limit(1)` will never see
   it. Publish a NEW document per release; never edit the previous one.
   Flip `enable_force_update` to true only once that build is live on both
   stores.
3. **No caching — deliberately.** Every entry into the app (cold start and
   each resume) is one Firestore document read. That is what makes an
   emergency un-block take effect on the next app open, unlike Remote
   Config's 12h cache. If the read volume ever matters, cache the record in
   memory and refetch after N minutes — decide the N against how fast an
   un-block has to reach users, and never cache the "blocked" verdict longer
   than the "not blocked" one.

Also note `env/dev.json` and `env/prod.json` point at the SAME Firebase
project, so a blocking record written while testing hits real users too.
Fix that with a separate dev project, or wire the Firestore emulator behind
`!AppEnv.isProd` before testing a blocking record post-launch.

### HealthKit — code and Xcode project are done, the portal side is not

`ios/Runner/Runner.entitlements` (checked in, wired into all three Runner
build configs), the `com.apple.HealthKit` target capability and BOTH health
usage strings all exist. What is NOT in the repo, because it cannot be:

**Both strings are mandatory even though the app only reads.**
`NSHealthUpdateUsageDescription` looks unnecessary — the plugin calls
`requestAuthorization(toShare: nil, …)`, so nothing is ever written and iOS
never shows that string. But App Store Connect's validator keys off the
**entitlement**, not off actual API usage: with `com.apple.developer.healthkit`
present it rejects the upload with `ITMS-90683 — Missing purpose string in
Info.plist … should contain a NSHealthUpdateUsageDescription key`, and the
build never reaches TestFlight. Do not "clean up" that string as dead config.

1. **HealthKit on the App ID.** The App ID behind
   `PRODUCT_BUNDLE_IDENTIFIER` needs the HealthKit capability enabled in the
   Apple Developer portal (Xcode's
   automatic signing will offer to do it on the first device build with the
   enrolled team selected). Until it is, signing fails with "Provisioning
   profile doesn't include the com.apple.developer.healthkit entitlement".
2. **A real device.** HealthKit does not exist in the iOS Simulator: the
   authorization sheet never appears and reads come back empty, which is
   indistinguishable from a refusal. Never read "no sleep card" on the
   Simulator as a bug.
3. **App Store privacy.** HealthKit apps need a privacy policy URL and the
   App Privacy label must declare Health & Fitness data as collected-but-
   not-linked (it never leaves the device — sleep is read for the analysis
   and nothing is stored or uploaded). App Review also rejects HealthKit
   apps whose usage string doesn't say what is read and why; the shipped one
   names sleep specifically.

The entitlements file now declares `aps-environment` alongside HealthKit, and
its value is **`development`, deliberately**: one file serves all three build
configs, and the app-store export re-signs it to `production` from the
distribution profile. Hardcoding `production` there would break push on every
debug build instead. Push still cannot reach a device until the console side
is done — an APNs auth key in Firebase, and Push Notifications enabled on the
App ID — and `getToken()` returns null on the Simulator (no APNs), which
`FirebaseAlertRegistrationRepository` maps to
`AlertRegistrationError.pushUnavailable`. That refusal is expected on the
Simulator; never read it as a bug.

### Sign in with Apple — the app ships it, the portal and Firebase do not have it

`appleSignInImplementedProvider` is `true`, the entitlement is in
`ios/Runner/Runner.entitlements`, and the whole Dart path (nonce,
`linkWithCredential`, the repository) is done and tested. Submission 1.0(11)
was rejected under **App Store 4.8** for the state before that: offering
Google obliges us to offer Apple, and a button answering "coming soon" does
not count as offering it. The console side does not exist yet, and **the
order below matters** — an entitlement the App ID does not carry breaks
device signing with "Provisioning profile doesn't include the
com.apple.developer.applesignin entitlement", which names the entitlement,
not the missing portal step.

1. **The capability on the App ID.** Apple Developer portal → Identifiers →
   the App ID behind `PRODUCT_BUNDLE_IDENTIFIER` → enable **Sign in with
   Apple**. Then a **Services ID**, a **Key ID** and its `.p8` — downloadable
   once, like the APNs and WeatherKit keys, and a different key from all of
   them.
2. **The Apple provider in Firebase.** Console → Authentication → Sign-in
   method → **Apple**, filled with the Services ID, Team ID, Key ID and `.p8`.
   Until this exists the flow reaches Firebase and comes back
   `AuthError.notConfigured`, which looks like a bug in the app.
3. **Re-run `fastlane certificates`** from the Mac, so the profiles are
   re-created carrying the new capability. Existing profiles do not gain it.

If any of it slips, flip `appleSignInImplementedProvider` back to `false`
rather than shipping the failure — but that build cannot be submitted, which
is the whole point of the switch.

### App icon and launch screen — DONE, nothing outstanding

Submission 1.0(11) was rejected under **App Store 2.3.8** for shipping the
default Flutter logo at every size. Closed: the owner supplied the artwork at
`assets/images/app_icon.png`, and `flutter_launcher_icons` generates the whole
set from it — configured in the `flutter_launcher_icons:` block at the bottom
of `pubspec.yaml`, which is also where the two traps are written down (the
alpha channel, and the tool corrupting the pbxproj on every run). Regenerate
with `dart run flutter_launcher_icons`.

The white launch screen went with it, on both platforms — see the
`fix: branding - the launch screen stops flashing white` commit. It was never
a *launch image*: iOS ships 1×1 transparent placeholders, so the storyboard's
own `backgroundColor` was the only thing ever on screen.

**What is still worth a decision, though nothing blocks submission:** the icon
is an AI-generated raster. Its strokes carry visible mottled texture and soft
edges at 1024, and App Store product pages show that size large. Rebuilding
the same design as vector would give flat exact brand colours and crisp edges
from one source. Owner's call, and cosmetic either way.

**Android is on legacy mipmaps, not adaptive icons.** Adaptive reserves the
outer 18 of 108dp for the launcher's mask, which on this full-bleed design
crops the teal scale off the left edge. Doing it properly needs a separately
padded foreground asset — Android polish, not a blocker while the app ships
iOS first.

### App Privacy labels — they claim tracking the app does not do

Submission 1.0(11) was rejected under **5.1.2(i)** for having no App Tracking
Transparency prompt while the privacy labels declare Crash Data, Health and
Fitness as *Used to Track You*. **The labels are wrong, not the app** —
`pubspec.yaml` carries `firebase_analytics`, `firebase_crashlytics` and
`firebase_messaging` and nothing else; there is no ad network, no attribution
SDK, no IDFA read and no `AppTrackingTransparency` usage anywhere in the
repo. Nothing is shared with a data broker or joined to third-party data.

Owner, in App Store Connect (needs Account Holder or Admin): App Privacy →
untick **Used to Track You** on those three, leaving them **collected**. Do
not add ATT to satisfy the label — a prompt asking permission to do something
the app does not do is its own rejection.

### WeatherKit — decided, nothing on the Apple side exists yet

Weather moves to WeatherKit, called only from Cloud Functions (see the tech
stack note). None of the credentials exist, so this is blocked on:

1. **A key with WeatherKit enabled** — Certificates, Identifiers & Profiles →
   **Keys** → tick WeatherKit. Gives the `.p8` and a **Key ID**. Downloadable
   once, like the APNs key, and it is a different key from that one.
2. **A Services ID** — Identifiers → **Services IDs**. This is the JWT's
   subject; the app's Bundle ID is not it.
3. **The `.p8` in Secret Manager**, never in the repo and never in `env/`
   (hard rule 13 covers why a build-time define is not a secret store).

Until all three land the backend has nothing to sign with, and every weather
read fails — which the app already treats as "no weather", never as an error
(hard rule 4).

### Home screen widget — the target is checked in, the App ID is not

`ios/BaroEaseWidget/`, the `BaroEaseWidgetExtension` target, both entitlements
files and the whole Dart side are done, and the extension builds and embeds.
What is NOT in the repo:

1. **The App Group on the App ID.** `group.app.dd.migraine.tracker` must be
   registered under Certificates, Identifiers & Profiles and enabled on the
   App ID behind `PRODUCT_BUNDLE_IDENTIFIER`, and on
   `…​.BaroEaseWidgetExtension` too — an app extension has its own App ID.
   Xcode's automatic signing offers to create both on the first device build.
   Until then a device build fails to sign the extension, and the shared
   `UserDefaults` silently returns nothing. **The Simulator does not need any
   of this** — App Groups work there unprovisioned, which is why "it works on
   the Simulator" says nothing about the device.
2. **A widget placed on a home screen.** Nothing draws until the user adds it,
   and an empty gallery entry after a fresh install is normal, not a bug.

### TestFlight from CI — the workflow is checked in, none of the credentials are

`.github/workflows/release-ios.yml`, `ios/fastlane/*` and `ios/Gemfile` are in
the repo. How the pieces fit is in `docs/rules/COMMANDS.md`; the first Run
workflow fails until every item below exists.

**Do the HealthKit, App Group and Sign in with Apple items above first.** A provisioning profile
carries whatever capabilities the App ID has at the moment it is created, so
match can succeed and the build still fail to sign — the error names the
missing entitlement, not the missing portal step.

**How each credential is created, where it lives, and every failure mode paid
for so far is in `docs/release/CREDENTIALS.md`.** That file is the authority;
this list is only the register of what is still outstanding.

1. **An App Store Connect API key**, App Manager role. Downloadable once, like
   the APNs and WeatherKit keys, and a different key from both.
2. **A private git repo for `match`** — e.g. `DAMHONGDUC/certificates`. It
   holds a real distribution certificate's private key, encrypted with the
   match passphrase. Private, and not this repo.
3. **A fine-grained PAT** scoped to that repo alone, Contents: Read-only.
4. **`fastlane certificates`, run once from the Mac** (`cd ios && bundle exec
   fastlane certificates`). It mints the distribution certificate and the two
   App Store profiles — app and widget extension — and pushes them to that
   repo. CI is `readonly: true` and can only install what already exists.
5. **`ios/fastlane/.env`** on the developer's Mac — six keys, gitignored.
6. **Repository secrets** (Settings → Secrets and variables → Actions):
   `ENV_PROD_JSON`, `ENV_DEV_JSON`, `ASC_KEY_ID`, `ASC_ISSUER_ID`,
   `ASC_KEY_CONTENT`, `MATCH_PASSWORD`, `MATCH_GIT_URL`, and **one of**
   `MATCH_GIT_BASIC_AUTHORIZATION` / `MATCH_GIT_BEARER_AUTHORIZATION`.
   `FIREBASE_IOS_APP_ID` is optional — unset simply skips the Crashlytics
   symbol upload with a warning. It is an env var rather than
   `GoogleService-Info.plist` because that file is gitignored and absent from a
   CI checkout.
5. **Fastlane on the Mac**, for step 3 and for a local run: `brew install
   fastlane`, or rbenv plus `cd ios && bundle install`. The system Ruby is
   2.6 and deprecated — installing gems into it needs sudo and is not worth
   the trouble.

`ios/Gemfile.lock` is deliberately not committed yet: it can only be generated
from a Ruby 3.x install. Commit it after the first local `bundle install`, then
turn on `bundler-cache: true` in the workflow to stop resolving gems on every
release.

### RevenueCat — code is wired, the dashboard and store are not

`purchases_flutter` is in, `RevenueCatPremiumRepository` reads the
entitlement, `RevenueCatPurchaseRepository` sells and restores, and the
paywall renders whatever the offering returns. **There is no local premium
repository any more** — the old `DebugPremiumRepository` (a prefs flag with a
`setPremium`) is deleted, because a premium state the client can write is the
one thing this project must not ship. Tests override
`premiumRepositoryProvider` with a fake instead; nothing else may.

Missing config used to fail loud via `assert(AppEnv.hasFirebaseConfig, …)` and
`assert(AppEnv.hasPurchasesConfig, …)` in `main()`; both were removed (owner
call: a TestFlight build crashing on launch was suspected to trace back to
one of them; under investigation) and have now been **replaced with one
assert** — `AppEnv.missingConfigKeys` walks every required Firebase field
plus the platform's own RevenueCat key and returns the names still empty;
`main()` asserts that list is empty, reporting every gap in one message
instead of failing on the first field checked.

**The assert was never capable of causing that TestFlight crash — that
suspicion is closed.** Dart strips `assert()` from release builds, and
TestFlight is release, so it cannot fire there. Note the shape of that trap:
the one check meant to catch missing config is compiled out in precisely the
build where the mistake happens.

**The crash was RevenueCat, and it was a bad API key — `test_...` left in
`REVENUECAT_IOS_KEY`.** RevenueCat's native SDK answers a key carrying
another platform's prefix with `fatalError`, which kills the process.
**No Dart `catch` can survive that**, so the guards around `ensureConfigured`
never applied — they only ever caught Dart throws — and Swift keeps
`fatalError` in release, so it lands on TestFlight and nowhere else.
`RevenueCatClient.isUsableKey` now rejects such a key before it reaches
`Purchases.configure`, turning an uncatchable crash back into the
already-handled `StateError` path. An **empty** key is therefore safer than a
placeholder: empty has always been handled, a plausible-looking placeholder
is fatal. Keys with no prefix are let through — those are RevenueCat's legacy
keys and it merely warns.

**Separately, never archive from Xcode.** Product > Archive knows nothing
about `--dart-define-from-file`, so the archive carries empty config;
`Firebase.initializeApp` throws, `main()` swallows it, and the app dies on
the first `FirebaseAuth.instance` with `[core/no-app] No Firebase App
'[DEFAULT]' has been created`. **Always build with `melos run
build-ipa-prod`** (or `build-ipa-dev`), or let the Release iOS workflow do
it — the fastlane lane calls the same script for the same reason.

The paywall still surfaces `PurchaseError.notConfigured` when a purchase
action runs without a key, because every RevenueCat call site catches the
`RevenueCatClient.apiKey` `StateError` — that guard is unchanged. What the
owner must do by hand:

1. **Keys in `env/dev.json` / `env/prod.json`** (gitignored, placeholders
   already added): `REVENUECAT_IOS_KEY`, `REVENUECAT_ANDROID_KEY`, and
   optionally `REVENUECAT_ENTITLEMENT` (defaults to `premium`) and
   `REVENUECAT_OFFERING` (empty = whatever the dashboard marks current).
2. **Products in App Store Connect** — monthly $4.99, yearly $29.99,
   lifetime $44.99 — plus the Paid Apps Agreement, then the same three
   attached to a RevenueCat offering. Until an offering exists the paywall
   correctly shows "no plans available"; that is not a bug.
   **Submission 1.0(11) was rejected under App Store 2.1(b) for exactly that
   screen**, so the full checklist, in order: the Paid Apps Agreement signed
   and *active*; all three IAPs in **Ready to Submit** and attached to the
   build at submission; in RevenueCat, the three products in **one offering
   marked Current**, under entitlement id `premium`; `REVENUECAT_IOS_KEY` a
   real `appl_...` key (a `test_...` one is the fatal crash above, not an
   empty paywall); and the whole thing bought once in **sandbox on a real
   device** before resubmitting. A reviewer sees "no plans available" as a
   non-functional app, and no amount of correct client code answers it.
3. **Prices are never formatted in Dart.** `PremiumOffer.priceLabel` is the
   store's own string, because the currency, its position and the decimal
   separator belong to the customer's storefront.

Only `PackageType.monthly` / `annual` / `lifetime` are rendered; anything else
the dashboard adds is skipped rather than drawn blind. Purchases are bound to
the Firebase UID via `PurchaseIdentity` so an entitlement follows the person,
not the install.
