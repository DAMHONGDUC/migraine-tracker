# CLAUDE.md — BaroEase (Migraine + Barometric Pressure Tracker)

Read `PLAN.md` for full product spec before making architectural decisions.

**This file is an index, not the rulebook.** It holds what applies to *every*
change; everything else is split out and read when the work touches it. The
routing table below is the map.

**Every rule the owner states goes into the right file, in the same turn it is
stated** — with the reason, before the work it governs. A rule that lives only
in a chat is gone by the next session. If it applies everywhere it belongs
here; if it belongs to one feature it goes in that feature's own `CLAUDE.md`.

**Every document in this repo is written in English, in full.** Owner's rule.
`CLAUDE.md`, `PLAN.md`, everything under `docs/` and every `README.md`,
including the sample-data ones — no mixed-language paragraphs and no
untranslated quotes. The app's user-facing strings are the exception and the
opposite: those live in ARB files and ship in both locales.

**Explaining a change means showing before and after.** Not prose about what
changed — the old code and the new one, side by side, then what the
difference does. A description of a diff is the reader taking your word for
it; the diff is the reader checking.

**An explanation goes straight to the point — no rambling.** Owner's rule.
Answer the question that was asked, then stop. Length is not thoroughness.

## What this project is

Flutter iOS-first app for migraine sufferers sensitive to barometric pressure.
Local-first data; Firebase backend for pressure alerts, optional sign-in (Google/Apple), and encrypted attack sync for signed-in users.
Monetization: RevenueCat subscriptions ($4.99/mo, $29.99/yr, $44.99 lifetime). No ads.
The premium rules — what is gated, the free record limits and why each number is what it is — live in `docs/PREMIUM_RULES.md`, which is the authority; this file only points at it.

## Where the rules live

Read the file whose trigger matches the work. Do not read them all.

| Working on | Read |
|---|---|
| running, building, seeding, deploying | `docs/rules/COMMANDS.md` |
| any Dart file | `docs/rules/CODE_STYLE.md` |
| anything with a look — widgets, spacing, colour, text | `docs/rules/DESIGN_SYSTEM.md` |
| Drift tables, schema versions, Firestore collections | `docs/rules/DATA_AND_SYNC.md` |
| anything touching user data, secrets, `env/`, the privacy policy | `docs/rules/PRIVACY_AND_SECURITY.md` |
| Cloud Functions, the alert cron, force update | `docs/rules/BACKEND.md` |
| WeatherKit, iOS build/SPM/CocoaPods | `docs/rules/TECH_STACK.md` |
| tests | `docs/rules/TESTING.md` |
| anything that seems unconfigured (keys, App IDs, products) | `docs/rules/PENDING_SETUP.md` |
| why a rule is the way it is, before changing it | `docs/rules/DECISIONS.md` |
| premium gates, prices, free limits | `docs/PREMIUM_RULES.md` |
| adding to the design system package | `packages/system_design/WIDGET_RULES.md` |

And one per feature, loaded when the work is in that directory:
`lib/features/<feature>/CLAUDE.md` — attacks, alerts, dashboard, health,
history, home_widget, insights, medications, notifications, premium, settings,
sync.

## Always — these apply to every change

- **`melos run analyze` must pass with zero findings** before considering any
  task done. It is what CI runs (`--fatal-infos`).
- **Never run the whole test suite to verify a change**, no exception. Scope to
  what changed: `flutter test test/features/<x>/<y>_test.dart`.
- **Never read `env/`** — not with Read, not with `cat`/`grep`/`sed`, not "just
  one field". Live Firebase and RevenueCat keys; the harm is the copy, not the
  size. `ios/Flutter/Generated.xcconfig` is the same secret under another name.
  Full rule in `docs/rules/PRIVACY_AND_SECURITY.md`.
- **Every user-facing string goes through `intl` ARB files**, `app_en.arb` and
  `app_vi.arb`, both, every time. Access via `context.l10n`.
- **Every action logs, with its data.** API calls, taps, submits — a line going
  in and a line coming back. Errors carry the full error *and* the response.
  Every `catch` logs before returning its substitute. Detail in
  `docs/rules/CODE_STYLE.md`.
- **Dark mode is the default theme.** Users are photophobic. No pure white
  backgrounds anywhere; no flashing or strobing animations.
- **Attack logging must work fully offline.** Weather is best-effort and
  backfilled later; nothing in the log flow waits on the network.
- Commit style: conventional commits (`feat:`, `fix:`, `chore:`). No parenthetical scope — write the scope inline after the colon, then a dash: `feat: medications - a screen per medication`, never `feat(medications): a screen per medication`. No `Co-Authored-By` trailer. **The scope is never `claude`** (e.g. never `chore: claude - listItemGap covers item spacing`) — the scope names the part of the app touched, not who or what made the change; a handful of earlier commits on this repo got this wrong and are grandfathered, not a pattern to continue.
- **Commit freely; never push.** Every commit (app repo and the `system_design` submodule alike) stays local until the owner explicitly asks for a push — the owner reviews and pushes themselves. Don't run `git push` (or `git push --force*`) on your own initiative, even after a commit that would previously have been pushed as a matter of course.
- **Any edit to this file gets its own commit, right away** — a CLAUDE.md change never rides along uncommitted or folded into an unrelated commit. Message: `docs: update docs - detail is <what changed>`.
- **PR descriptions are short bullets, never prose.** A one-line summary, then bulleted groups — one line per bullet, about a screen in total. No explanatory paragraphs, no quoting source in the body. The *why* belongs in the commit message and the code comment, which reviewers reach from the diff; a PR body they have to read twice gets skimmed instead. **No mention of Claude anywhere in a PR description** — no attribution footer (e.g. "Generated with Claude Code"), no "Claude did X" phrasing, nothing naming the tool at all; the description reads like the person who owns the repo wrote it.
- **Any edit to a `CLAUDE.md` or a `docs/rules/` file gets its own commit,
  right away** — never folded into an unrelated change. Message:
  `docs: update docs - detail is <what changed>`.

