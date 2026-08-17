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
  **CI follows the same branch** — `git submodule update --remote` runs after
  checkout in both workflows, because a laptop and a runner quietly building
  different design systems is the worse failure. The price is that no build is
  reproducible from its commit alone, and a broken push to the design system's
  `main` breaks this repo's CI with nothing here having changed. Note that
  `branch = main` in `.gitmodules` does *not* do this on its own: plain
  `actions/checkout` still takes the pinned gitlink, and only `--remote` reads
  that line.
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
- `cd ios && bundle exec fastlane beta flavor:prod` — the same build, plus signing, export and the TestFlight upload. **Fastlane never archives**: it shells out to `tool/build-ipa.sh`, because `gym` cannot pass `--dart-define-from-file` and an archive made without it is the `[core/no-app]` crash above. Do not "simplify" the lane into `build_app`.
  - **The release is a manually triggered workflow** (`release-ios.yml`, `workflow_dispatch`), runnable from any branch — but GitHub lists a `workflow_dispatch` entry only once its file is on the **default** branch. The bump commit goes back to the branch chosen, so a protected `main` rejects it and the job fails with the build already up.
  - **CI bumps the build number by rewriting `pubspec.yaml`, never with `--build-number`**, and pushes that commit only **after** the upload succeeds. The rule protects that the number exists in git, not that a human typed it; a bump with no build is a gap in the numbering, a build with no commit is what the rule exists to prevent. It takes `max(pubspec, TestFlight) + 1`, because App Store Connect refuses a number it has seen from any branch. That commit also carries the design system's gitlink, and names its commit in the message — the tree is the authority, but a gitlink appears in neither `git log --oneline` nor a GitHub commit list, which is exactly where someone looks to ask what shipped. The `bump` input off means the file is used as-is — **and then nothing records the design system either**, since that same commit is what writes the gitlink the release was built from.
  - **Manual signing is applied on CI only**, in the throwaway checkout — a runner has no Apple ID logged into Xcode, while a developer's Mac keeps automatic signing and never sees the pbxproj edit. `match` runs `readonly: true` there; the certificate is minted once from a real Mac by `fastlane certificates`, because a runner allowed to create them burns Apple's limit of three one failed job at a time.
  - **The lane writes `ExportOptions.plist`, not Flutter.** `--export-method` makes Flutter generate one mapping the **main bundle id only** — multi-target is a TODO in its own source — so the widget extension gets no profile and `exportArchive` fails after the whole build. `build-ipa.sh` drops its own `--export-method` when a caller passes a plist; Flutter refuses both together.
  - **dSYMs go to Crashlytics best effort**, after the upload. Bitcode is gone so nothing else sends them, but by then the build has shipped: every failure path warns rather than raises. Two fastlane defaults do not hold here — the `Pods/` binary path (Firebase is SPM) and `gsp_path` (`GoogleService-Info.plist` is gitignored).
- `cd ios && CI=true bundle exec fastlane preflight` — **rehearse the runner without building.** The release lane's first three minutes and none of the twenty-five after: API key, build number, `match`. Every credential failure this pipeline has hit surfaces here in seconds, and none of them needed an IPA to appear.
  - **`CI=true` is the point** — without it the lane skips `match`, the half most likely to break. Reproduce the runner exactly by also setting the variables whose secrets do not exist: `CI=true MATCH_GIT_BEARER_AUTHORIZATION= bundle exec fastlane preflight`. An empty variable is not an absent one, and that difference was a whole afternoon.
- The pipeline as a diagram is `docs/release/PIPELINE.md`. Every credential — how it is made, where it lives, how it fails — is `docs/release/CREDENTIALS.md`. What is still missing is `docs/rules/PENDING_SETUP.md`.
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
