# A separate prod Firebase project

Today there is one project, `migraine-tracker-9f7b2`, and both `env/dev.json`
and `env/prod.json` point at it. So there is nothing to practise on: a rules
deploy reaches real users immediately, a force-update record written while
testing blocks them, and `sendTestPush` ships wherever the functions ship. This
is the work that ends that.

**Nothing in the repo has to change first.** The app already reads every Firebase
identifier from `AppEnv`, so a second project is a second `env/*.json` and a
second pair of native config files — no code, no `firebase_options.dart` edit.

**It is not free.** Cloud Functions v2, Cloud Scheduler and any outbound call to
WeatherKit need the **Blaze** plan, so the new project needs a billing account
before step 5.

## What does not get duplicated

- **The Apple keys are per team, not per project.** The same APNs `.p8` and the
  same WeatherKit `.p8` serve both — but each must be *uploaded into* each
  project (APNs into Firebase, WeatherKit into that project's Secret Manager).
- **The WeatherKit quota is per developer account.** 500k calls/month covers both
  projects together, so a dev project spending it takes it from prod.
- **RevenueCat stays one app** unless you also split the store products. What
  moves is the webhook URL, which is per environment.
- **The bundle id stays one** (`app.dd.migraine.tracker`), because one App Store
  record serves both builds. Two Firebase projects may register the same bundle
  id; two App Store records is a different and much larger decision
  (`docs/rules/COMMANDS.md`).

## Order

Each step depends on the one before it.

### 1. Create the project

Firebase console → Add project. Name it so the two are unmistakable at a glance
in the console's project picker — the deploy prompt prints the id, and that is
the last thing standing between a rules push and real users.

**Enable Google Analytics.** The app ships `firebase_analytics` and 36 typed
events through `AppAnalytics`, and the privacy policy declares Analytics — a
project without it collects none of them, silently. Attach the new project to
the **existing Analytics account** in the dropdown rather than creating a second
one: one account, two properties, one set of permissions to manage.

**"Analytics location" is the account's country, not where the data lives.** GA4
does not let you choose a storage region at all, so this field only picks the
jurisdiction and terms the Analytics account sits under — set it to the country
of whoever owns the account. It is not the permanent data-residency choice; the
Firestore location in the next step is.

### 2. Firestore, in the same location as today's

Build → Firestore Database → Create. **Choose the location deliberately: it is
permanent**, and the data is EU-resident by rule (`docs/rules/PRIVACY_AND_SECURITY.md`).
Match the existing project rather than picking again.

Start in **production mode** — the repo's own rules replace the default in step 6.

### 3. Register the iOS and Android apps

Project settings → Your apps.

- **iOS**: bundle id `app.dd.migraine.tracker`. Download `GoogleService-Info.plist`.
- **Android**: package `app.dd.migraine.tracker`. Download `google-services.json`.

Put both in `env_assets/` under the `prod-` names `sh packages/system_design/tool/prepare-env.sh prod`
expects: `prod-GoogleService-Info.plist`, `prod-google-services.json`. A third
name goes beside them, `prod-Info.plist` — the Runner `Info.plist` carrying this
project's Google sign-in URL scheme, which has to switch with the plist rather
than after it (`docs/rules/COMMANDS.md`).

### 4. Authentication

Build → Authentication → Sign-in method. All three, and **Anonymous is not
optional**: it is the default session every install runs on, and without it
`getWeather` fails with `admin-restricted-operation` on a fresh install
(hard rule 1).

- **Anonymous**
- **Google** — this is what mints the `CLIENT_ID` / `REVERSED_CLIENT_ID` in the
  new `GoogleService-Info.plist`, so download that file again after enabling it,
  and put the matching URL scheme in `env_assets/prod-Info.plist` — not in
  `ios/Runner/Info.plist`, which the next `prepare-env` run overwrites
  (`docs/setup/AUTH_SETUP.md`).
- **Apple** — same Services ID, Team ID, Key ID and `.p8` as the dev project.

### 5. Billing

Upgrade to **Blaze**. Steps 6 and 7 fail without it, and the failure names a
quota rather than a plan.

### 6. Rules and indexes

```bash
firebase use --add          # pick the new project, alias it `prod`
melos run deploy-firebase-prod rules
```

`firebase use --add` rewrites the `prod` alias in `.firebaserc`, which today
still points at the dev project — that alias is the only thing the deploy
commands switch on, so pointing it at the new project is what makes
`deploy-firebase-prod` mean it. Leave `dev` where it is. **Rules and indexes
always deploy together** — a missing composite index fails at runtime, not at
build.

What lands: the four synced collections (`attacks`, `medications`,
`medication_reminders`, `notifications`) with their `userId` + `updatedAt`
indexes and the three opaque fields exempted, plus `users`, `sync_keys` and the
public read-only `app_config/app`.

### 7. Functions: params, secrets, then deploy

**The three WeatherKit identifiers are per project.** The CLI reads
`functions/.env` by default and `functions/.env.<project-id>` for a specific
one, so give the new project its own file with the same three keys
(`docs/setup/WEATHERKIT_SETUP.md` lists them). An empty value fails the deploy
rather than prompting, because melos pipes the script's stdout.

**The two secrets are per project too**, and Secret Manager is per project:

```bash
firebase functions:secrets:set WEATHERKIT_PRIVATE_KEY   # paste the .p8
firebase functions:secrets:set REVENUECAT_WEBHOOK_AUTH  # invent a long random string
```

Then:

```bash
melos run deploy-firebase-prod functions
```

Six functions land, all in **europe-west1** (`FirebaseConstants.functionsRegion`
must keep matching `REGION` in `functions/src/index.ts`, or a callable is simply
not found): `pressureAlertJob`, `getSyncKey`, `deleteAccount`,
`revenuecatWebhook`, `getWeather`, `sendTestPush`.

**The deploy creates the Cloud Scheduler job** for `pressureAlertJob` (every 3
hours, UTC). Check it exists in the Google Cloud console afterwards — a
scheduler that silently failed to create is an alert feature that never fires
and never errors.

### 8. Push

Project settings → Cloud Messaging → **APNs Authentication Key**: upload the
same `.p8`, Key ID and Team ID. Without it every alert push is accepted by FCM
and delivered nowhere.

### 9. RevenueCat's webhook

RevenueCat dashboard → Integrations → Webhooks. Point it at the new project's
`revenuecatWebhook` URL and set the Authorization header to the value you gave
`REVENUECAT_WEBHOOK_AUTH` in step 7. Without this, a purchase never flips
`premium` on the user doc and the alert cron skips that user for ever.

### 10. Fill `env/prod.json`

The key names are in `env/prod.example.json` — the committed, value-free
template. Copy every Firebase identifier out of the new project's settings and
the two RevenueCat keys as they are.

Then put everything where the build reads it:

```bash
sh packages/system_design/tool/prepare-env.sh prod
```

**Do not open `env/*.json` to check the values** (hard rule 13). If a build
comes up misconfigured, `AppEnv.missingConfigKeys` names the empty keys for you.

### 11. `app_config` in the new project

Created by hand: the one `app_config/app` document, holding the app-wide
switches, the force-update record and the three address lists
(`docs/rules/PENDING_SETUP.md` has the schema and a full sample). It does not
travel between projects — a new project starts with premium on, nobody blocked
and nobody force-updated, which is the safe state.

### 12. CI

Repository secrets → Settings → Secrets and variables → Actions.
`ENV_PROD_JSON` and `GOOGLE_SERVICE_INFO_PLIST_PROD` become the prod values;
`ENV_DEV_JSON` and `GOOGLE_SERVICE_INFO_PLIST_DEV` keep pointing at the old
project. Both plist secrets are needed from here on: the release lane compares
the plist's `PROJECT_ID` against the flavor's alias in `.firebaserc` and stops
if they disagree. `FIREBASE_APP_ID_IOS` is the new iOS app id, or the
Crashlytics symbol upload is skipped with a warning
(`docs/release/CREDENTIALS.md`).

## Verifying, in this order

1. **A fresh install signs in anonymously and the weather card fills.** That one
   check covers Anonymous auth, the callable region, the WeatherKit secret and
   the three identifiers at once.
2. **Sign in with Google, then with Apple.** A failure here is the provider
   config, not the app: `AuthError.notConfigured` means the console side.
3. **Log an attack, then sync.** Proves the rules, both indexes and `getSyncKey`.
   `permission-denied` on the pull means the rules deploy did not land.
4. **The dev-only test push row** (Settings → Dev). Proves APNs.
5. **Buy in sandbox**, then check `premium` flips on the user doc. Proves the
   webhook.
6. **Leave it a few hours and check the scheduler ran.** Nothing else proves the
   cron.

## Afterwards

Two things in the repo become out of date the day this lands, and each says so
where it is written: the "same project" note in `docs/rules/COMMANDS.md` and the
force-update caveat in `docs/rules/PENDING_SETUP.md`. Update both in the same
change. The deploy script needs nothing: its "dev and prod are the SAME project"
warning compares the two aliases at run time and stops printing the moment they
differ.
