# Commands, tooling and scripts

Melos is the task runner (`melos.yaml`). Read this before running, building,
seeding or deploying anything.

Installed once per machine at the version `pubspec.yaml` pins — `dart pub global
activate melos 6.3.3`. **The global and local versions must match exactly**, or
melos runs one version's code against the other's asset templates and bootstrap
dies on a missing `.tmpl`; that is why the dependency is pinned, not
caret-ranged. **Melos 6, not 7/8, on purpose** — `melos.yaml` explains the two
costs of the workspace-based versions.

## Setting up and everyday work

### `melos run set-up`

Everything a clone needs, in order: submodules, `pub get` for both packages,
`gen-l10n`, `build_runner`, `env/*.json` from the templates, `npm ci` in
`functions/`, `pod install` on macOS. Idempotent.

- **It always wipes first** (`tool/_clean.sh`: `flutter clean`, gradle, pods).
  Unconditional on purpose: setup is the one answer to "it built yesterday and
  not today". Don't reach for it when `melos run gen` would do.
- **It puts each submodule on the branch named in `.gitmodules` (`main`) and
  fast-forwards it**, rather than leaving it detached at the recorded gitlink, so
  the design system is always editable in place. The price: what you build is
  whatever is on that branch, not what the parent commit pins. When the branch
  moves ahead, `packages/system_design` shows as modified — commit that gitlink
  deliberately, and never assume an old parent commit rebuilds byte-for-byte.
- **CI follows the same branch** (`git submodule update --remote` after
  checkout, in both workflows), because a laptop and a runner quietly building
  different design systems is the worse failure. So no build is reproducible from
  its commit alone, and a broken push to the design system's `main` breaks this
  repo's CI with nothing here having changed. `branch = main` in `.gitmodules`
  does not do this by itself — plain `actions/checkout` still takes the pinned
  gitlink, and only `--remote` reads that line.

### `melos run prepare-env-dev` / `prepare-env-prod`

Copy the real config from `env_assets/` into the four paths the build reads:
`env/dev.json`, `env/prod.json`, `android/app/google-services.json` and
`ios/Runner/GoogleService-Info.plist`. `env_assets/` holds the same live keys
`env/` does, so it is gitignored and a clone never has it.

- **Both `env/*.json` are written whatever the target is** — one destination
  each, nothing to choose. The target picks only the two native files, which also
  have one destination each: one bundle id and one Firebase project serve both
  environments, so there is no second path a `prod-` file could go to.
- **The destinations carry no `dev-`/`prod-` prefix.** Those are the paths the
  google-services gradle plugin and the Runner target's Resources phase read; a
  prefixed copy beside them is a file nothing opens, and the build fails later
  naming none of it.
- **Every source is checked before anything is copied.** Dying halfway leaves a
  tree half one environment and half the other with nothing saying so, so a
  missing file names all of them and copies none.
- **It never reads what it copies** (hard rule 13), and **it overwrites** — that
  is how a checkout switches environment. `melos run set-up` still fills in
  `env/*.example.json` only when the real file is absent, so setting up
  afterwards cannot undo it.

### The rest

- `melos run gen` — after editing Drift tables, Riverpod codegen or ARB files.
- `melos run analyze` — `--fatal-infos`, exactly what CI runs. Zero findings
  before any task is done.
- `melos run test` — the whole suite. **Never run it to verify a change, no
  exception** — not for shared code (theme, spacing, the design system), not
  "just before a commit". Scope to what changed: `flutter test
  test/features/<x>/<y>_test.dart`, narrowed with `--plain-name`. The full suite
  is minutes of wall clock to re-learn what one scoped file already said.
