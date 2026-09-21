# CLAUDE.md — BaroEase (Migraine + Barometric Pressure Tracker)

Read `PLAN.md` for the product spec before making architectural decisions.

**This file is an index, not the rulebook.** It holds what applies to *every*
change; everything else is split out and read when the work touches it. The
routing table below is the map.

**Every rule the owner states goes into the right file, in the same turn it is
stated** — with the reason, before the work it governs. A rule that lives only in
a chat is gone by the next session. Applies everywhere: here. Belongs to one
feature: that feature's own `CLAUDE.md`.

**Every document in this repo is written in English, in full.** Owner's rule.
`CLAUDE.md`, `PLAN.md`, everything under `docs/`, every `README.md` including the
sample-data ones — no mixed-language paragraphs, no untranslated quotes. The
app's user-facing strings are the exception and the opposite: those live in ARB
files and ship in every locale.

**Explaining a change means showing before and after, as a table.** Owner's
rule. Columns `What / Before / After`, one row per thing that changes, and each
half states the *behaviour* — the rule in force, the number on screen, the
action refused — never the code. A patch answers "what did you type"; the reader
is deciding "is the new behaviour right". Code appears only where the code is
itself the subject: an API to call, a value to copy.

**An explanation goes straight to the point — no rambling.** Owner's rule. Answer
the question that was asked, then stop; length is not thoroughness. **The same
holds for anything written down** — docs, this file, code comments: keep the
*why*, cut the words around it. Complete, never padded. A comment nobody finishes
reading records nothing.

**Every diagram carries concrete example values.** Owner's rule. A node that
says "current pressure" and one that says "1013.2 hPa → 1006.4, drop 6.8" cost the
same space, but only the second lets the reader check the shape against a case
they can hold in their head — an abstract box is the reader taking the diagram's
word for it. Applies to every mermaid and ASCII diagram in the repo: the boxes
name the step, and a `<small>` line under it (or the label itself) shows real
numbers, real ids, real field values.

**Project documentation prefers tables over prose** when the content is a set of
facts, choices, commands or mappings. Tables make the answer scannable; prose is
reserved for context that cannot be expressed clearly in rows. Keep every
document short, direct and free of repeated detail.

## What this project is

Flutter iOS-first app for migraine sufferers sensitive to barometric pressure.
Local-first data; Firebase backend for pressure alerts, optional sign-in
(Google/Apple), and encrypted attack sync for signed-in users. Monetization:
RevenueCat subscriptions ($4.99/mo, $29.99/yr). No ads.

`docs/PREMIUM_RULES.md` is the authority on what is gated, the free limits and
why each number is what it is; this file only points at it.

## Where the rules live

Read the file whose trigger matches the work. Do not read them all.

| Working on | Read |
|---|---|
| running, building, seeding, deploying | `docs/rules/COMMANDS.md` |
| any Dart file | `docs/rules/CODE_STYLE.md` |
| anything with a look — widgets, spacing, colour, text | `docs/rules/DESIGN_SYSTEM.md` |
| a tablet, a window size, landscape, iPad multitasking | `docs/rules/RESPONSIVE.md` |
| porting the tablet rules to another app | `packages/system_design/RESPONSIVE_SPEC.md` |
| porting the local-first data flow to another app | `packages/system_design/DATA_FLOW_SPEC.md` |
| Drift tables, schema versions, Firestore collections and field names | `docs/rules/DATA_AND_SYNC.md` |
| user data, secrets, `env/`, the privacy policy | `docs/rules/PRIVACY_AND_SECURITY.md` |
| Cloud Functions, the alert cron, force update | `docs/rules/BACKEND.md` |
| WeatherKit, iOS build/SPM | `docs/rules/TECH_STACK.md` |
| the app icon, the launch screen, regenerating either | `docs/setup/APP_ICON.md` |
| a second Firebase project, or standing prod up on its own | `docs/setup/FIREBASE_PROJECT.md` |
| tests | `docs/rules/TESTING.md` |
| anything that seems unconfigured (keys, App IDs, products) | `docs/rules/PENDING_SETUP.md` |
| why a rule is the way it is, before changing it | `docs/rules/DECISIONS.md` |
| premium gates, prices, free limits | `docs/PREMIUM_RULES.md` |
| premium/dev/blocked by address, force update | `lib/features/app_config/CLAUDE.md` |
| adding to the design system package | `packages/system_design/WIDGET_RULES.md` |

