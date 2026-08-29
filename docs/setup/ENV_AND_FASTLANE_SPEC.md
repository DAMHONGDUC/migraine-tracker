# Env config + fastlane — the spec, portable to a new project

What to rebuild, in what order, and which properties must hold. Written to be
read from another repo: the values here are BaroEase's, the rules are not
about BaroEase. The reasoning behind each rule stays where it already lives —
`docs/rules/COMMANDS.md`, `docs/release/CREDENTIALS.md`,
`docs/release/PIPELINE.md` — and this file is the shape.

Two halves, and they are independent: env config is what a build carries,
fastlane is what happens to the build afterwards. Half one works alone; half
two is useless without it.

---

## Part A — Env config

### A1. The two kinds of config, and why they are separate

| Kind | Reaches the app by | Files |
|---|---|---|
| Dart-visible values | `--dart-define-from-file=env/<flavor>.json` | `env/dev.json`, `env/prod.json` |
| Native SDK config | Read by the platform at build time | `ios/Runner/GoogleService-Info.plist`, `android/app/google-services.json`, `ios/Runner/Info.plist` |

**Nothing ties the two together**, and that is the central hazard of the whole
system: `env/prod.json` beside a *dev* `GoogleService-Info.plist` compiles,
installs, launches, and writes into the wrong Firestore. Every guard in Part B
exists because of this one gap.

`ios/Runner/Info.plist` is in the list because it carries the Google sign-in
URL scheme — the reversed client id of one Firebase project. Wrong flavor: the
Google sheet opens and the callback never arrives.

### A2. `env_assets/` — the local source of truth

A gitignored folder holding your own copies, one set per flavor:

```
env_assets/
  dev.json                          prod.json
  dev-google-services.json          prod-google-services.json
  dev-GoogleService-Info.plist      prod-GoogleService-Info.plist
  dev-Info.plist                    prod-Info.plist
  dev-function.env                  prod-function.env
  fastlane.env                      (one, both flavors)
```

`tool/prepare-env.sh <dev|prod>` copies them where the build reads them. Its
contract:

1. **Both `env/*.json` and `fastlane.env` every run**; the other four are
   flavor-picked. One destination each, so there is nothing to choose.
   - `fastlane.env` → `ios/fastlane/.env` carries no flavor because the six
     credentials in it do not have one: one bundle id, one match repo, one App
     Store Connect key serve both environments.
   - `<flavor>-function.env` lands on `functions/.env`, the Cloud Functions
     config the Firebase CLI reads **at deploy time** — `WEATHERKIT_*` and
     `PREMIUM_EMAIL`. Copying it changes nothing until the next deploy, which is
     why the script says so on the way out.
2. **Destinations carry no `dev-`/`prod-` prefix.** Those exact paths are what
   the google-services gradle plugin and the Runner target read; a prefixed
   copy beside them is a file nothing opens.
3. **Check every source first, copy after.** A run that dies on the third file
   leaves a tree half one environment and half the other, and nothing on disk
   says so.
4. **It copies bytes and never reads them.** Same rule as the agent's: secrets
   are not to be printed.
5. Two thin wrappers in the task runner: `prepare-env-dev`, `prepare-env-prod`.

### A3. `AppEnv` — the only place the environment is read

One `final class AppEnv` under `lib/core/env/`, holding every
`String.fromEnvironment`. Nothing else in the app may call it. What that buys:
the set of expected keys is self-documenting, and a renamed key is a one-line
fix.

**A key that belongs to one platform ends in `_IOS` or `_ANDROID`**, and its
getter ends in the same word — `FIREBASE_API_KEY_IOS` / `firebaseApiKeyIos`.
Suffix rather than infix, so the two halves of a pair sort together and the
platform is the last thing read on every line, which is the question asked when
a build carries the wrong one. No suffix means both platforms read it.

Three properties worth copying verbatim:

- **`missingConfigKeys`** — a getter listing every *required* key still empty,
  walked by one fail-loud assert in `main()`. One report of all gaps beats an
  assert per config group.
- **Required vs defaulted is a decision, not an accident.** Firebase ids and
  the current platform's store key are required; entitlement name, offering,
  support email, policy URL are defaulted, because empty is their normal
  state. The other platform's store key is allowed to be empty.
- **Asserts are stripped from release builds**, which is exactly where the
  mistake happens. The assert is a developer convenience; Part B's checks are
  the real guard.

### A4. The gitignore contract

```
env/*.json
!env/*.example.json
ios/Runner/GoogleService-Info.plist
android/app/google-services.json
env_assets/
functions/.env
!functions/.env.example
ios/fastlane/.env*
ios/fastlane/*.p8
```

**Commit key-only `*.example.json` templates.** They make "which keys exist"
answerable without any value being read, and setup copies them into place for
a fresh clone so the app at least builds and fails with a named key rather
than with a Firebase stack trace.

### A5. Setup