- `melos run deep-set-up` — setup plus **Xcode's DerivedData**. Separate because
  clearing that cache costs a full cold build. Reach for it when a build fails in
  a way the code cannot explain — a module Xcode refuses to reuse ("has been
  modified since the module file was built"), a header resolving to a version you
  no longer depend on, a failure that comes and goes on one commit — almost
  always right after a native dependency moved. **DerivedData is matched on the
  workspace path each cache records, never on the folder name**: every Flutter
  app builds a target called `Runner`, so deleting `Runner-*` would take other
  projects' caches with it.
- **There are exactly two entry points, `set-up` and `deep-set-up`.** The wipe
  itself is `tool/_clean.sh`, underscore-prefixed like `_common.sh` because it is
  not a command. Don't add a third clean-shaped one; the choice is only ever
  "with DerivedData or without".
- `flutter run --dart-define-from-file=env/dev.json` — Firebase config comes from
  `env/dev.json` / `env/prod.json` (gitignored; `env/*.example.json` are the
  committed key-only templates). Read config only through `AppEnv`
  (`lib/core/env/app_env.dart`) — the ONLY place `String.fromEnvironment` may
  appear; `firebase_options.dart` and everything else read `AppEnv.*`. The VS
  Code launch configs already pass the flag.
- `cd functions && npm run build && npm test` — after touching Cloud Functions.

## Building the IPA

`melos run build-ipa-prod` / `build-ipa-dev`. **They build and nothing else** —
uploading is fastlane's job, which is why the pair is no longer called
`release-ios`. One `tool/build-ipa.sh` takes the environment as its argument;
the two differ only by which `env/*.json` is attached. Anything after the
environment passes straight to `flutter build ipa`.

- **Both export `app-store`** — both are meant for TestFlight, and that is the
  only method App Store Connect accepts.
- **It wipes `build/ios/ipa` first.** Both environments write the same filename
  to the same folder, and they carry different Firebase and RevenueCat keys, so a
  leftover IPA is indistinguishable from the one just built.
- **Version and build number are edited in `pubspec.yaml`, never passed as a
  flag.** `--build-number` still passes through, but using it ships a build whose
  version exists nowhere in git. The script prints the version it is about to
  build, so the number is confirmed before the upload rather than after the
  rejection.
- **One bundle id (`app.dd.migraine.tracker`) serves both**, so dev and prod land
  in the SAME TestFlight app and the build number is all that tells them apart —
  and App Store Connect refuses one it has seen from either. Separating them
  means a real flavour setup: a second bundle id, its own App Store Connect
  record, its own Firebase iOS app, its own RevenueCat app. Not worth doing while
  both `env/*.json` point at the same Firebase project.
- **Why the script exists**: Xcode's Product > Archive cannot pass
  `--dart-define-from-file`, so an archive made that way carries empty config and
  crashes with `[core/no-app]`, which names nothing to do with the missing flag.

## Releasing to TestFlight

`cd ios && bundle exec fastlane beta flavor:prod` — the same build, plus signing,
export and upload. **Fastlane never archives**: it shells out to
`tool/build-ipa.sh`, because `gym` cannot pass `--dart-define-from-file` and an
archive without it is the crash above. Do not "simplify" the lane into
`build_app`.

- **The release is a manually triggered workflow** (`release-ios.yml`,
  `workflow_dispatch`), runnable from any branch — but GitHub lists a
  `workflow_dispatch` entry only once its file is on the **default** branch. The
  bump commit goes back to the branch chosen, so a protected `main` rejects it
  and the job fails with the build already up.
- **CI bumps the build number by rewriting `pubspec.yaml`**, never with
  `--build-number`, and pushes that commit only **after** the upload succeeds.
  The rule protects that the number exists in git, not that a human typed it. It
  takes `max(pubspec, TestFlight) + 1`, because App Store Connect refuses a
  number it has seen from any branch. That commit also carries the design
  system's gitlink and names its commit in the message — a gitlink appears in
  neither `git log --oneline` nor a GitHub commit list, which is exactly where
  someone looks to ask what shipped. With `bump` off, nothing records the design
  system either.
- **Manual signing is applied on CI only**, in the throwaway checkout: a runner
  has no Apple ID in Xcode, while a developer's Mac keeps automatic signing and
  never sees the pbxproj edit. `match` runs `readonly: true` there; the
  certificate is minted once from a real Mac by `fastlane certificates`, because
  a runner allowed to create them burns Apple's limit of three one failed job at
  a time.
- **Entitlements are checked against the installed profiles before the build**
  (`verify_profile_entitlements`). Xcode enforces the same rule but only once the
  target has compiled, so a profile minted before a capability existed costs
  three and a half minutes to say so. Key presence only, never values —
  `aps-environment` is `development` in the entitlements file and `production` in
  an App Store profile on purpose. A profile it cannot read is a warning and a
  skip: the guard exists to explain a build that was already going to fail, never
  to be the reason a good one does not go out.
- **`fastlane certificates` reuses an existing profile; `certificates force:true`
  regenerates it.** Adding a capability to an App ID does not touch a profile
  Apple already issued, and CI's `readonly: true` match can only install what the
  certificates repo holds — so a new capability reaches a build only through the
  `force` run. It regenerates profiles alone, so the limit of three is not in
  play.
- **The lane writes `ExportOptions.plist`, not Flutter.** `--export-method` makes
  Flutter generate one mapping the main bundle id only (multi-target is a TODO in
  its own source), so the widget extension gets no profile and `exportArchive`
  fails after the whole build. `build-ipa.sh` drops its own `--export-method`
  when a caller passes a plist; Flutter refuses both together.
- **dSYMs go to Crashlytics best effort**, after the upload — bitcode is gone so
  nothing else sends them, but by then the build has shipped, so every failure
  path warns rather than raises. Two fastlane defaults do not hold here: the
  `Pods/` binary path (Firebase is SPM) and `gsp_path` (the plist is gitignored).

### Rehearsing without building

`cd ios && CI=true bundle exec fastlane preflight` — the release lane's first
three minutes and none of the twenty-five after: API key, build number, `match`.
Every credential failure this pipeline has hit surfaces here in seconds.

**`CI=true` is the point** — without it the lane skips `match`, the half most
likely to break. Reproduce the runner exactly by also clearing the variables
whose secrets do not exist: `CI=true MATCH_GIT_BEARER_AUTHORIZATION= bundle exec
fastlane preflight`. An empty variable is not an absent one, and that difference
was a whole afternoon.

### Keychains

- **`setup_ci` runs on a real runner only — `runner?`, never `is_ci`.** `is_ci`
  is true on any machine with `CI` set, including a Mac rehearsing with
  `CI=true`, and there `setup_ci` creates `~/Library/Keychains/fastlane_tmp_keychain-db`,
  adds it to the keychain **search list**, and never removes it — a runner is
  discarded whole, a laptop is not. `match` then imports the shared certificate
  into it, so the same certificate lives in two keychains and `security
  find-identity -v -p codesigning` reports **four** "Apple Distribution"
  identities where there is one certificate (an identity is a certificate/key
  pair, and either copy pairs with either). Each is one more key codesign can
  stop and ask about at `exportArchive`. `runner?` reads `GITHUB_ACTIONS`, so the
  rehearsal still runs match — readonly, into the login keychain — and leaves
  nothing behind.
- **Clean up a keychain an older run left**, if `security list-keychains` still
  names one:

  ```sh
  security list-keychains -d user -s ~/Library/Keychains/login.keychain-db
  security default-keychain -s ~/Library/Keychains/login.keychain-db
  security delete-keychain ~/Library/Keychains/fastlane_tmp_keychain-db
  ```

  **The middle line is not optional, and leaving it out is worse than not
  cleaning up at all.** `list-keychains -s` rewrites the user search list *and
  clears the default keychain*: `security default-keychain` then answers "A
  default keychain could not be found", Xcode logs `DVTDeveloperAccountManager:
  Failed to load credentials … DVTSecErrorDomain Code=-25307`, and automatic
  signing can no longer fetch a profile on a machine that worked ten minutes
  earlier. `login.keychain-db` must be named in the first line or nothing signs
  at all; `System.keychain` is in the system domain and is untouched.
- **A local `beta` that stops at a codesign keychain prompt has failed, not
  paused.** The dialog is raised by `exportArchive`, which runs *after* the
  archive is built, so the four minutes are already spent:
  `build/ios/archive/Runner.xcarchive` exists and `build/ios/ipa` stays empty.
  Denying it surfaces as `errSecInternalComponent`, which names the Security
  framework and not the key. Fix it once per machine with `security
  set-key-partition-list -S apple-tool:,apple:,codesign: -s -k <login password>
  ~/Library/Keychains/login.keychain-db` (`README.md` has the copy-pasteable
  form). **It comes back after every `fastlane certificates` run** — each import
  adds another copy of the certificate with a fresh ACL. CI is unaffected:
  `setup_ci` builds a throwaway keychain and `match` sets its partition list.
- **Fastlane's gems install into `ios/vendor/bundle`, never the system Ruby.**
  `cd ios && bundle config set --local path vendor/bundle` once per machine, then
  `bundle install`. Homebrew's Ruby keeps its gem files read-only, so a plain
  `bundle install` dies on `Permission denied @ rb_sysopen … rdoc_plugin.rb` — an
  error naming a file nobody asked for rather than the directory it could not
  write. **`ios/.bundle/` and `ios/vendor/` are gitignored**, so the config never
  reaches CI, which pins Ruby 3.3 through `ruby/setup-ruby` and resolves gems its
  own way.
- **Local `beta` differs from CI in two ways.** `match` and the manual-signing
  switch are both inside `if is_ci`, so a developer's Mac signs automatically and
  never touches the shared certificate; and `commit_build_number` is `if bump &&
  is_ci`, so `bump:true` rewrites `pubspec.yaml` locally but does not commit it.
  Commit that number by hand after the upload.

The pipeline as a diagram is `docs/release/PIPELINE.md`; every credential is
`docs/release/CREDENTIALS.md`; what is still missing is `PENDING_SETUP.md`.

## Firebase

`melos run deploy-firebase` — firestore rules and indexes, then the functions,
after running the functions' own tests. Takes an optional target, `rules` or
`functions`, to do half of it.

- **Rules and indexes always deploy together** (`--only
  firestore:rules,firestore:indexes`): a missing composite index fails at
  runtime rather than at build, so shipping one without the other is a live
  breakage.
- **It prints `firebase use` and asks before deploying.** `env/dev.json` and
  `env/prod.json` point at the SAME project, so there is no dev target to
  practise on and a rules deploy reaches real users immediately. The prompt reads
  from `/dev/tty` because melos pipes the script's stdout.
- **`firebase.json`'s functions predeploy calls `tsc` directly, never `npm run
  build`.** The standalone Firebase CLI is a pkg snapshot bundling its own Node
  and npm 8.19.4; that npm crashes inside `promiseSpawnUid` reading
  `process.stdin`, which a snapshot does not have. It looks like a broken build
  script — `tsc` even prints first — but the same command by hand succeeds. Don't
  put npm back.
- `firebase emulators:start` — test functions locally; never test cron against
  production. **Needs a JDK on PATH** (11+): the Firestore emulator is a Java
  program, and macOS ships `/usr/bin/java` as a stub whose only job is to say
  Java is missing, so it looks like a broken PATH — and it lands *after* the
  TypeScript tests pass, which reads as the tests having broken something. `sdk
  install java 21.0.12-tem` with SDKMAN. Only the emulator needs it.

## The dev seed

**It fills EVERY table, and health with it** (owner's rule). `DevSeedService`
covers attacks and their weather snapshots, medications, reminders, exports,
`DailyWeather` and `AppNotifications`. `SyncTombstones` is filled by *deleting* a
few of the rows it just wrote — the only way a tombstone is ever made.

- **Five rows, not a hundred** (owner's numbers): 5 attacks, 5 medications, 2
  reminders, 5 exports, in `DevSeedService.attackCount` and its siblings. A
  hundred answered "what does this look like full" and never "what does a real
  user's first month look like", and made every screenshot unreadable. The
  crowded-reminder medications went with it — at two reminders there is nothing
  to crowd.
- **Two shapes are forced rather than rolled**, because at five rows a
  per-row chance seeds nothing: exactly one attack is weatherless (the offline
  case the backfill queue exists for), and the rows the tombstone step deletes
  are written on top of the counts above, so no list is left short. What the seed
  can no longer promise is a spread of every enum value — the tests assert what
  holds at any size, not the RNG.
- **`DailyWeather` is what changes what you can see.** It is the correlation's
  denominator (hard rule `DailyPressure`), so without it the pressure card can only say "what share of my
  attacks fell during drops" and never "am I more likely to attack when it
  drops". Seeded days that ended in an attack are biased to drop, so
  `PressureBaseline` has two sides that differ.
- **Notification ids come from the real derivers**
  (`AppNotification.reminderOccurrenceId` / `.pressureAlertId`), never a UUID: a
  random id is a row no real writer could match, which is what hard rule 16's
  idempotence depends on.
- **Apple Health is NOT seeded** (owner's call). HealthKit is read-only and
  nothing it returns is persisted, so there is no table to fill — and the
  `DevSeededHealthRepository` that stood in for it is **gone**, with
  `devHealthSeedProvider` and `PrefsKeyConstant.devHealthSeed`. It generated
  nights and steps on the Simulator, where real reads come back empty, so a dev
  build could be showing invented sleep — harder to trust than an honest empty
  card. **Health is the one source the app does not own, so it is the one the
  seed does not invent**; check those cards on a device.
  `healthRepositoryProvider` therefore has no branch in it: it is
  `HealthKitRepository`, always.

## Writing a script

**Every script's body lives in `tool/<name>.sh`; `melos.yaml` only names it.**
Melos echoes the whole `run:` block before and after each run with no flag to
turn it off, so a multi-line body buries the output it introduces — and a file is
the only version that can be linted and run directly. Adding a command is a
`tool/*.sh` plus one line in `melos.yaml`.

They are **POSIX sh, not bash**: melos runs them through `/bin/sh`, which is dash
on Linux, where `set -o pipefail`, `[[ ]]` and `local` are syntax errors. macOS
will not catch this — its `/bin/sh` is bash under another name — so check with
`dash -n tool/<name>.sh`.

`tool/_common.sh` is sourced by all of them and holds what they share: the SDK
resolution (`fvm flutter` when `.fvmrc` and fvm are both present, plain `flutter`
otherwise — a shell alias is invisible inside a script) and
`step`/`warn`/`done_msg`.
