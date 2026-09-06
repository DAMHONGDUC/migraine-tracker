# Remaining release work

Snapshot: 2026-08-30. All v1.0 features are implemented. Re-check external
state before acting because this list includes consoles and legal work.

## Blocking checklist

| Order | Owner action | Where | Blocked result |
|---:|---|---|---|
| 1 | Create monthly and yearly products | App Store Connect | Paywall has no plans |
| 2 | Sign the Paid Apps Agreement | App Store Connect | Products remain unavailable |
| 3 | Attach both products to the RevenueCat offering | RevenueCat | Paywall has no plans |
| 4 | Install real dev/prod RevenueCat keys | Local secret files | Purchases cannot initialize |
| 5 | Complete App Privacy labels | App Store Connect | Submission is incomplete |
| 6 | Create `app_config/app` with its `force_update` field | Firestore | Force update always fails open |
| 7 | Create an App Store Connect API key with App Manager role | App Store Connect | CI cannot upload |
| 8 | Create a private `match` repository | Git provider | CI has no signing store |
| 9 | Run `fastlane certificates` once on a Mac | Local Mac | CI cannot bootstrap certificates |
| 10 | Add release repository secrets | GitHub Actions | Release workflow fails |
| 11 | Generate and commit `ios/Gemfile.lock` with Ruby 3.x | Repo | CI resolves gems every run |
| 12 | Add the standard EULA link to the App Description | App Store Connect | Subscription review fails |
| 13 | Decide export classification and update encryption metadata | Legal + repo | Upload may be blocked |
| 14 | Complete the French ANSSI declaration or remove France | Legal | French distribution is non-compliant |
| 15 | Have a lawyer review the privacy policy | Legal | Policy remains unverified |
| 16 | Test HealthKit, push and the widget on a real device | iPhone | Native behavior is unverified |
| 17 | Add the real App Store ID to `docs/privacy/privacy.json` | Repo | Published store link is missing |
| 18 | Confirm both Siri phrases appear in the Shortcuts app | iPhone | The App Intents are unverified off-device |
| 19 | Deploy the functions after the onset-alert change | Firebase | Users get one push per front instead of two |

## Required release secrets

| Secret | Required |
|---|---|
| `ENV_PROD_JSON` | Yes |
| `ENV_DEV_JSON` | Yes |
| `ASC_KEY_ID` | Yes |
| `ASC_ISSUER_ID` | Yes |
| `ASC_KEY_CONTENT` | Yes, base64 |
| `MATCH_PASSWORD` | Yes |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Yes, base64 `user:PAT` |
| `MATCH_GIT_URL` | Optional |
| `FIREBASE_APP_ID_IOS` | Optional |

Never place secret values in documentation or command output.

## Checks that are easy to miss

| Check | Required detail |
|---|---|
| Firestore `app_config/app` | One fixed document id, `app`; never put an address on it — it is world-readable |
| App Privacy | Synced health/fitness and signed-in analytics are linked to identity |
| RevenueCat keys | Empty is safe; plausible test placeholders can crash native setup |
| Provisioning | Profiles must include app, widget, push, HealthKit and App Group capabilities |
| Widget | Confirm rendering and that its log button opens the attack flow |
| Encryption | Read `release/APP_ENCRYPTION.md` before changing `ITSAppUsesNonExemptEncryption` |

## References

| Task | Document |
|---|---|
| Release flow | [`release/PIPELINE.md`](release/PIPELINE.md) |
| Credentials | [`release/CREDENTIALS.md`](release/CREDENTIALS.md) |
| Pending setup details | [`rules/PENDING_SETUP.md`](rules/PENDING_SETUP.md) |
| Store copy and EULA | [`release/APP_STORE_LISTING.md`](release/APP_STORE_LISTING.md) |
| Encryption decision | [`release/APP_ENCRYPTION.md`](release/APP_ENCRYPTION.md) |
| Privacy source | [`privacy/PRIVACY_POLICY.md`](privacy/PRIVACY_POLICY.md) |
