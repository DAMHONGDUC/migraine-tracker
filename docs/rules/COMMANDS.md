# Commands, tooling and scripts

Melos is the task runner. Read this before running, building, seeding or
deploying anything.

**Melos is the task runner** (`melos.yaml`). Installed once per machine at the
version `pubspec.yaml` pins — `dart pub global activate melos 6.3.3`. The
global and local versions must match exactly or melos runs one version's code
against the other's asset templates and bootstrap dies; that is why the
dependency is pinned, not caret-ranged. **Melos 6, not 7/8, on purpose** —
`melos.yaml` explains the two costs of the workspace-based versions.

- `melos run set-up` — **always wipes first** (`tool/_clean.sh`: `flutter
  clean`, gradle, pods), then everything a clone needs, in order: submodules,
  `pub get` for both packages, `gen-l10n`, `build_runner`, `env/*.json` from
  the templates, `npm ci` in `functions/`, and `pod install` on macOS.
  Idempotent — re-run it any time.
  **The wipe is unconditional on purpose**: setup is the one answer to "it
  built yesterday and not today". Don't reach for it when `melos run gen`
  would do.
  **It puts each submodule on the branch named in `.gitmodules` (`main`) and
  fast-forwards it, rather than leaving it detached at the recorded gitlink.**
  So the design system is always editable in place — and what you build is
  whatever is on that branch, NOT what the parent commit pins. When the branch
  moves ahead, `packages/system_design` shows as modified; commit that gitlink
  deliberately, and never assume an old parent commit rebuilds byte-for-byte.
- `melos run gen` — after editing Drift tables, Riverpod codegen, or ARB files
- `melos run analyze` — `--fatal-infos`, exactly what CI runs. Must pass with
  zero findings before considering any task done.
