# BaroEase

Migraine tracker with barometric pressure alerts. Flutter, iOS first.

See `CLAUDE.md` for architecture and `PLAN.md` for the product spec.

## Getting started

Clone with submodules — the design system lives in one:

```bash
git clone --recurse-submodules <url>
cd migraine_tracker
```

Already cloned without them? `git submodule update --init --recursive` (or
just run setup below, which does it for you).

Install the task runner once per machine, at the version this repo pins:

```bash
dart pub global activate melos 6.3.3
```

Then one command does the rest:

```bash
melos run setup
```

That fetches submodules, resolves both packages, generates localizations and
Drift code, lays down `env/*.json` from the templates, installs the Cloud
Functions dependencies, and — on macOS — runs `pod install` for the one
plugin that still needs CocoaPods. It is safe to re-run at any time.

**One thing setup cannot do for you:** `env/dev.json` and `env/prod.json`
hold Firebase and RevenueCat keys and are gitignored, so a fresh clone gets
key-only templates copied from `env/*.example.json`. Fill them in before
running the app — setup says so loudly when it creates them.

## Commands

| Command | What it does |
| --- | --- |
| `melos run setup` | Everything a fresh clone needs. Idempotent. |
| `melos run gen` | Regenerate localizations + `build_runner` output. |
| `melos run analyze` | Analyze every package, zero warnings (what CI runs). |
| `melos run test` | The Flutter test suite. |
| `melos run clean` | Wipe Android + iOS build artefacts. Follow with `setup`. |

Run the app:

```bash
flutter run --dart-define-from-file=env/dev.json
```

The VS Code launch configs already pass that flag (dev → `env/dev.json`,
prod → `env/prod.json`).

## Layout

```
lib/                      the app
packages/system_design/   the design system — its own repo, a git submodule
functions/                Firebase Cloud Functions (TypeScript)
```

The design system is deliberately separate and deliberately ignorant of this
app; see `packages/system_design/WIDGET_RULES.md` before adding to it.
