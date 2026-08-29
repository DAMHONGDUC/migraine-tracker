# Release credentials — how to make them, where they live

Four credentials stand between a clone and a TestFlight build. None is in this
repo and none can be. This file is the how: making each one, where it lives,
and how it fails. `PIPELINE.md` is the order of the release,
`docs/rules/COMMANDS.md` the reasoning, `docs/rules/PENDING_SETUP.md` what is
still missing.

| Credential | Purpose | On the Mac | On CI |
|---|---|---|---|
| App Store Connect API key | Read build numbers, upload the IPA | `.p8` under `~/.appstoreconnect/private_keys/` | `ASC_KEY_CONTENT` (base64) |
| Fine-grained PAT | Clone the private certificates repo | base64 in `ios/fastlane/.env` | `MATCH_GIT_BASIC_AUTHORIZATION` |
| match passphrase | Decrypt the certificate | `ios/fastlane/.env` | `MATCH_PASSWORD` |
| `env/*.json` | Firebase and RevenueCat config | `env/dev.json`, `env/prod.json` | `ENV_DEV_JSON`, `ENV_PROD_JSON` |
| `GoogleService-Info.plist` | Firebase's own iOS config, a build input | `ios/Runner/GoogleService-Info.plist` | `GOOGLE_SERVICE_INFO_PLIST_DEV`, `GOOGLE_SERVICE_INFO_PLIST_PROD` (base64) |

On the Mac the last two rows are laid down together — with
`android/app/google-services.json` and `ios/Runner/Info.plist`, whose Google
sign-in URL scheme has to match the project — by `melos run
prepare-env-dev|prod`, from a gitignored `env_assets/` folder holding your own
copies. CI writes them from the secrets instead; `Info.plist` is tracked, so
the workflow rewrites its URL scheme from the plist it just wrote rather than
trusting whatever was committed.

**And the lane checks the result before it builds.** `fastlane beta` reads the
project id out of `ios/Runner/GoogleService-Info.plist` and refuses to go on
unless it is the one `.firebaserc` gives for the flavor — the guard against
`prepare-env-dev` followed by `beta flavor:prod`, which uploads a working app
pointed at the wrong Firestore. Same check on `fastlane preflight flavor:dev`.

## The App Store Connect API key

App Store Connect → Users and Access → Integrations → App Store Connect API →
a key with the **App Manager** role. It yields three things: an `AuthKey_*.p8`
file, a **Key ID**, and an **Issuer ID**.

**Downloadable exactly once.** Like the APNs and WeatherKit keys, and a
different key from both. Put it somewhere permanent immediately —
`~/.appstoreconnect/private_keys/` is where fastlane looks by convention.

It replaces an Apple ID login, which is the whole point: two-factor
authentication has no answer a CI runner can give.

For CI the file is base64-encoded, because it is multi-line and a secret that
loses its newlines fails as an unreadable key rather than as a missing one:

```sh
base64 -i ~/.appstoreconnect/private_keys/AuthKey_XXXXXXXXXX.p8 | pbcopy
```

## The fine-grained PAT

GitHub → Settings → Developer settings → Personal access tokens →
**Fine-grained tokens** → Generate new token:

- **Resource owner**: the account that owns the certificates repo
- **Repository access**: Only select repositories → the certificates repo alone
- **Permissions** → Repository permissions → **Contents: Read-only**

Read-only is not caution for its own sake: CI runs `match` with
`readonly: true` and never writes, so a token that can write grants an ability
nothing uses. Fine-grained over classic for the same reason — a classic token
with the `repo` scope carries read *and* write across *every* repository the
account owns.

A fine-grained token starts with `github_pat_`; a classic one starts with
`ghp_`. If the token in hand starts with `ghp_`, it is the wrong kind.

Shown once, on the page that creates it.

### Turning it into an auth header

match sends the token as an HTTP header, and the header form decides the
encoding:

- `MATCH_GIT_BEARER_AUTHORIZATION` takes the token **verbatim**.
- `MATCH_GIT_BASIC_AUTHORIZATION` takes **base64 of `username:token`**. This is
  the form match's own documentation shows.

Set exactly one. The lane deletes an empty one from the environment before
calling match — see the duplicate-header trap below for why that is not
optional.

```sh
printf 'PAT: '; read -s PAT; echo
printf '<github-username>:%s' "$PAT" | base64 | tr -d '\n' | pbcopy
unset PAT
```

Three details in that snippet, each of which has already cost a failed run:

- **`printf`, never `echo`.** `echo` appends a newline, base64 encodes it, and
  the header carries a line break.
- **`tr -d '\n'`** removes base64's own trailing newline. `printf` alone does
  not save you from this one; the newline comes out of `base64`, not the input.
- **`%s` rather than the variable inside the format string.** A token
  containing `%` would otherwise be read as a format directive and mangled.

## `ios/fastlane/.env`

