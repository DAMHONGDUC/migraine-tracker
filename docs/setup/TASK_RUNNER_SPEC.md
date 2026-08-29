# The task runner — every command, and the rules behind the set

The full command surface of this repo, written to be rebuilt in another one.
`docs/rules/COMMANDS.md` is the in-repo authority and carries the reasoning per
command; this file is the *shape of the set* — what exists, what each one
promises, and the conventions that keep them all the same.

Release and env commands appear here only as entries in the table; their
contracts live in `ENV_AND_FASTLANE_SPEC.md` beside this file.

---

## The set

Eleven commands, no more. Every one of them is `melos run <name>`, and every
body is a file in `tool/`.

| Command | Script | Promise |
|---|---|---|
| `set-up` | `set-up.sh` | Wipe, then everything a fresh clone needs. Idempotent. |
| `deep-set-up` | `deep-set-up.sh` | `set-up` plus the IDE's native module cache. Costs a cold build. |
| `prepare-env-dev` | `prepare-env.sh dev` | Install dev's config — env files, native files, `functions/.env`. |
| `prepare-env-prod` | `prepare-env.sh prod` | The same, prod's files. |
| `gen` | `gen.sh` | Localizations + codegen, nothing else. |
| `analyze` | `analyze.sh` | Zero findings, or fail. What CI runs. |
| `test` | `test.sh` | The test suite. |
| `build-ipa-dev` | `build-ipa.sh dev` | The IPA, dev config attached. |
| `build-ipa-prod` | `build-ipa.sh prod` | The IPA, prod config attached. |
| `deploy-firebase-dev` | `deploy-firebase.sh dev` | Rules, indexes and functions to the dev alias. |
| `deploy-firebase-prod` | `deploy-firebase.sh prod` | The same, prod alias. |

Three shapes recur, and they are the pattern to copy:

1. **A flavor is a separate command, never a flag on a shared one.** `-dev` and
   `-prod` are typed on purpose; a prod deploy inherited from whatever the CLI
   was last pointed at is the failure this prevents.
2. **One script serves both flavors**, taking the flavor as `$1`. The runner
   entry is the only thing that is duplicated.
3. **Underscore-prefixed files are not commands.** `_common.sh`, `_clean.sh` —
   sourced or called by others, never named in the runner config.

---

## What each one actually does

### `set-up` — the one answer to "it built yesterday and not today"

Ordered, and the order is the contract:

1. **Wipe, unconditionally** (`_clean.sh`): `flutter clean`, gradle dirs, iOS
   `Pods`/`Podfile.lock`/`.symlinks`/`ephemeral`. Unconditional is the whole
   point — a clean that has to be *decided* is one nobody runs.
2. **Submodules onto their branch**, not the pinned commit: read
   `submodule.<name>.branch` from `.gitmodules`, checkout, `pull --ff-only`,
   and report per submodule when either step fails instead of dying.
3. Dependencies for the root package and each sub-package.
4. Localizations, then codegen.
5. **Env templates**: copy `env/<flavor>.example.json` → `env/<flavor>.json`
   for each missing one, collect the names, and warn loudly at the end.
6. Backend dependencies (`npm ci`) when that folder exists.
7. Pods, on macOS only, when a `Podfile` exists.

Two details that are not cosmetic:

- **Force a UTF-8 `LANG` before running CocoaPods.** Ruby without one reads the
  Podfile as ASCII-8BIT and dies inside its own error reporter, on a trace that
  names the encoding and never the missing locale. Force it, do not default it:
  `LANG=C` breaks identically and only an *unset* one gets caught by a default.
- **Fold pod's stderr into stdout** (`pod install 2>&1`). Melos labels every
  stderr line `ERROR:`, so an otherwise clean run reads as a failed one.
  `set -e` still stops on a real failure.

The submodule choice has a price, so state it where people read it: after this,
what you build is whatever is on the submodule's branch, **not** what the parent
commit pins, and a past parent commit no longer rebuilds byte-for-byte.

### `deep-set-up` — the second entry point, and the last one

Sets one variable, then calls `set-up`. `_clean.sh` reads it and additionally
clears the IDE's derived data.

**Why it is separate**: Xcode caches precompiled modules against the modulemap
it saw at the time, so bumping a native plugin leaves a `.pcm` that no
`flutter clean` can reach — `has been modified since the module file was built`.
Clearing it fixes that and costs a full cold build, which is exactly the
trade that must stay opt-in.

**Match the cache on the recorded workspace path, never the folder name.** Every
Flutter app builds a target called `Runner`, so a `Runner-*` glob deletes other
projects' caches.

**Do not add a third clean-shaped command.** Two entry points, and `gen` for
"all I changed is a table or a string".

### `gen` — the cheap one

Localizations + codegen, and nothing else. It exists so that `set-up` never
becomes the reflex for a one-line change.

