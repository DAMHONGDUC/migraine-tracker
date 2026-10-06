# The task runner — porting it to another app

The commands are not this repo's code. Scripts, make targets and the iOS lanes
live in [script-tools](https://github.com/DAMHONGDUC/script-tools) under
`flutter/`; this repo only includes them. `docs/rules/COMMANDS.md` carries the
reasoning per command. **The full checklist for another project is
`packages/script-tools/flutter/ADOPTION_SPEC.md`.**

## Standing it up

| # | Step | Example |
|---|---|---|
| 1 | Add the submodule under `packages/` | `git submodule add -b main https://github.com/DAMHONGDUC/script-tools packages/script-tools` |
| 2 | Two-line root `Makefile` | `SCRIPT_TOOLS := packages/script-tools` then `include $(SCRIPT_TOOLS)/flutter/flutter.mk` |
| 3 | Flavors other than `dev prod` | `script-tools.properties` at the root: `FLAVORS=dev staging prod` |
| 4 | iOS lanes | `ios/fastlane/Fastfile`: `import "../../packages/script-tools/flutter/fastlane/Fastfile"` + `sd_ios_app(...)` |
| 5 | CI | `submodules: recursive`, then `bash packages/script-tools/flutter/<script>.sh` |

`make` lists the targets: `make release-dev` runs
`flutter/release_ios.sh dev` → `prepare_env.sh dev` (6 files from
`env_assets/`) → `deploy_firebase.sh dev` → `fastlane beta flavor:dev`.

## Rules that keep the set small

| Rule | Why |
|---|---|
| A new command is a script in script-tools plus one line in `flutter.mk` | Every app gets the fix; no app carries a private fork of a shared script. |
| Flavor is part of the target name (`deploy-prod`), never a flag or default | A prod deploy is typed on purpose. |
| A step the app lacks is skipped by name, never failed (no `.firebaserc` → no deploy) | One script set serves apps with and without a backend. |
| App-specific facts live in the app (`sd_ios_app`, `script-tools.properties`, `env_assets/`) | The scripts name no app. |