- `melos run test` — the whole suite. **Never run the whole suite to verify a change, no exception** — not even one that touches shared code (theme, spacing, the design system) and not "just before a commit" either. Always scope to what changed: `flutter test test/features/<x>/<y>_test.dart`, narrowed with `--plain-name` when one case is failing. The full suite is minutes of wall clock through the harness to re-learn what one scoped file already tells you — that cost is why this is absolute, not a judgment call per change.
- `melos run deep-set-up` — setup, plus **Xcode's DerivedData**. The only
  difference, and the reason it is separate: clearing that cache costs a full
  cold build every time. Reach for it when a build fails in a way the code
  cannot explain — a precompiled module Xcode refuses to reuse ("has been
  modified since the module file was built"), a header resolving to a version
  you no longer depend on, a failure that comes and goes on one commit —
  which is almost always right after a native dependency moved.
  **DerivedData is matched on the workspace path each cache records, never on
  the folder name**: every Flutter app builds a target called `Runner`, so
  deleting `Runner-*` would take other projects' caches with it.
- `melos run build-ipa-prod` / `build-ipa-dev` — the IPA, per environment. **They build and nothing else**; uploading is the fastlane lane below. The pair used to be called `release-ios` / `release-ios-dev`, which claimed a release neither of them performed — renamed once fastlane took that job. **One `tool/build-ipa.sh` takes the environment as its argument**, rather than a script each: the two differ only by which `env/*.json` is attached. **Both export `app-store`**, because both are meant for TestFlight and that is the only method App Store Connect accepts. Anything after the environment passes straight to `flutter build ipa`, which is how `--build-number` and a sideloading `--export-method` get in.
  - **It wipes `build/ios/ipa` first.** Both environments write the same filename to the same folder, so a leftover IPA from the other one is indistinguishable from the build you just made — and the two carry different Firebase and RevenueCat keys. Clearing first means the folder holds exactly one file and it is the one just built.
  - **Version and build number are edited in `pubspec.yaml`, never passed as a flag.** `--build-number` still passes through, but using it ships a build whose version exists nowhere in git — the repo then cannot say what went out. The script prints the version it is about to build so the number is confirmed before the upload, not after the rejection.
  - **One bundle id (`app.dd.migraine.tracker`) serves both**, so a dev build and a prod build land in the SAME TestFlight app and the build number is the only thing telling them apart — App Store Connect refuses one it has already seen, across both. Separating them means a real flavour setup: a second bundle id, its own App Store Connect record, its own Firebase iOS app and its own RevenueCat app. Not done, and not worth doing while `env/dev.json` and `env/prod.json` still point at the same Firebase project.
  - Why the script exists at all is in its header and in the RevenueCat section below: Xcode's Product > Archive cannot pass `--dart-define-from-file`, and the resulting crash names nothing to do with the missing flag.
- `cd ios && bundle exec fastlane beta flavor:prod` — the same build, plus signing, export and the TestFlight upload. **Fastlane never archives here**: it shells out to `tool/build-ipa.sh`, because `gym`/`build_app` cannot pass `--dart-define-from-file` and an archive made without it is exactly the `[core/no-app]` crash above. Do not "simplify" the lane into `build_app`.
  - **The release runs from GitHub Actions, manually triggered** (`.github/workflows/release-ios.yml`, `workflow_dispatch`). Running the lane by hand on the Mac works, but `melos run build-ipa-prod` plus Transporter is fewer moving parts locally — the lane exists for CI.
  - **Any branch, from the "Use workflow from" dropdown.** The run uses that branch's code *and* its own copy of the workflow file. But GitHub only lists a `workflow_dispatch` entry once the file exists on the **default** branch, so the workflow has to reach `main` once before any branch can be picked. The bump commit is pushed back to whichever branch was chosen — a protected `main` rejects it unless the Actions bot is allowed to push, and the job then fails with the build already on TestFlight.
  - **CI bumps the build number by rewriting `pubspec.yaml`, never with `--build-number`.** What the flag rule protects is that the number exists in git, not that a human typed it — a build numbered from the run counter is one the repo cannot account for afterwards. So the lane writes `max(pubspec, latest on TestFlight) + 1` into the file and pushes that commit **after** the upload succeeds: a bump commit with no build is a gap in the numbering, a build with no commit is the failure the rule exists to prevent. Read from TestFlight rather than from `pubspec.yaml` alone because App Store Connect has seen the builds of every branch that ever ran this lane, and refuses a number twice. Turn the `bump` input off to use the file as-is; the lane then checks it before building and fails in seconds if it was not bumped.
  - **Signing is `match`, and manual signing is applied on CI only.** A runner cannot sign automatically — that needs an Apple ID logged into Xcode. The lane installs the shared certificate and both profiles, then flips `Runner` **and** `BaroEaseWidgetExtension` to manual signing in the throwaway checkout, so a developer's Mac keeps automatic signing and the pbxproj edit never reaches git. CI is `readonly: true`; the certificate is minted once by `fastlane certificates` from a real Mac, because a runner permitted to create them burns Apple's limit of three one failed job at a time.
  - **The ExportOptions.plist is written by the lane, not by Flutter.** `--export-method` makes Flutter generate one, and that generator maps the **main bundle id only** — multi-target apps are a TODO in its own source. The widget extension would get no profile and `exportArchive` would fail *after* the whole build. So the lane writes a plist naming both ids, and `build-ipa.sh` drops its own `--export-method` whenever a caller passes `--export-options-plist` (Flutter refuses the two together). Nothing changes for a local build, which still passes neither.
  - **dSYMs go to Crashlytics from the lane, best effort.** Bitcode is gone, so nothing on Apple's side uploads them and a crash report without them is unsymbolicated. It runs after the TestFlight upload and every failure path is a warning, not a raise: the build is already up by then, and missing symbols are something to fix rather than a reason to re-cut a release. Two fastlane defaults do not apply here and the helper says why — the `Pods/` binary path (Firebase is SPM) and `gsp_path` (`GoogleService-Info.plist` is gitignored).
- `cd ios && CI=true bundle exec fastlane preflight` — **rehearse the runner without building.** It does the release lane's first three minutes and none of the twenty-five that follow: resolve the API key, ask App Store Connect for the latest build number, then run `match`. Every credential failure this pipeline has hit — a rejected token, a newline inside the auth header, a second empty `Authorization` header — surfaces here, and none of them needs an IPA to appear.
  - **`CI=true` is the whole point.** Without it the lane skips `match`, because a developer's Mac signs automatically; with it, the half most likely to break actually runs. To reproduce the runner exactly, set the variables it sets *including the ones whose secrets do not exist* — `CI=true MATCH_GIT_BEARER_AUTHORIZATION= bundle exec fastlane preflight` — because an empty one is not the same as an absent one, and that difference is what the duplicate-header failure was.
  - Reach for this before pushing any change to signing or to a secret. A failed release job costs a few macOS minutes out of 200 and ten minutes of waiting; this costs seconds.
  - Credentials — how each one is made, where it lives, and every failure mode paid for so far — are in `docs/RELEASE_CREDENTIALS.md`. What is still outstanding is in `docs/rules/PENDING_SETUP.md`. None of them are in this repo.
  - The order of the whole thing, as a diagram: `docs/RELEASE_PIPELINE.md`.
- **There are exactly two entry points, `set-up` and `deep-set-up`.** The wipe
  itself is `tool/_clean.sh`, underscore-prefixed like `_common.sh` because it
  is not a command — it is never run on its own, and `melos.yaml` does not
  name it. Don't add a third clean-shaped command; the choice is only ever
  "with DerivedData or without".
- `flutter run --dart-define-from-file=env/dev.json` — Firebase config comes from `env/dev.json` / `env/prod.json` (gitignored; `env/*.example.json` are the committed key-only templates). Read config only through the `AppEnv` class (`lib/core/env/app_env.dart`) — it is the ONLY place `String.fromEnvironment` may appear; `firebase_options.dart` and everything else read `AppEnv.*`. VS Code launch configs already pass this flag (dev → `env/dev.json`, prod → `env/prod.json`).
- `cd functions && npm run build && npm test` — after touching Cloud Functions
- **The dev seed fills EVERY table, and health with it.** Owner's rule. `DevSeedService` covers attacks (+ their weather snapshots), medications, reminders, exports, `DailyWeather` and `AppNotifications`; `SyncTombstones` is filled by *deleting* a few of the rows it just wrote, which is the only way a tombstone is ever made — writing one by hand would fabricate a row no delete produced.
  - **`DailyWeather` is the one that changes what you can see.** It is the correlation's denominator (hard rule: `DailyPressure`), so without it the pressure card can only say "what share of my attacks fell during drops" and never "am I more likely to attack when it drops". Seeded days that ended in an attack are biased to drop, so `PressureBaseline` has two sides that differ.
  - **Notification ids come from the real derivers** (`AppNotification.reminderOccurrenceId` / `.pressureAlertId`), never a UUID: a random id is a row no real writer could ever match, which is exactly the idempotence hard rule 16 depends on.
  - **Health is NOT a table, so it is seeded differently.** HealthKit is read-only and nothing it returns is persisted, so there is nothing to write — `DevSeededHealthRepository` generates nights, days and hours from a seed instead, and `healthRepositoryProvider` swaps it in behind `!AppEnv.isProd` *and* a `PrefsKeyConstant.devHealthSeed` that only the dev seed writes. It exists because **HealthKit does not exist on the Simulator**: real reads there come back empty and nothing can tell that from a refusal, so the sleep and activity cards could never be seen populated on a laptop.
    - A day's numbers are generated from the day itself, so a week and a month cannot disagree about Tuesday.
    - `SettingsController.seedDevData` connects both sources after setting the seed, so `connect` asks the fake rather than the plugin; the GDPR wipe clears the seed alongside `disconnectAll`, because "delete everything" that leaves invented health data still generating is a lie about what it did.
- `melos run deploy-firebase` — the whole Firebase side: firestore rules and indexes, then the functions, after running the functions' own tests. **Rules and indexes always deploy together** (`--only firestore:rules,firestore:indexes`), because a missing composite index fails at runtime rather than at build, so shipping one without the other is a live breakage. Takes an optional target — `rules` or `functions` — to do half of it.
  - **It prints `firebase use` and asks before deploying, on purpose.** `env/dev.json` and `env/prod.json` point at the SAME project, so there is no dev target to practise on and a rules deploy reaches real users immediately. The prompt reads from `/dev/tty` first because melos pipes the script's stdout.
- **`firebase.json`'s functions predeploy calls `tsc` directly, never `npm run build`.**
  The standalone Firebase CLI is a pkg snapshot bundling its *own* Node 20 and npm
  8.19.4, whatever the machine has; that npm crashes inside `promiseSpawnUid` reading
  `process.stdin`, which does not exist in a snapshot. The failure looks like a broken
  build script — `tsc` even prints first — but the same command run by hand succeeds,
  and the npm debug log is the only place the bundled versions show up. Don't "fix" it
  by putting npm back.
- `firebase emulators:start` — test functions locally; never test cron against production.
  **Needs a JDK on PATH** (11+): the Firestore emulator is a Java program. macOS ships
  `/usr/bin/java` as a stub whose only job is to tell you Java is missing, so the failure
  looks like a broken PATH rather than a missing install — and it lands *after* the
  TypeScript tests pass, which reads as the tests having broken something. `sdk install
  java 21.0.12-tem` if you use SDKMAN. Deploying needs no JDK; only the emulator does.

**Every script's body lives in `tool/<name>.sh`; `melos.yaml` only names it.**
Melos echoes the whole `run:` block before AND after each run, with no flag to
turn it off, so a multi-line body buries the output it introduces. A file is
also the only version that can be linted and run directly. Adding a command is
a `tool/*.sh` plus one line in `melos.yaml`.

Those scripts are **POSIX sh, not bash**: melos runs them through `/bin/sh`,
which is dash on Linux, where `set -o pipefail`, `[[ ]]` and `local` are
syntax errors. macOS will not catch this — its `/bin/sh` is bash under
another name — so check a change with `dash -n tool/<name>.sh`.

`tool/_common.sh` is sourced by all of them and holds the two things they
share: the SDK resolution (`fvm flutter` when `.fvmrc` and fvm are both
present, plain `flutter` otherwise — a shell alias is invisible inside a
script), and `step`/`warn`/`done_msg`, which colour their output only when
stdout is a terminal so CI logs stay readable.
