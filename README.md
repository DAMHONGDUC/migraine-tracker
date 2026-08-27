# BaroEase

Migraine tracker with barometric pressure alerts. Flutter, iOS first.

See `CLAUDE.md` for architecture and `PLAN.md` for the product spec.

## Getting started

Clone with submodules — the design system lives in one:

```bash
git clone --recurse-submodules <url>
cd migraine_tracker
```

Already cloned without them? `git submodule update --init --recursive`, or just
run setup below, which does it for you.

Install the task runner once per machine, at the version this repo pins:

```bash
dart pub global activate melos 6.3.3
```

Then one command does the rest:

```bash
melos run set-up
```

It wipes build artefacts first — `flutter clean`, gradle, pods — then fetches
submodules, resolves both packages, generates localizations and Drift code, lays
down `env/*.json` from the templates, installs the Cloud Functions dependencies
and, on macOS, runs `pod install` for the one plugin that still needs CocoaPods.
Safe to re-run at any time.

**The wipe is unconditional on purpose**: setup is the one answer to "it built
yesterday and not today". Use `melos run gen` when all you changed is a table or
a string. When even setup does not help — Xcode refusing a precompiled module, a
header resolving to a version you no longer depend on, a failure that comes and
goes on one commit — use `melos run deep-set-up`, which adds Xcode's DerivedData.
It is separate because clearing that cache costs a full cold build every time.

**Submodules follow their branch, they are not pinned.** Setup checks the design
system out on `main` (the branch named in `.gitmodules`) and fast-forwards it, so
you can edit it in place — but what you build is whatever is on `main`, not what
this repo's commit records. When `main` moves ahead, git shows
`packages/system_design` as modified: commit that gitlink when you mean to.

**The Firebase emulator needs a JDK** (11+) on your PATH — the Firestore emulator
is a Java program, and macOS ships a `/usr/bin/java` stub whose only job is to
say Java is missing, so it looks like a PATH problem rather than a missing
install. `sdk install java 21.0.12-tem` with SDKMAN, or a JDK from anywhere else.
Nothing but the emulator needs it.

**One thing setup cannot do for you:** `env/dev.json` and `env/prod.json` hold
Firebase and RevenueCat keys and are gitignored, so a fresh clone gets key-only
templates from `env/*.example.json`. Fill them in before running the app — setup
says so loudly when it creates them.

Already keep the real files? Put them in a gitignored `env_assets/` folder
(`dev.json`, `prod.json`, `dev-`/`prod-google-services.json`,
`dev-`/`prod-GoogleService-Info.plist`, `dev-`/`prod-Info.plist`) and
`melos run prepare-env-dev` copies them where the build looks: both
`env/*.json`, plus that environment's `android/app/google-services.json`,
`ios/Runner/GoogleService-Info.plist` and `ios/Runner/Info.plist`.
`prepare-env-prod` installs the prod trio instead. It overwrites — that is how
you switch a checkout between the two. `Info.plist` is tracked, so switching
environments shows in `git status`.

## Commands

| Command | What it does |
| --- | --- |
| `melos run set-up` | Wipe build artefacts, then everything a clone needs. Idempotent. |
| `melos run prepare-env-dev` | Copy `env_assets/` into place for dev — env + native files. |
| `melos run prepare-env-prod` | The same, with prod's native files. |
| `melos run gen` | Regenerate localizations + `build_runner` output. |
| `melos run analyze` | Analyze every package, zero warnings (what CI runs). |
| `melos run test` | The Flutter test suite. |
| `melos run deep-set-up` | Setup, plus Xcode's DerivedData. Costs a cold build. |
| `melos run build-ipa-prod` | The TestFlight/App Store IPA, config flag attached. |
| `melos run build-ipa-dev` | The same IPA with `env/dev.json` attached instead. |

Run the app:

```bash
flutter run --dart-define-from-file=env/dev.json
```

The VS Code launch configs already pass that flag (dev → `env/dev.json`, prod →
`env/prod.json`).

**Never archive from Xcode.** Product > Archive knows nothing about
`--dart-define-from-file`, so the build ships with empty Firebase and RevenueCat
config and crashes on launch with `[core/no-app] No Firebase App '[DEFAULT]' has
been created` — which names nothing to do with the missing flag. Use `melos run
build-ipa-prod`, then upload the `.ipa` it leaves in `build/ios/ipa/`.

Releasing to TestFlight is normally the manually-triggered **Release iOS**
workflow in GitHub Actions, which builds with that same script and uploads
through fastlane. To run the same lane from your own Mac, see below.

## Fastlane, locally

One-time, per machine:

```bash
cd ios
bundle config set --local path vendor/bundle
bundle install
```

**The local path is not optional on a Homebrew Ruby**: its gem files are
read-only, so a plain `bundle install` dies on `Permission denied @ rb_sysopen …
rdoc_plugin.rb`. `ios/.bundle/` and `ios/vendor/` are gitignored — CI pins its
own Ruby through `ruby/setup-ruby` and resolves gems its own way.

Credentials live in `ios/fastlane/.env` (gitignored, six keys). Check its shape
without printing any values: `cut -d= -f1 ios/fastlane/.env`. How each one is
made: `docs/release/CREDENTIALS.md`.