Exactly two entry points — `set-up` and `deep-set-up` (the latter also clears
the native build cache, which costs a cold build, hence separate). Setup
**wipes first, unconditionally**: it is the one answer to "it built yesterday
and not today". Its env step copies each missing `env/<flavor>.json` from its
template and says loudly which files it created.

---

## Part B — Fastlane

### B1. Files and what each one owns

| File | Owns |
|---|---|
| `ios/fastlane/Appfile` | Bundle id, team id. No `apple_id` — every lane authenticates with an App Store Connect API key, so no 2FA prompt a runner cannot answer. |
| `ios/fastlane/Matchfile` | The private certificates repo, `type("appstore")`, and **every** bundle id: app *and* app extensions. |
| `ios/Gemfile` | `fastlane`, plus `cocoapods` pinned to the version in `Podfile.lock` if any plugin still needs pods. |
| `ios/fastlane/.env` | The six local credentials, gitignored. |
| `ios/fastlane/Fastfile` | The three lanes below. |
| `tool/build-ipa.sh` | The build, and only the build. |

`ios/fastlane/.env`, six keys, values never printed — check its shape with
`cut -d= -f1 ios/fastlane/.env`:

```
ASC_KEY_ID= ASC_ISSUER_ID= ASC_KEY_FILEPATH=
MATCH_PASSWORD= MATCH_GIT_URL= MATCH_GIT_BASIC_AUTHORIZATION=
```

**The file must end with a newline**: `>>` appends bytes, not lines, so a
missing one turns the next appended variable into a suffix of the previous
value — and the symptom is "the previous variable is nonsense", not "variable
missing".

### B2. `build-ipa.sh` — fastlane never archives

The lane shells out to the same script a developer runs by hand. Non-negotiable,
because the app's config arrives through `--dart-define-from-file`, a flag
`xcodebuild`, `gym` and Xcode's Product > Archive all know nothing about. An
archive made by any of them carries empty config and dies at runtime on
`[core/no-app] No Firebase App '[DEFAULT]' has been created` — a crash naming
nothing to do with the missing flag.

The script also: fails early if `env/<flavor>.json` or the plist is missing
(existence only, never contents); **wipes `build/ios/ipa` before every build**,
so the glob afterwards matches exactly one file and it is the one just built;
and prints the version from the version file rather than accepting a
`--build-number` flag.

### B3. Lane `beta` — the order is the design

```
flavor:dev|prod   bump:true|false   notes:"one line for testers"
```

1. **`verify_flavor_config`** — read the project id out of the installed
   `GoogleService-Info.plist` and refuse unless it matches what `.firebaserc`
   gives for this flavor. Also checks the sign-in URL scheme and the
   Crashlytics app id. This is the last place the A1 hazard can be caught.
2. **Settle the build number before the build**: `max(version file, TestFlight)
   + 1`, written **into the version file**, never passed as a flag. Taken from
   TestFlight because App Store Connect refuses a number it has already seen
   for that version, on any branch. Without `bump`, a number already used is a
   hard error here rather than after twenty-five minutes.
3. **CI only**: `setup_ci` (gated on a *real runner*, see B5) → `match(readonly:
   true)` → **verify every entitlement the target claims is in the profile** →
   flip the project to manual signing for this checkout → write an
   ExportOptions.plist naming **every** target's profile.
4. **Build** via `build-ipa.sh`, passing that plist.
5. **Upload** with `skip_waiting_for_build_processing: true` — nothing in the
   lane reads the result and macOS minutes bill at 10x. A changelog still
   costs a couple of minutes because the note is the only thing on the build
   that says dev or prod.
6. **dSYMs, best effort** — the build is already up; a symbol failure must not
   take the build-number commit down with it.
7. **Commit the build number, after the upload.** A bump commit with no build
   is a gap in the numbering; a build whose number is in no commit is the thing
   the rule exists to prevent.

### B4. Lanes `preflight` and `certificates`

- **`preflight`** — everything a release depends on except the build: the API
  key, the build-number question, and (with `CI=true`) match and the
  entitlement check. Three minutes instead of twenty-eight, and every
  credential failure ever met surfaces in it. `flavor:` is optional and
  **skipped rather than defaulted** when absent: defaulting to prod would fail
  a rehearsal on a dev machine over the one question it was not asked.
- **`certificates`** — local only, because CI runs match `readonly: true`: a
  runner that can mint distribution certificates burns through Apple's limit of
  three, one failed job at a time. `force:true` regenerates the *profiles* (not
  the certificate) and is the only way a newly-enabled capability ever reaches
  CI — match reuses an existing profile otherwise, which is the trap behind
  every "profile doesn't include the … entitlement".

### B5. Three subtleties that cost real time

1. **`runner?` is not `is_ci`.** `is_ci` is true on a Mac rehearsing with
   `CI=true` — the very thing the docs tell people to run — and `setup_ci`
   there creates a throwaway keychain, adds it to the search list, and never
   removes it. The shared certificate then lives in two keychains and codesign
   starts prompting at `exportArchive`, after the whole build. Gate `setup_ci`
   on the CI provider's own variable.
