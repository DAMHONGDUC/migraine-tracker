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

`set-up` restores submodules, dependencies, generated code and native setup. It
also creates missing key-only files from `env/*.example.json`.

Real configuration is gitignored. Put local source files in `env_assets/`, then
install one environment:

```bash
melos run prepare-env-dev
# or
melos run prepare-env-prod
```

Never print or commit files from `env/`, `env_assets/`,
`ios/Flutter/Generated.xcconfig` or native Firebase configuration.

## Daily commands

| Command | Purpose |
|---|---|
| `melos run set-up` | Clean and restore a normal checkout |
| `melos run deep-set-up` | Also clear Xcode DerivedData |
| `melos run prepare-env-dev` | Install development configuration |
| `melos run prepare-env-prod` | Install production configuration |
| `melos run gen` | Generate localization and Drift code |
| `melos run analyze` | Run the CI analyzer with zero findings allowed |
| `flutter run --dart-define-from-file=env/dev.json` | Run the development app |

Run only tests related to the change:

```bash
flutter test test/features/<feature>/<test_file>_test.dart
```

Do not use the full test suite as change verification.

## Release

One command per environment. Each installs that environment's configuration,
deploys its Firebase side, then builds and uploads to TestFlight.

```sh
melos run release-dev
```

```sh
melos run release-prod
```

The Firebase deploy still names the project and asks before it runs, and the
build number is bumped in `pubspec.yaml` — commit it after the upload.

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
| `tool/` | Scripts called by Melos |

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