| Command | What it does |
| --- | --- |
| `cd ios && CI=true bundle exec fastlane preflight` | Rehearse the release without building — API key, build number, `match`. Three minutes, not twenty-eight. |
| `cd ios && bundle exec fastlane beta flavor:prod` | Build with `env/prod.json`, sign, export, upload to TestFlight. |
| `cd ios && bundle exec fastlane beta flavor:dev` | The same, with `env/dev.json` attached instead. |
| `cd ios && bundle exec fastlane beta flavor:prod bump:false` | Ship the build number already in `pubspec.yaml`, unchanged. |
| `cd ios && bundle exec fastlane certificates` | Create or renew the distribution certificate and both profiles. Mac only. |
| `cd ios && bundle exec fastlane certificates force:true` | Regenerate the profiles — the only way a newly-enabled capability reaches CI. |

Three things differ from the CI run:

- **`CI=true` on `preflight` is the point.** Without it the lane skips `match`,
  the half most likely to break.
- **`match` and manual signing are skipped locally** — your Mac signs
  automatically and never touches the shared certificate.
- **`bump:true` (the default) rewrites `pubspec.yaml` but does not commit it.**
  Only CI commits the number back, so commit it yourself after the upload — or a
  build sits on TestFlight whose version is in no commit, the one thing the
  build-number rule exists to prevent.

**If codesign asks for keychain permission, the export has already failed.** The
prompt — *"codesign wants to access key \"Apple Distribution: …\" in your
keychain"* — is raised at `exportArchive`, after the archive is built, so a lane
that dies there has spent its whole four minutes. `Always Allow` clears it for
one key; the permanent fix hands codesign the whole login keychain once:

```bash
security unlock-keychain ~/Library/Keychains/login.keychain-db
security set-key-partition-list -S apple-tool:,apple:,codesign: -s \
  -k "$(read -rs -p 'login password: ' p; echo "$p")" \
  ~/Library/Keychains/login.keychain-db
```

It is your Mac's login password, typed into your own terminal — nothing here
stores it, and CI never runs this (its keychain is the throwaway one `setup_ci`
makes).

If `security find-identity -v -p codesigning` shows the same "Apple Distribution"
several times, that is a keychain an older `CI=true preflight` left in the search
list. `setup_ci` is gated on a real runner now, so no new one appears, but an
existing one has to be cleared by hand:

```bash
security list-keychains -d user -s ~/Library/Keychains/login.keychain-db
security default-keychain -s ~/Library/Keychains/login.keychain-db
security delete-keychain ~/Library/Keychains/fastlane_tmp_keychain-db
```

The first line rewrites the whole user search list, so `login.keychain-db` has to
be named in it or nothing signs afterwards — **and it clears the default
keychain, which is what the second line puts back.** Without it, `security
default-keychain` answers *"A default keychain could not be found"* and Xcode
logs `DVTDeveloperAccountManager: Failed to load credentials … Code=-25307`, so
automatic signing can no longer refresh a profile.

Both flavors go to the **same** TestFlight app: one bundle id serves both, so the
build number is the only thing telling a dev build from a prod one. Full detail
in `docs/rules/COMMANDS.md`; the pipeline as a diagram is
`docs/release/PIPELINE.md`.

## Layout

```
lib/                      the app
packages/system_design/   the design system — its own repo, a git submodule
functions/                Firebase Cloud Functions (TypeScript)
tool/                     what the melos commands actually run
```

`melos.yaml` only names each command; the body is a POSIX `sh` script in `tool/`.
Melos echoes a `run:` block twice per run, so anything longer than one line
drowns its own output.

**This app renders design system generation `v2`.** One generation belongs to one
product, so nothing else imports `v2/` and a change there can only reach this app
— but only while this line stays accurate, because the gitlink records the commit
pinned, never the folder imported. Move it in the same change as any generation
move.

The design system is deliberately separate and deliberately ignorant of this app;
see `packages/system_design/WIDGET_RULES.md` before adding to it.

## Sync

Signing in backs up attacks, medications and their reminders to the account and
keeps them in step across devices. An account is optional: everything else works
without one, and the on-device database stays the source of truth — the cloud
copy is a copy, never the only one. Past exports deliberately stay out of it:
their file paths belong to one device.

It never blocks the UI. Sync runs in the background on sign-in, launch, resume
and after logging an attack, and a pass that fails leaves the work for the next
one. The one visible control is a row in Settings' "Your data", which runs a sync
on tap and shows how the last one went.

Records are encrypted with AES-GCM before they leave the device, so no intensity,
note or medication name reaches Firestore readable. **This is not end-to-end
encryption:** the key is minted and held by the `getSyncKey` Cloud Function, so
the backend can decrypt. The in-app copy therefore says "encrypted" and never
"only you can read this" — hold any new wording to that bar.

Nothing syncs until `firestore.rules` and `functions/` are deployed. Until then
the app behaves exactly as it did before sync existed.

## rm icon marker

dart run tool/strip_icon_marker.dart assets/images/app_icon_v3.png assets/images/final_app_icon.png

dart run flutter_launcher_icons

## build app to tesflight (local)

melos run prepare-env-dev

cd ios && bundle exec fastlane beta flavor:dev

=======

melos run prepare-env-prod

cd ios && bundle exec fastlane beta flavor:prod