2. **Multi-target export.** `flutter build ipa --export-method` generates an
   ExportOptions.plist mapping the main bundle id only — its own source calls
   multi-target apps a TODO. With automatic signing this never shows; with
   manual signing the extension gets no profile and `exportArchive` fails after
   the full build. Write the plist yourself with every id in it, and have the
   build script drop its own `--export-method` when a caller passes one.
3. **Delete the empty auth variable.** Actions sets every `${{ secrets.X }}` a
   workflow names, empty string included, and match reads *both* auth variables
   from the environment regardless of what the call site passes — giving
   `remote: Duplicate header: "Authorization"`. Choosing one in code is not
   enough; the empty one has to be removed from `ENV`.

---

## Part C — The release workflow

Manual `workflow_dispatch` only (inputs: flavor, bump, notes) — a release is an
act, not a side effect of a push. `runs-on: macos-15`, `permissions: contents:
write` for the bump commit, `timeout-minutes: 60` set against the **bill**
(macOS bills at 10x), `LANG: en_US.UTF-8` for the whole job or Ruby reads the
Podfile as ASCII-8BIT and dies inside its own error reporter.

Steps, in the order that matters:

1. Checkout with submodules, then follow the submodule's branch.
2. Git identity for the bump commit → the bot, not whoever pressed the button.
3. Xcode, Flutter (pinned), task runner (pinned).
4. **Write `env/<flavor>.json` from a secret** with a `case`, never a
   `${{ a && b || c }}` ternary — that falls through to the second branch when
   the first secret is merely *empty*, silently building prod with dev config.
5. **Write the plist from a base64 secret**, then `plutil -lint` it: a
   truncated paste is otherwise indistinguishable from a good one until it
   throws on a device.
6. **Derive the sign-in URL scheme** from the plist just written
   (`REVERSED_CLIENT_ID`) and rewrite the committed `Info.plist`. Derived, not
   carried as a third secret — two copies of derived data is what causes the
   drift in the first place.
7. Bootstrap, generate.
8. **Pin Ruby, then `bundle install`, then pods — in that order.** A gem binary
   only runs under the Ruby it was installed for; the image's CocoaPods under a
   pinned Ruby finds none of its gems, and Flutter reports that as *"CocoaPods
   is installed but broken. Skipping pod install."* and archives an app missing
   that plugin's pods.
9. Run the lane. Free-text notes travel as an **env var**, never as a lane
   argument: spaces would split into extra fastlane arguments and a backtick
   would run.
10. Upload the IPA as an artifact — if TestFlight later rejects the binary, the
    exact one that went out is still there.

### Secrets

| Secret | Encoding |
|---|---|
| `ENV_DEV_JSON`, `ENV_PROD_JSON` | Whole file, verbatim. Adding a key later needs no workflow change. |
| `GOOGLE_SERVICE_INFO_PLIST_DEV`, `..._PROD` | base64 — multi-line XML whose newlines must survive. |
| `ASC_KEY_ID`, `ASC_ISSUER_ID` | Plain. |
| `ASC_KEY_CONTENT` | base64 of the `.p8`. |
| `MATCH_PASSWORD`, `MATCH_GIT_URL` | Plain. |
| `MATCH_GIT_BASIC_AUTHORIZATION` *or* `..._BEARER_...` | Basic = base64 of `user:PAT`; Bearer = the PAT verbatim. **Set exactly one.** |
| `FIREBASE_APP_ID_IOS` | Plain, optional — unset skips the dSYM upload with a warning. |

The certificates repo is **private and separate**: match stores a real
distribution certificate's private key in it, encrypted with `MATCH_PASSWORD`.
Its PAT is fine-grained, that repo only, **Contents: Read-only** — CI never
writes, so a token that can write grants an ability nothing uses.

---

## Part D — Standing this up in a new project

1. `env/` with `dev.example.json` / `prod.example.json` committed, the real
   files ignored; `AppEnv` with its required-key list and the `main()` assert.
2. `tool/prepare-env.sh` + the two runner wrappers; create `env_assets/` on
   your machine and put the real files in it.
3. `tool/build-ipa.sh`, and the rule that no one ever archives from Xcode
   written into the commands doc the same day.
4. App Store Connect API key (App Manager role, **downloadable once**), the
   private certificates repo, the fine-grained PAT.
5. `Appfile` / `Matchfile` / `Gemfile` / `.env`, then
   `bundle exec fastlane certificates` **once, from a Mac**.
6. `bundle exec fastlane preflight`, then `CI=true bundle exec fastlane
   preflight` — the second one is the half most likely to break.
7. The workflow and its secrets; first run with `bump:false` against a build
   number you know is free.
8. A `PIPELINE.md` diagram and a `CREDENTIALS.md`, and every unconfigured thing
   in one `PENDING_SETUP.md` so "it doesn't work" has one place to look.