### `analyze` — the gate

`flutter analyze --fatal-infos`, every package. **Zero findings before any task
is done**, and it must be byte-for-byte what CI runs — a gate that differs from
CI is a gate that passes and then fails.

### `test`

The suite, for CI. Locally, **never run the whole suite to verify a change**:
scope to the file that changed. The command exists for CI and for the rare full
sweep, not as a per-change habit.

### `prepare-env-*` and `build-ipa-*`

See `ENV_AND_FASTLANE_SPEC.md` — Part A2 and Part B2.

### `deploy-firebase-*` — the one that reaches real users

The environment is a **CLI alias** (`.firebaserc`), not an env JSON file: the
alias resolves to a project id, and the project id is what picks the functions'
own config and secrets. Naming the environment is the whole of the switch.

Its contract, in order:

1. Validate the flavor, and an optional target (`rules` | `functions` | both).
2. **Resolve the alias to a project id from `.firebaserc` yourself**, so the
   prompt can name the project *before* anything is sent, and so a missing
   alias fails with the command that creates it rather than a CLI error naming
   neither.
3. **Warn when dev and prod resolve to the same project.** Until they are split,
   `deploy-firebase-dev` is a production deploy wearing another name — the one
   thing the alias in the prompt would otherwise hide.
4. **Confirm interactively**, reading from `/dev/tty` with a fallback: the
   runner pipes stdout but leaves stdin alone, and `/dev/tty` is the descriptor
   that survives a redirected invocation.
5. **Build and test the functions before deploying them.** Deploying a build
   that fails its own tests costs a second deploy to undo.
6. **Pass `--project` on every deploy; never run `firebase use` first.** `use`
   leaves the developer's shell pointed at whatever the script deployed last,
   so their next bare `firebase deploy` goes there silently.
7. Rules and indexes deploy **together**: a missing composite index fails at
   runtime, not at build.

---

## The conventions

### Every body is a file; the runner config only names it

Melos echoes the whole `run:` block before **and** after each run, with no flag
to turn it off, so a multi-line body buries the output it introduces. A file is
also the only version that can be linted and run directly. **Adding a command is
a `tool/*.sh` plus one line in `melos.yaml`** — a `run:` that is longer than one
line is the smell.

### POSIX sh, not bash

Melos runs scripts through `/bin/sh`, which is dash on Linux: `set -o pipefail`,
`[[ ]]` and `local` are syntax errors there. **macOS will not catch it** — its
`/bin/sh` is bash under another name. Check with `dash -n tool/<name>.sh`.

Every script opens the same way:

```sh
#!/bin/sh
set -eu
. "$(dirname "$0")/_common.sh"
```

### `tool/_common.sh` holds what they share

- `cd "${MELOS_ROOT_PATH:-.}"` — every path in every script is repo-relative.
- **SDK resolution**: `fvm flutter` when `.fvmrc` and `fvm` are both present,
  plain `flutter` otherwise, exported as `$FL` / `$DT`. A shell alias does not
  exist inside a script, so without this a machine using a version manager
  silently runs the wrong SDK.
- `step` / `warn` / `done_msg`, colour-coded.
- **Emit colour unconditionally unless `NO_COLOR` is set.** Melos hands every
  script a piped stdout *and* `TERM=dumb` even on a real terminal, so `[ -t 1 ]`
  and a `TERM` check both mean "never colour at all". Melos passes ANSI through
  and CI renders it.

### Pin the runner exactly, and know why you are on that major

`dart pub global activate melos 6.3.3` — exact, not caret. This repo stays on 6
deliberately: 7+ moves to pub workspaces, which (a) drags in a dependency set
that cannot resolve against this codegen version without pinning the codegen
from the task runner, and (b) requires `resolution: workspace` inside the shared
package, which stops it resolving in any project that is not itself a workspace
— exactly the portability the submodule exists for. Write that reason down; a
version pin with no recorded reason is one the next session "upgrades".

Also `ide: intellij: false` if the pinned version ships without the run-config
templates it tries to write, and nothing uses them.

---

## Porting checklist

1. `melos.yaml`: name, packages globs, `scripts:` with one-line bodies and a
   real `description:` each — the description is what `melos run` prints.
2. `tool/_common.sh` first: root cd, SDK resolution, the three printers.
3. `tool/_clean.sh`, then `set-up.sh` and the one-variable `deep-set-up.sh`.
4. `gen.sh`, `analyze.sh`, `test.sh` — three files, five lines each.
5. Flavored pairs last (`prepare-env`, `build-ipa`, `deploy-firebase`): one
   script taking `$1`, two runner entries.
6. `dash -n tool/*.sh` before committing any of them.
7. Document the set in one `docs/rules/COMMANDS.md` and nowhere else; the README
   gets a table of names, never a second explanation.
