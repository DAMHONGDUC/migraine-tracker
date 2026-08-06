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
melos run set-up
```

That wipes build artefacts first — `flutter clean`, gradle, pods — then
fetches submodules, resolves both packages, generates localizations and Drift
code, lays down `env/*.json` from the templates, installs the Cloud Functions
dependencies, and — on macOS — runs `pod install` for the one plugin that
still needs CocoaPods. It is safe to re-run at any time.

The wipe is unconditional on purpose: setup is the one answer to "it built
yesterday and not today". Use `melos run gen` when all you changed is a table
or a string.

When even that does not help — Xcode refusing a precompiled module, a header
resolving to a version you no longer depend on, a failure that comes and goes
on one commit — use `melos run deep-set-up`, which is the same thing plus
Xcode's DerivedData. It is separate because clearing that cache costs a full
cold build every time.

**Submodules follow their branch, they are not pinned.** Setup checks the
design system out on `main` (the branch named in `.gitmodules`) and
fast-forwards it, instead of leaving it detached at the commit this repo
records. So you can edit it in place without remembering to check out a
branch first — but what you build is whatever is on `main`, not what the
parent commit pins. When `main` moves ahead, git shows
`packages/system_design` as modified: commit that gitlink when you mean to.

**One thing setup cannot do for you:** `env/dev.json` and `env/prod.json`
hold Firebase and RevenueCat keys and are gitignored, so a fresh clone gets
key-only templates copied from `env/*.example.json`. Fill them in before
running the app — setup says so loudly when it creates them.

## Commands

| Command | What it does |
| --- | --- |
| `melos run set-up` | Wipe build artefacts, then everything a clone needs. Idempotent. |
| `melos run gen` | Regenerate localizations + `build_runner` output. |
| `melos run analyze` | Analyze every package, zero warnings (what CI runs). |
| `melos run test` | The Flutter test suite. |
| `melos run deep-set-up` | Setup, plus Xcode's DerivedData. Costs a cold build. |

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
tool/                     what the melos commands actually run
```

`melos.yaml` only names each command; the body is a POSIX `sh` script in
`tool/`. Melos echoes a `run:` block twice per run, so anything longer than
one line drowns its own output.

The design system is deliberately separate and deliberately ignorant of this
app; see `packages/system_design/WIDGET_RULES.md` before adding to it..

## Attack sync

Signing in backs up attack history to the account and keeps it in step
across devices. An account is optional: everything else works without one,
and the on-device database stays the source of truth — the cloud copy is a
copy, never the only one.

It never blocks the UI. Sync runs in the background on sign-in, launch,
resume and after logging an attack, and a pass that fails just leaves the
work for the next one. The Account screen is the only place it is visible in
full, with a "Sync now" button for a deliberate retry.

Attacks are encrypted with AES-GCM before they leave the device, so no
intensity, note or medication name reaches Firestore readable. **This is not
end-to-end encryption:** the key is minted and held by the `getSyncKey`
Cloud Function, so the backend can decrypt. The in-app copy therefore says
"encrypted" and never "only you can read this" — hold any new wording to
that bar.

Nothing syncs until `firestore.rules` and `functions/` are deployed. Until
then the app behaves exactly as it did before sync existed.
