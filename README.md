# BaroEase

An iOS-first Flutter app for tracking migraines and barometric-pressure risk.
It works offline, uses dark mode by default and supports seven languages.

| Document | Use it for |
|---|---|
| [`PLAN.md`](PLAN.md) | Product scope and architecture |
| [`AGENTS.md`](AGENTS.md) | Repository rules and document routing |
| [`docs/README.md`](docs/README.md) | Documentation index |
| [`docs/DONE_WORK.md`](docs/DONE_WORK.md) | What is built |
| [`docs/REMAINING_WORK.md`](docs/REMAINING_WORK.md) | What still blocks release |

## Requirements

| Tool | Requirement |
|---|---|
| Flutter | Stable, Dart 3 |
| Melos | `6.3.3` |
| Xcode | iOS build and signing |
| Ruby 3.x + Bundler | Fastlane release only |
| JDK 11+ | Firebase emulator only |

## Setup

```bash
git clone --recurse-submodules <url>
cd migraine_tracker
dart pub global activate melos 6.3.3
melos run set-up
```

`--recurse-submodules` is not optional. Every Melos script lives in
`packages/system_design/tool/`, inside the design-system submodule, so a clone
without it has no `set-up.sh` to run — recover with `git submodule update --init
--recursive`.

`set-up` restores submodules, dependencies, generated code and native setup. It
also creates missing key-only files from `env/*.example.json`.

Real configuration is gitignored. Put local source files in `env_assets/`, then
install one environment:

```bash
sh packages/system_design/tool/prepare-env.sh dev
# or
sh packages/system_design/tool/prepare-env.sh prod
```

A release does this itself, so this is only for switching a checkout by hand.

Never print or commit files from `env/`, `env_assets/`,
`ios/Flutter/Generated.xcconfig` or native Firebase configuration.

## Commands

Melos carries eight commands, and they are the ones a human types.

| Command | Purpose |
|---|---|
| `melos run set-up` | Clean and restore a normal checkout |
| `melos run deep-set-up` | Also clear Xcode DerivedData |
| `melos run release-dev` | Full dev release: set up, config, checks, deploy, TestFlight |
| `melos run release-prod` | The same against production |
| `melos run deploy-firebase-dev` | Rules, indexes and functions to dev |
| `melos run deploy-firebase-prod` | The same against production |
| `melos run upload-ipa-dev` | Re-upload the built IPA when only the upload failed |
| `melos run upload-ipa-prod` | The same against production |

Everything else is a script in `packages/system_design/tool/`, run by the
command that needs it or by hand.

| Script | Purpose |
|---|---|
| `sh packages/system_design/tool/gen.sh` | Generate localization and Drift code |
| `sh packages/system_design/tool/analyze.sh` | The CI analyzer, zero findings allowed |
| `sh packages/system_design/tool/test.sh` | The full test suite |
| `sh packages/system_design/tool/pre-build.sh` | The release gate, one ✓/✗ per check |
| `sh packages/system_design/tool/prepare-env.sh <dev\|prod>` | Install one environment's configuration |
| `sh packages/system_design/tool/build-ipa.sh <dev\|prod>` | Build the IPA and nothing else |
| `flutter run --dart-define-from-file=env/dev.json` | Run the development app |

Run only tests related to the change:

```bash
flutter test test/features/<feature>/<test_file>_test.dart
```

Do not use the full test suite as change verification.

## Release

One command per environment, five steps: set up, install that environment's
configuration, run the pre-build gate, deploy its Firebase side, then build and
upload to TestFlight.

```sh
melos run release-dev
```

```sh
melos run release-prod
```

The Firebase deploy still names the project and asks before it runs, and the
build number is bumped in `pubspec.yaml` — commit it after the upload.

If the build succeeded and only the upload failed, re-send the IPA already on
disk instead of building again:

```sh
melos run upload-ipa-dev
```

See [`docs/release/PIPELINE.md`](docs/release/PIPELINE.md) for the flow and
[`docs/release/CREDENTIALS.md`](docs/release/CREDENTIALS.md) for required keys.

## Project map

| Path | Ownership |
|---|---|
| `lib/core/` | Cross-cutting infrastructure only |
| `lib/features/` | Feature-based app code |
| `lib/l10n/` | Seven ARB localization files |
| `functions/` | Firebase Cloud Functions |
| `packages/system_design/` | Design-system git submodule |
| `test/features/` | Tests mirroring app features |
| `packages/system_design/tool/` | Scripts called by Melos |

Dependencies inside a feature point `presentation → domain ← data`. Across
features, import only `domain/` or `providers.dart`.

## App identifiers

| Target | Identifier |
|---|---|
| iOS app | `app.dd.migraine.tracker` |
| iOS widget | `app.dd.migraine.tracker.BaroEaseWidgetExtension` |
| iOS App Group | `group.app.dd.migraine.tracker` |
| Android app | `com.dd.migraine.tracker` |

The iOS and Android identifiers intentionally differ. Do not normalize them.

## Core behavior

| Area | Rule |
|---|---|
| Storage | Drift on-device is the source of truth |
| Attack log | Fully usable offline; weather is best-effort |
| Account | Optional; Google/Apple upgrades the anonymous UID |
| Sync | AES-GCM encrypted, server-assisted, not end-to-end encrypted |
| Weather | WeatherKit is called only by Cloud Functions |
| Premium | RevenueCat entitlement is the only access source |
| Theme | Dark mode is the default; no pure-white or flashing UI |