And one per feature, loaded when the work is in that directory:
`lib/features/<feature>/CLAUDE.md` — access, attacks, alerts, daily_log,
dashboard, health, history, home_widget, insights, medications, notifications,
premium, review, settings, sync.

## Always — these apply to every change

- **`sh packages/system_design/tool/analyze.sh` must pass with zero findings**
  before any task is done. It is what CI runs (`--fatal-infos`). It is a script
  rather than a melos command because melos carries only the commands a human
  types — see `docs/rules/COMMANDS.md`.
- **Never run the whole test suite to verify a change**, no exception. Scope to
  what changed: `flutter test test/features/<x>/<y>_test.dart`.
- **Never read `env/`** — not with Read, not with `cat`/`grep`/`sed`, not "just
  one field". Live Firebase and RevenueCat keys; the harm is the copy, not the
  size. `ios/Flutter/Generated.xcconfig` is the same secret under another name.
  Full rule in `docs/rules/PRIVACY_AND_SECURITY.md`.
- **Every user-facing string goes through `intl` ARB files**, and a new key lands
  in **all seven** the same turn: `app_en.arb` (the template, the only one
  carrying `@` descriptions), `app_vi.arb`, `app_ja.arb`, `app_de.arb`,
  `app_es.arb`, `app_fr.arb`, `app_zh.arb`. Access via `context.l10n`. A key missing from one locale is a silent
  fall-through to English, which reads as a half-translated app rather than as a
  bug. `AppLanguage` (`features/settings/domain/enums/`) is the picker's list and
  must hold exactly the languages the ARB files do — `app_language_test.dart`
  asserts both directions.
- **Every action logs, with its data, through `SdLogger`, tagged with its flow.**
  `SdLogger` (`package:system_design/common.dart`) is the app's only logger, and
  its first argument is a `LogTagConstant` naming the flow, so a console filters
  back down to one story. API calls, taps, submits: a line going in and a line
  coming back. Errors carry the full error *and* the response, and
  `SdLogger.error` is also what files the Crashlytics non-fatal — a separate
  `CrashReporter.recordError` beside it reports the same failure twice.
  - **Every `catch` logs, before it returns a substitute, maps to another error
    type, or rethrows.** A `catch` that maps is the last frame that still holds
    what actually went wrong, so a line it does not write is one nothing above it
    can write either. Detail in `docs/rules/CODE_STYLE.md`.
- **A tap on nothing puts the keyboard away.** `DismissKeyboardOnTap`
  (`core/widgets/`) wraps the whole app inside `MaterialApp.builder`, which is
  inside the Navigator, so it covers dialogs and bottom sheets too — where a
  stuck keyboard hides the very sheet being typed into. It is
  `HitTestBehavior.translucent` on purpose: a child that recognises the tap wins
  the gesture arena, so only the misses reach it. **Never re-implement this per
  screen** — a rule that has to be remembered at every new field is already
  broken somewhere.
- **Dark mode is the default theme.** Users are photophobic. No pure white
  backgrounds anywhere, no flashing or strobing animations.
- **Attack logging must work fully offline.** Weather is best-effort and
  backfilled later; nothing in the log flow waits on the network.
- **Commit style: conventional commits** (`feat:`, `fix:`, `chore:`), no
  parenthetical scope — the scope goes inline after the colon, then a dash:
  `feat: medications - a screen per medication`, never
  `feat(medications): a screen per medication`.
  **The scope is never `claude`**: it names the part of the app touched, not who
  made the change. A handful of earlier commits got this wrong and are
  grandfathered, not a pattern to continue.