## Repo layout

Feature-based clean architecture. Layers inside every feature use fixed
subfolder names:

```
lib/
  core/                  # cross-cutting only, NO business logic
    db/                  # AppDatabase (composes feature-owned tables), converters
    router/ theme/
  l10n/                  # ARB files (+ generated gen/)
  features/
    <feature>/
      domain/            # pure Dart, no Flutter imports
        entities/        # immutable models / value objects
        enums/
        repositories/    # abstract repository interfaces
        services/        # real domain logic (e.g. correlation engine)
      data/
        tables/          # Drift table definitions (owned here, composed in core/db)
        repositories/    # Drift/API implementations of domain interfaces
        datasources/     # API clients (e.g. WeatherKit) when needed
      presentation/
        controllers/     # Riverpod Notifiers holding view state + orchestration
        screens/         # one subfolder PER screen (see below)
          <name>_screen/ # <name>_screen.dart + its part files, together
        widgets/
      providers.dart     # Riverpod wiring for the feature
functions/               # firebase cloud functions (typescript)
test/features/           # mirrors lib/features
packages/
  system_design/      # the design system, its own git repo (submodule)
```

Features: `app_update` (force-update gate), `attacks` (Attack entity + 3-tap log), `medications`, `weather`
(WeatherSnapshot + API clients), `history`, `insights` (correlation engine),
`alerts`, `auth` (Google/Apple + linkWithCredential, account screen, `users/{uid}` profile doc), `sync`, `paywall`,
`settings`, `health` (HealthKit sleep, read-only), `notifications` (the notification list — see hard rule 16),
`home_widget` (the iOS home screen widget — see hard rule 18).
Create a layer folder only when it gets its first file — no empty placeholder folders.

Dependency rule: `presentation → domain ← data` inside a feature. Across
features, import only another feature's `domain/` (or its `providers.dart`),
never its `data/` or `presentation/`. Drift tables live with their feature;
`core/db` only composes them.

## Tech stack

- **Flutter** (stable channel), Dart 3, iOS first (keep Android compiling, don't polish it yet)
- **State**: Riverpod (hooks_riverpod). No BLoC, no GetX.
- **Local DB**: Drift (SQLite). Source of truth for health data is always on-device; cloud is a synced copy, never the only copy.
- **Navigation**: go_router
- **Backend**: Firebase — Firestore (region europe-west1), Cloud Functions (TypeScript, Node 20), Cloud Scheduler, FCM, Remote Config
- **Auth**: anonymous by default (app fully usable without an account). Optional sign-in via Google (`google_sign_in`) and Apple (`sign_in_with_apple`) using `linkWithCredential` so the anonymous UID is upgraded, never replaced. Sign in with Apple is mandatory because Google login is offered (App Store 4.8).
- **Payments**: RevenueCat (`purchases_flutter`) — never call StoreKit directly, never trust client-side premium flags; premium state comes from RevenueCat entitlements
- **Sync crypto**: `cryptography` (AES-GCM, pure Dart) for record payloads, `cloud_functions` to fetch the account key from the `getSyncKey` callable. The key is server-held, so this is not end-to-end encryption — see hard rule 12.
- **Weather is WeatherKit, called only from Cloud Functions.** Detail and the
  quota rules: `docs/rules/TECH_STACK.md`.
- **Charts**: fl_chart. **PDF**: `pdf` + `printing` packages. **Health**: `health` package (HealthKit sleep, read-only)
- **Observability**: Firebase Crashlytics (crashes + non-fatals) and Firebase Analytics (usage). Both are initialized in `main` and stay no-ops until then, so tests and pure-Dart paths never touch the SDKs.
- **Home screen widget**: `home_widget` for the App Group bridge; the WidgetKit extension itself is hand-written SwiftUI in `ios/BaroEaseWidget/` (hard rule 18)
- **Files out**: `share_plus` for the share sheet, `flutter_file_dialog` for "save to device" (the platform's own save picker). `flutter_file_dialog` is below the usual ">1k likes" bar and is a deliberate exception: `file_picker` is the popular choice but every version from 8.3.3 up pins `win32 ^5.9.0`, which `share_plus` >=13.1.0 (`win32 ^6.0.1`) cannot resolve against, and there is no stable `file_picker` 12. Do not "fix" this with a `win32` dependency override — the app ships iOS first and a resolution hack to satisfy a preference is the clever-over-boring trade CLAUDE.md warns against. Revisit only when `file_picker` ships a stable release on `win32 ^6`.
- **iOS builds on Swift Package Manager, not CocoaPods** — except `health`.
  Detail, and why the reverse was tried and reverted:
  `docs/rules/TECH_STACK.md`.

## When unsure

- Product questions → check `PLAN.md` first
- Prefer boring, well-maintained pub.dev packages (>1k likes, recent commits) over clever solutions
- Ask before adding any new third-party service, SDK, or analytics tool
