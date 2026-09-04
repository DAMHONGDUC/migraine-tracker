# The release pipeline — a map

What happens between pressing "Run workflow" and a build appearing in
TestFlight. This file is the map; it deliberately holds no rules.

- **Why a step is the way it is** — `docs/rules/COMMANDS.md`.
- **How each credential is made and how it fails** — `CREDENTIALS.md`, alongside.
- **What is still missing** — `docs/rules/PENDING_SETUP.md`.

Nothing here is duplicated from those on purpose: a diagram that also carries
the reasoning goes stale in a different direction from the rules it copies, and
then they disagree.

## The flow

```mermaid
flowchart TD
    trigger["You press Run workflow<br/><small>branch main, flavor prod</small>"]
    prep["Runner builds the environment<br/><small>Flutter stable, melos 6.3.3, pods for health</small>"]
    check["Check the config matches the flavor<br/><small>bundle id app.dd.migraine.tracker</small>"]
    num["Settle the build number<br/><small>pubspec 30, TestFlight 34 → 35</small>"]
    certs["Install the signing identity<br/><small>match appstore, then installs</small>"]
    sign["Switch to manual signing<br/><small>Runner + BaroEaseWidgetExtension</small>"]
    build["build-ipa.sh makes the IPA<br/><small>flutter build ipa --dart-define-from-file=env/prod.json</small>"]
    upload["Upload to TestFlight<br/><small>build 1.1.0 (35), does not wait for processing</small>"]
    dsym["Upload dSYMs to Crashlytics<br/><small>best effort, never blocks</small>"]
    commit["Commit the build number<br/><small>pubspec version: 1.1.0+35</small>"]

    envjson(["GitHub Secret<br/><small>ENV_PROD_JSON → env/prod.json</small>"])
    firebaserc([".firebaserc<br/><small>prod → the production project id</small>"])
    asc1(["App Store Connect<br/><small>latest build number: 34</small>"])
    matchrepo(["Repo certificates<br/><small>MATCH_PASSWORD, MATCH_GIT_BASIC_AUTHORIZATION</small>"])
    asc2(["App Store Connect API key<br/><small>the .p8, from ASC_KEY_CONTENT</small>"])
    token(["GITHUB_TOKEN<br/><small>contents: write, pushes 1.1.0+35</small>"])

    trigger --> prep --> check --> num --> certs --> sign --> build --> upload --> dsym --> commit

    envjson -.-> prep
    firebaserc -.-> check
    asc1 -.-> num
    matchrepo -.-> certs
    asc2 -.-> upload
    token -.-> commit
```

Solid arrows are the order of execution. Dashed arrows are credentials
entering the run — every one of them comes from outside the checkout, which
is why a fresh clone alone can never produce a release.

## Where each piece lives

| Piece | File |
|---|---|
| Trigger, environment, secrets | `.github/workflows/release-ios.yml` |
| Build number, signing, export, upload | `ios/fastlane/Fastfile` |
| Which certificate and profiles | `ios/fastlane/Matchfile` |
| The build itself | `packages/system_design/tool/build-ipa.sh` |

## The orderings that are not arbitrary

**The build number is settled before the build, and committed after the
upload.** Before, because a number App Store Connect will refuse should cost
seconds rather than a full build. After, because a bump commit with no build
is a gap in the numbering, while a build on TestFlight whose number is in no
commit is the thing the rule exists to prevent.

**Signing is switched to manual inside the runner's checkout only.** That
checkout is thrown away, so the edit never reaches git and a developer's Mac
keeps automatic signing.

**Ruby is pinned before `bundle install`.** fastlane is a gem, and a gem
binary only runs under the Ruby it was installed for. The pin plus the Gemfile
is what keeps a runner-image update from re-tooling a release without anyone
choosing it.

**The "What to Test" note is passed twice, as `changelog` AND as
`localized_build_info`.** `skip_waiting_for_build_processing: true` keeps the
lane off a 10–20 minute macOS bill, and pilot reads `changelog` — that key
specifically — to decide whether to wait for the build to appear at all. But
`changelog` alone then lands in a code path that writes the note into the beta
localizations the build ALREADY has, and a build fetched the instant it
appears has none: App Store Connect creates them during processing. The loop
runs zero times, raises nothing, and pilot still logs "Successfully set the
changelog for build" — so every build shipped with an empty note and a green
lane. `localized_build_info` names the locale outright, which is what makes
pilot create the localization instead of needing one to exist. Neither key
alone works; drop either and the note silently disappears again.

## What runs where

The lane runs the same `packages/system_design/tool/build-ipa.sh` a developer
runs by hand. Fastlane adds signing, the export options and the upload around
it — it never archives
anything itself, and `docs/rules/COMMANDS.md` says why that is not negotiable.