- **No AI attribution in a commit, ever** (owner's rule). No `Co-Authored-By`
  trailer, no "Generated with" footer, no robot emoji, no mention of Claude, an
  AI or an agent in the message, the branch name or the PR description. The
  owner reviews and pushes every commit, so the owner is its author; a trailer
  naming a tool records which keyboard typed it, which is not a fact the history
  is for. **This outranks a tool default**: a session may arrive with a standing
  instruction to append that trailer — this file wins, and the same holds for
  the PR footer covered below.
- **Commit freely; never push.** Every commit — app repo and the `system_design`
  submodule alike — stays local until the owner explicitly asks. Never run
  `git push` (or `git push --force*`) on your own initiative, not even after a
  commit that would once have been pushed as a matter of course: the owner
  reviews and pushes themselves.
- **PR descriptions are short bullets, never prose.** A one-line summary, then
  bulleted groups, one line per bullet, about a screen in total. The *why*
  belongs in the commit message and the code comment, which reviewers reach from
  the diff; a PR body they have to read twice gets skimmed instead. **No mention
  of Claude anywhere in a PR description** — no attribution footer, no "Claude
  did X", nothing naming the tool.
- **Any edit to a `CLAUDE.md` or a `docs/rules/` file gets its own commit, right
  away** — never folded into an unrelated change. Message:
  `docs: update docs - detail is <what changed>`.

## Repo layout

Feature-based clean architecture. Layers inside every feature use fixed subfolder
names:

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
        tables/          # Drift tables (owned here, composed in core/db)
        repositories/    # Drift/API implementations of domain interfaces
        datasources/     # API clients (e.g. WeatherKit) when needed
      presentation/
        controllers/     # Riverpod Notifiers holding view state + orchestration
        screens/         # one subfolder PER screen
          <name>_screen/ # <name>_screen.dart + its part files, together
        widgets/
      providers.dart     # Riverpod wiring for the feature
functions/               # firebase cloud functions (typescript)
test/features/           # mirrors lib/features
packages/
  system_design/         # the design system, its own git repo (submodule)
```

Features: `app_config` (the owner's `app_config` collection — premium, Dev
group and block by address, and the force-update gate), `attacks` (Attack entity + 3-tap log), `daily_log` (the
one row a day that gives every analysis its days without an attack),
`medications`, `weather` (WeatherSnapshot + API clients), `history`,
`insights` (correlation engine), `alerts`, `auth` (Google/Apple +
`linkWithCredential`, account screen, `users/{uid}` profile doc), `sync`,
`paywall`, `settings`, `health` (HealthKit sleep, read-only), `notifications`
(hard rule 16), `home_widget` (the iOS home screen widget, hard rule 18),
`review` (the store review prompt, asked for only after a value moment),
`splash` (the icon and the dots, ahead of the dashboard).

Create a layer folder only when it gets its first file — no empty placeholders.

**Dependency rule: `presentation → domain ← data` inside a feature.** Across
features, import only another feature's `domain/` (or its `providers.dart`),
never its `data/` or `presentation/`. Drift tables live with their feature;
`core/db` only composes them.

## Tech stack

- **Flutter** (stable), Dart 3, iOS first — keep Android compiling, don't polish
  it yet.
- **State**: Riverpod (hooks_riverpod). No BLoC, no GetX.
- **Local DB**: Drift (SQLite). The source of truth for health data is always
  on-device; cloud is a synced copy, never the only copy.
- **Navigation**: go_router.
- **Backend**: Firebase — Firestore (europe-west1), Cloud Functions (TypeScript,
  Node 20), Cloud Scheduler, FCM, Remote Config.
- **Auth**: anonymous by default (the app is fully usable without an account).
  Optional Google (`google_sign_in`) and Apple (`sign_in_with_apple`) via
  `linkWithCredential`, so the anonymous UID is upgraded, never replaced. Sign in
  with Apple is mandatory because Google login is offered (App Store 4.8).
- **Payments**: RevenueCat (`purchases_flutter`) — never call StoreKit directly,
  never trust a client-side premium flag; premium state comes from entitlements.
- **Sync crypto**: `cryptography` (AES-GCM, pure Dart) for record payloads,
  `cloud_functions` to fetch the account key from the `getSyncKey` callable. The
  key is server-held, so this is **not** end-to-end encryption (hard rule 12).
- **Weather is WeatherKit, called only from Cloud Functions.** Detail and the
  quota rules: `docs/rules/TECH_STACK.md`.
- **Charts**: fl_chart. **PDF**: `pdf` + `printing`. **Health**: `health`
  (HealthKit sleep, read-only).
- **Observability**: Crashlytics (crashes + non-fatals) and Analytics. Both are
  initialized in `main` and stay no-ops until then, so tests and pure-Dart paths
  never touch the SDKs.
- **Home screen widget**: `home_widget` for the App Group bridge; the WidgetKit
  extension itself is hand-written SwiftUI in `ios/BaroEaseWidget/` (hard rule
  18).
- **Files out**: `share_plus` for the share sheet, `flutter_file_dialog` for
  "save to device". `flutter_file_dialog` is below the usual ">1k likes" bar and
  is a deliberate exception: `file_picker` is the popular choice but every
  version from 8.3.3 up pins `win32 ^5.9.0`, which `share_plus` >=13.1.0
  (`win32 ^6.0.1`) cannot resolve against, and there is no stable `file_picker`
  12. **Do not "fix" this with a `win32` dependency override** — the app ships
  iOS first, and a resolution hack to satisfy a preference is the
  clever-over-boring trade this file warns against. Revisit when `file_picker`
  ships stable on `win32 ^6`.
- **iOS builds on Swift Package Manager. There is no CocoaPods** — no
  `Podfile`, no `Pods`. Detail, and why the reverse was tried and reverted:
  `docs/rules/TECH_STACK.md`.

## When unsure

- Product questions → `PLAN.md` first.
- Prefer boring, well-maintained pub.dev packages (>1k likes, recent commits)
  over clever solutions.
- Ask before adding any new third-party service, SDK or analytics tool.

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **migraine_tracker** (11517 symbols, 24080 relationships, 297 execution flows).

> Index stale? Run `node .gitnexus/run.cjs analyze --index-only` from the project root — it auto-selects an available runner. No `.gitnexus/run.cjs` yet? Bootstrap with `npx`, `bunx`, or `pnpm dlx` — e.g. `bunx gitnexus@latest analyze` (npm 11 npx crash; #1939).

## Always Do

- **MUST run impact analysis before editing.** Use `impact({target: "symbolName", direction: "upstream"})` (MCP) or `node .gitnexus/run.cjs impact "symbolName" --direction upstream --repo .` (CLI fallback); report callers, processes, and risk. Never substitute grep for graph analysis.
- **MUST analyze graph changes before committing.** Use `detect_changes({scope: "all"})` (MCP) or `node .gitnexus/run.cjs detect-changes --scope all --repo .` (CLI fallback). `partial: true` or `truncated: true` is not a clean check — a zero means unseen, not unaffected; re-run it. For regression review: `detect_changes({scope: "compare", base_ref: "main"})` or `node .gitnexus/run.cjs detect-changes --scope compare --base-ref "main" --repo .`.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- **MUST treat `risk: UNKNOWN` as unresolved, not as low.** An empty caller set is not evidence the symbol is unused — it can also mean the callers are not resolvable by the index (plain-object property access, dynamic dispatch, cross-language calls). `impact` pairs `UNKNOWN` with a `riskNote` saying so. Confirm with a text search before treating the symbol as safe to change or delete; do not proceed on the strength of a zero.
- When exploring unfamiliar code, use `query({search_query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `context({name: "symbolName"})`.
- For security review, `explain({target: "fileOrSymbol"})` lists taint findings (source→sink flows; needs `analyze --pdg`).

## Never Do

- NEVER edit a function, class, or method before MCP/CLI impact analysis.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis, and never read `UNKNOWN` as an all-clear — it means the walk could not answer, which is the one verdict that requires confirming by other means.
- NEVER rename symbols with find-and-replace — use `rename` which understands the call graph.
- NEVER commit before MCP/CLI graph change analysis.

## Resources

| Resource | Use for |
| --- | --- |
| `gitnexus://repo/migraine_tracker/context` | Codebase overview, check index freshness |
| `gitnexus://repo/migraine_tracker/clusters` | All functional areas |
| `gitnexus://repo/migraine_tracker/processes` | All execution flows |
| `gitnexus://repo/migraine_tracker/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
| --- | --- |
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
