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

**Do the HealthKit and App Group items above first.** A provisioning profile
carries whatever capabilities the App ID has at the moment it is created, so
match can succeed and the build still fail to sign — the error names the
missing entitlement, not the missing portal step.

1. **An App Store Connect API key.** Users and Access → Integrations → App
   Store Connect API → a key with the **App Manager** role. Gives
   `AuthKey_XXXXXXXX.p8`, a Key ID and an Issuer ID. Downloadable once, like
   the APNs and WeatherKit keys, and a different key from both. It replaces an
   Apple ID login, which is the point: 2FA has no answer a runner can give.
2. **A private git repo for `match`** — e.g. `DAMHONGDUC/certificates`. It
   holds a real distribution certificate's private key, encrypted with the
   match passphrase. Private, and not this repo.
3. **`fastlane certificates`, run once from the Mac** (`cd ios && bundle exec
   fastlane certificates`). It mints the distribution certificate and the two
   App Store profiles — app and widget extension — and pushes them to that
   repo. CI is `readonly: true` and can only install what already exists.
4. **Repository secrets** (Settings → Secrets and variables → Actions):
   - `ENV_PROD_JSON` / `ENV_DEV_JSON` — the entire contents of `env/prod.json`
     and `env/dev.json`. The whole file, so adding a key later needs no
     workflow change.
   - `ASC_KEY_ID`, `ASC_ISSUER_ID` — from step 1.
   - `ASC_KEY_CONTENT` — the `.p8`, base64:
     `base64 -i AuthKey_XXXXXXXX.p8 | pbcopy`. Base64 because the file is
     multi-line, and a secret that loses its newlines fails as an unreadable
     key rather than as a missing one.
   - `MATCH_PASSWORD` — the passphrase chosen during step 3.
   - `MATCH_GIT_URL` — the repo from step 2. Optional; `Matchfile` has a
     default.
   - `MATCH_GIT_BASIC_AUTHORIZATION` — base64 of
     `<github-username>:<PAT with repo scope>`, so the runner can clone a
     private certs repo.
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
'[DEFAULT]' has been created`. **Always release with `melos run
release-ios`** (prod) or `melos run release-ios-dev`.

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
3. **Prices are never formatted in Dart.** `PremiumOffer.priceLabel` is the
   store's own string, because the currency, its position and the decimal
   separator belong to the customer's storefront.

Only `PackageType.monthly` / `annual` / `lifetime` are rendered; anything else
the dashboard adds is skipped rather than drawn blind. Purchases are bound to
the Firebase UID via `PurchaseIdentity` so an entitlement follows the person,
not the install.