Read automatically by fastlane, gitignored by `ios/fastlane/.env*`, and laid
down by `melos run prepare-env-dev|prod` from `env_assets/fastlane.env` — one
copy for both flavors, because nothing in it differs between them. Six keys:

```
ASC_KEY_ID=
ASC_ISSUER_ID=
ASC_KEY_FILEPATH=/Users/<you>/.appstoreconnect/private_keys/AuthKey_XXXXXXXXXX.p8
MATCH_PASSWORD=
MATCH_GIT_URL=
MATCH_GIT_BASIC_AUTHORIZATION=
```

**The file must end with a newline.** Not a style preference — see the trap
below. After editing it, confirm the shape without printing any values:

```sh
cut -d= -f1 ios/fastlane/.env
```

Six names, each on its own line, is correct. A name that is missing, or one
that appears glued to the end of another value, is the failure this check
exists to catch.

## `GoogleService-Info.plist`

Firebase console → the iOS app → download. It belongs at
`ios/Runner/GoogleService-Info.plist` and is gitignored, so a CI checkout does
not have it — and unlike `env/*.json` it is a **build input** of the Runner
target, listed in the pbxproj's Resources. Missing, it does not degrade
anything at runtime; the archive itself fails, after the full compile:

```
Build input file cannot be found: '.../ios/Runner/GoogleService-Info.plist'
```

The workflow writes it from `GOOGLE_SERVICE_INFO_PLIST_DEV` or
`GOOGLE_SERVICE_INFO_PLIST_PROD`, base64 for the same reason as the API key —
multi-line XML whose newlines must survive the round trip. Run this once per
project, with that project's file in place:

```sh
base64 -i ios/Runner/GoogleService-Info.plist | pbcopy
```

One secret per flavor, because dev and prod are two Firebase projects
(`.firebaserc`). The older single `GOOGLE_SERVICE_INFO_PLIST` is still read as
a fallback, and it is only ever right for one of the two — the lane's project
check fails the other before the build starts.

## Rotating

All three are replaceable. That is the property to remember when one leaks —
the question is only how much work, never whether.

- **PAT** — revoke, generate another, update `ios/fastlane/.env` and the GitHub
  secret. Nothing else is affected.
- **App Store Connect API key** — revoke under Integrations, create another,
  update three values. Builds already on TestFlight are untouched.
- **match passphrase or certificate** — `fastlane match nuke distribution`, then
  `fastlane certificates` again with a new passphrase. **Apps already on the App
  Store keep working**: Apple re-signs them for distribution, so revoking a
  distribution certificate breaks only ad-hoc builds signed with it.

The WeatherKit `.p8` is the one that is *not* cheap to replace — see
`docs/rules/PENDING_SETUP.md`.

## Traps, each one paid for

**`could not read Username for 'https://github.com': terminal prompts
disabled`.** The credential was rejected and git fell back to asking a human,
on a machine with no human. Reads like a missing configuration; means a wrong
value. Note the distinction from the next one: rejected, not malformed.

**`HTTP 400` on the clone.** Malformed request, not rejected credential. At the
header level that almost always means a newline inside a header value, because
a newline is what *terminates* a header — everything after it is read as a new,
broken one. Its source is usually base64's trailing newline surviving into the
value.

**`remote: Duplicate header: "Authorization"`.** Both auth env vars were set,
one of them to the empty string. Actions sets every `${{ secrets.X }}` a
workflow names, empty string included, for a secret that does not exist — and
match reads both variables from the environment regardless of which option the
call site passes. Choosing one in code is therefore not enough; the empty one
has to be deleted from `ENV`. The lane does this.

**A value glued to the end of the previous line.** `>>` appends bytes, not
lines: it writes from the last byte of the file, and if that byte is not a
newline the new text continues the existing line. A `.env` whose last line has
no trailing newline turns the next appended variable into a suffix of the
previous value — and the symptom is not "variable missing" but "the previous
variable is now nonsense", which points at the wrong place entirely.

Worse, the obvious check misleads: `grep -c '^NAME='` returns `0`, which reads
as "never written" when the truth is "written, wrong place". Prefer
`cut -d= -f1` — it shows the file's actual shape rather than answering one
question about it.

**A clipboard that no longer holds what you put there.** Any instruction of the
form "copy this value, then run this command" destroys itself: copying the
command overwrites the value. Put the value in the file or in a variable, and
leave the clipboard for the final hop into a browser field.

## Rehearsing before spending CI minutes

Every failure above surfaces in seconds, locally:

```sh
cd ios && CI=true MATCH_GIT_BEARER_AUTHORIZATION= bundle exec fastlane preflight
```

`CI=true` is what turns the match branch on; the empty
`MATCH_GIT_BEARER_AUTHORIZATION` reproduces the runner's environment exactly,
empty variables included. Detail in `docs/rules/COMMANDS.md`.
