---
name: engineering-conventions
description: A working rulebook for any codebase - module boundaries, one owner per value, logging on every action and every catch, comment and constant discipline, schema versioning, scoped tests, secret handling, commit and PR style, and keeping AGENTS.md an index over split rule files. Part 2 adds deep Flutter and Dart rules and applies only to Flutter repos. Use when writing or reviewing code, adding a module, screen, controller, repository or database table, naming things, deciding where a constant or a shared helper lives, or setting up a repo's conventions.
---

# Engineering conventions

A working rulebook for keeping a codebase where any file can be found from its
name, no value is typed twice, and nothing fails silently.

Each rule carries the reason it exists - usually a real bug. Read the reason
before proposing a change; a rule stripped of its reason is the one that gets
"simplified" away and re-learned the expensive way.

**Two things govern how to apply this:**

1. **When the project already has its own convention, the project wins.** This
   is the default for a codebase that has not decided yet, and the checklist
   for one reviewing whether its decisions still hold.
2. **Part 1 applies to every project, in any language.** **Part 2 applies only
   when the repo is Flutter** - a `pubspec.yaml` with a `flutter:` SDK
   dependency. In any other stack, take Part 1 and translate its principles to
   the nearest local idiom; do not import Part 2's specifics.

---

# Part 1 - Applies to every project

## 1. Boundaries and layout

- **Group by feature, not by kind.** A folder per feature holding everything
  that feature owns beats a folder of all the controllers and another of all
  the models. The second layout means every change touches four distant
  directories.
- **Fix the layer names once and never invent one.** A reader who learns the
  shape of one feature has learned all of them. Create a layer folder when it
  gets its first file - no empty placeholders.
- **Dependencies point inward.** The pure core (entities, business rules, no
  framework imports) is depended on by everything and depends on nothing.
  Delivery mechanisms (UI, HTTP handlers, CLI) and infrastructure (DB, API
  clients) both point at it, never at each other.
- **Across features, import only the other feature's public surface** - its
  domain types or its declared entry point. Never reach into another feature's
  internals; that is how two features quietly fuse into one.
- **Shared code moves the moment the second consumer appears.** A helper used
  by two features belongs in the shared layer, not in whichever feature wrote
  it first - otherwise the second consumer imports the first's internals and
  breaks the boundary. Shared -> feature imports are fine; feature -> feature
  internals are not.
- **One shared folder per job, not several.** A second `utils/` or `components/`
  under the shared layer means nobody can answer where a new one goes.

## 2. One owner per value

- **The second copy is the trigger for extraction, not a later cleanup.**
  Duplicated logic becomes one named function; duplicated structure becomes one
  component. Three call sites spelling out the same number is three chances to
  disagree.
- **Constants live in their own class or module, never bolted onto a model, an
  entity, a controller or a view.** A number a class does not itself use is not
  that class's business. Cross-cutting -> the shared constants module;
  feature-local -> that feature's own.
- Two exceptions worth naming: an object's **own intrinsic size or identity**
  (what the thing *is*, not configuration about it), and a **canonical empty
  instance** - a value of the type, the same shape as a zero.
- **One named value per job, and never a raw literal at a call site.** If two
  places need the same gap, timeout, page size or retry count, it gets a name
  and one home. If they need different ones, they get two names - not two
  literals.
- **Specialised logic gets its own helper on its FIRST use, not its second.** A
  view's job is layout, a controller's is orchestration, a handler's is
  request/response. Date math, parsing, formatting, filename building and
  arithmetic all move out even when only one caller exists today.
- **One class per subject.** All date and time arithmetic in one place; two
  date-shaped utility modules is how two call sites end up computing midnight
  differently.

## 3. Logging and observability

- **Every action logs, and it logs the DATA with it.** Every API call, every
  user action, every submit: a line going in with what was sent, a line coming
  back with what returned. Carry the payload, the id, the count - whatever the
  next person would otherwise have to reproduce the run to find out.
- **A log without its data cannot answer anything.** "Sync failed" tells you a
  sync failed; "Sync failed - {collection: orders, pushed: 12}" tells you which
  one and how far it got.
- **Success is logged too.** An empty log must mean nothing ran, never
  "everything worked".
- **Analytics goes through one typed module**, a method per event, so the full
  inventory of what is sent is one file. Never call the SDK directly and never
  type an event name at a call site. Events sit next to the matching log line
  in the orchestration layer, never in a view's render path. Sensitive user
  data never becomes an event parameter.
- **Crash/error reporting is its own module**, called for a caught failure
  worth seeing in production alongside the log line that serves the console.
  The pure core stays dependency-free - report from the layer that catches.

## 4. Errors

- **Every `catch` logs, wherever it sits.** A block that turns a failure into
  `null`, `false` or an enum holds the only copy of what actually went wrong,
  so it logs the error and the stack before returning the substitute. Handling
  an error is not the same as knowing it happened.
- **Log the full error object and the response**, not a message about it.
  Stringifying into a hand-written message throws away exactly the
  code/details/body that would have explained it. Pass what was thrown,
  unmodified, plus what the call was doing.
- **Catch broadly, not narrowly.** Catching only the "expected" error type lets
  exactly the unexpected ones through untouched *and* unlogged - and those are
  the ones you needed to see.
- **Plain inline `try`/`catch`, always.** No closure-taking wrapper
  (`logger.guard(action)`) - a combinator hides the flow. Never `print`.
- Two exemptions, both narrow: a caller re-catching what its callee already
  logged (say so in the comment), and a user cancellation, which is not a
  failure.
- **Guard each startup step separately, never the whole init function.** Its
  concerns are independent, and one `try` around all of them lets the first
  failure skip everything after it - including the error reporting that would
  have named it. **Initialize crash reporting first.** Anything that runs
  before the app is up needs its own catch and a fallback that leaves the app
  usable, because a throw there does not show an error screen - it stops the
  process from starting at all.

Why this section is absolute: three features once failed silently at once - an
API answered every call `401`, a push was refused by the backend, and neither
left a line anywhere. **A caught error is invisible by construction.**

## 5. Style that survives review

- **Extract at ~80 lines.** Composition over configuration flags: two booleans
  selecting three behaviours should be one enum.
- **The variant is a parameter, never a separate named constructor or a forked
  function.** Otherwise the shared parts drift apart one fix at a time.
- **Declarations first, blank line, then logic.** Group declarations at the top
  with no blank lines between them, one blank line, then the logic. Never
  declare, run logic, then declare again lower down.
- **Explicit types over inference** wherever a reader would otherwise have to
  jump to another file to learn what something is.
- **Interfaces are for contracts that are actually implemented**, not a mirror
  of every concrete class.
- **Comments: short and plain, never more than 3 lines.** Say *why*, not what
  the code already says. A multi-point comment is a bullet list, one line per
  point starting with `-`, never a run-on sentence joined by conjunctions. If
  it needs a 4th line, cut to the one reason that matters or move the "how"
  into a doc comment on the function it belongs to.
- **The entry point holds the entry point and nothing else.** Startup work
  lives in a bootstrap module, so `main` stays a list of what happens rather
  than how.

## 6. Data and schemas

- **Never put two kinds of record in one table or collection.** Each entity
  gets its own, on both sides of the wire. No shared table with a `type` column
  standing in for three schemas. A bookkeeping table (tombstones, audit) is the
  deliberate exception and says so in a comment.
- **Never edit a schema version in place once any database has run it - bump
  instead.** "Unshipped" means no database anywhere has run it, **and your own
  dev machine counts**. A rename that looks safe on an unshipped version leaves
  that one device stranded with the old column and no migration step that ever
  fixes it. When nothing records what the intermediate version looked like,
  recreate the table rather than renaming a column - a drop works whatever it
  was.
- **Test every schema change with a migration test.**
- **If ownership is a field rather than a path, that field is the entire
  security boundary.** Rules must check it on both the stored record and the
  incoming one - without the second, a client rewrites it and plants a record
  in someone else's account. And **every query must filter on it**, since
  per-row rules cannot be evaluated over a whole collection. Route all access
  through one wrapper that has no method omitting the filter.
- **Give reads their own rule; never fold them into one read-write rule.** A
  combined rule needs a disjunction to cover creates, which leaves a branch
  constraining nothing - the query proof then fails and **every query is denied
  while writes still succeed**. Test rules against an emulator; a
  permission-denied on a read looks identical to rules that were never
  deployed.
- **A missing index fails at runtime, not at build** - deploy indexes and rules
  together, always.
- **No cascade you did not write.** Document stores have no foreign keys;
  anything cascade-shaped is written by hand, so deleting a parent means
  explicitly handling its children.

## 7. Testing

- **Static analysis must pass with zero findings** before any task is done -
  run it exactly as CI does, with warnings fatal, on every package in the repo
  separately.
- **Never run the whole test suite to verify a change, no exception** - not for
  shared code, not "just before a commit". Scope to what changed, narrowed to
  the single case when one is failing. The full suite is minutes of wall clock
  to re-learn what one scoped file already told you.
- Where tests pay for themselves: pure business logic (high coverage, edge
  cases - empty input, all-identical input, timezone shifts), schema
  migrations, threshold/dedupe/idempotence logic, and any **gating** rule,
  where the test is what proves a restricted path holds no privileged data.
- **Shared setup lives in one test helpers module**, never re-declared per file.
- **A test that passes for the wrong reason is worse than no test.** Verify the
  assertion can fail: break the code deliberately once and watch it go red.
- If a redesign or migration suspends part of the suite, say so **in writing**
  with what it does not suspend and what pays the debt back - an undated
  suspension quietly becomes permanent.

## 8. Tooling, scripts and secrets

- **One task runner, pinned to an exact version.** A global and a local copy at
  different versions runs one version's code against the other's templates.
- **Every script's body lives in its own file; the runner config only names
  it.** Inline multi-line bodies get echoed around each run and bury the output
  they introduce; a file is also the only version that can be linted and run
  directly. Adding a command is a script plus one line.
- **Write shell scripts to the POSIX subset unless the shebang says otherwise**
  - `set -o pipefail`, `[[ ]]` and `local` are syntax errors under dash, and
  macOS will not catch it because its `/bin/sh` is bash under another name.
  Check with `dash -n <script>`.
- **Two setup entry points at most**: the normal one, and the one that also
  clears the expensive build cache - separate because that cache costs a full
  cold build every time. Don't add a third clean-shaped command.
- **Secrets live in gitignored env files with committed key-only templates.**
  Read configuration through exactly one module - the only place the raw
  environment is touched.
- **Never read the secret files.** Not with a file read, not with `cat`/`grep`,
  not "just one field" - anything read there is copied into a transcript that
  outlives the session, and the harm is the copy, not the size. Watch for the
  same secret under another name: generated build configs that embed every
  define, encoded, in a line that looks like build settings. Reading file
  *names* is fine; contents never. A tool deny list is a guard rail - the rule
  is the guarantee.
- **Version and build numbers are edited in the manifest, never passed as a
  flag.** A build whose version exists nowhere in git is one the repo cannot
  account for afterwards. If CI bumps it, CI rewrites the file and pushes that
  commit **after** the upload succeeds: a bump with no build is a gap in the
  numbering, a build with no commit is the failure the rule exists to prevent.

## 9. Design and accessibility (any UI)

- **Mockups are reference, not authority.** Where a mockup and the written
  rules disagree, the rules win, silently - build what the rules say and tell
  the owner what was overridden. A mockup is for hierarchy, rhythm, density,
  where the eye lands, how a component is composed. Take that; leave the
  tokens. This is written down because an AI design tool, asked for an exact
  palette, answered with its own - tonal ramps running to white, invented
  colour roles, a measured accessible scale quietly dropped - and then ignored
  the correction. A tool that answers a palette with its own palette cannot be
  the source of truth for one.
- **Never approve a label that only fits at the mockup's metrics.** If the
  product ships a different font than the mockup was drawn in, the mockup's
  measurements are not the ones that render.
- **Animations stay calm**: fade / scale / slide, short, gentle curves. Nothing
  flashes, strobes or pulses - not for a "delightful" micro-interaction, not
  ever.
- **Colour is never the only signal.** A state told by colour is also told by
  an icon, a label or a shape.
- **Charts hide their marks from screen readers and expose a summary instead.**
  A chart without a text label is unreadable to a screen reader.
- **Every user-facing string goes through the localization files**, every
  locale, every time, reached through one accessor.
- If the product has a default theme its audience depends on (dark-first, no
  pure white, no bundled font), write it down as its own rule - a default
  nobody stated is a default the next change breaks.

## 10. Documentation and rule files

- **`AGENTS.md` is an index, not the rulebook.** It holds what applies to every
  change; everything else splits into `docs/rules/<TOPIC>.md` plus one
  `AGENTS.md` per feature, with a routing table saying which file to read for
  which work. Read the file whose trigger matches - not all of them. An
  always-loaded rulebook that grows past a screen stops being read.
- **Every rule the owner states goes into the right file in the same turn it is
  stated**, with its reason, before the work it governs. A rule that lives only
  in a chat is gone by the next session. Applies everywhere -> the index;
  belongs to one feature -> that feature's file.
- **Keep a `DECISIONS.md` of things tried and reverted.** Each entry is
  something that WAS done the other way and cost something. Read it before
  changing a rule that looks arbitrary; it is the difference between a decision
  and an accident.
- **Keep a `PENDING_SETUP.md` for anything that looks unconfigured** - keys,
  IDs, accounts, products - so "is this broken, or just not set up yet?" has
  one answer.
- **The README records which major version of each shared internal library the
  project consumes.** A lockfile or submodule gitlink pins a *commit*; it does
  not say which generation, major or module the code actually imports. Without
  that line, a change to the shared library cannot know who it breaks, and the
  only way to find out is to ship. Move the line in the same change as the
  upgrade.
- **Every document in the repo is written in one language, in full** - no mixed
  paragraphs, no untranslated quotes. User-facing strings are the exception and
  live in the localization files.
- **Explaining a change means showing before and after** - the old code and the
  new one, then what the difference does. A description of a diff is the reader
  taking your word for it; the diff is the reader checking.
- **An explanation goes straight to the point.** Answer what was asked, then
  stop. Length is not thoroughness.

## 11. Git

- Conventional commits (`feat:`, `fix:`, `chore:`, `docs:`), **no parenthetical
  scope**: write the scope inline after the colon, then a dash -
  `feat: medications - a screen per medication`, never `feat(medications): ...`.
  The scope names the part of the product touched, never the tool or the agent
  that made the change.
- **No trailers in the commit message** - no `Co-Authored-By`, no generated-by
  footer, nothing naming the tool. The message says what changed and why, and
  ends there.
- **Commit freely; never push.** Every commit - main repo and every submodule
  alike - stays local until the owner explicitly asks for a push; they review
  and push themselves. Never run `git push` on your own initiative, even after
  a commit that would ordinarily be pushed as a matter of course.
- **Any edit to a `AGENTS.md` or a rules file gets its own commit, right away**
  - never folded into an unrelated change. Message:
  `docs: update docs - detail is <what changed>`.
- **PR descriptions are short bullets, never prose**: a one-line summary, then
  bulleted groups, one line per bullet, about a screen in total. The *why*
  belongs in the commit message and the code comment, which reviewers reach
  from the diff. No mention of the tool anywhere in a PR description.

---

# Part 2 - Flutter and Dart only

Everything below assumes a Flutter repo. Skip this half entirely otherwise.

## 12. Repo layout

```
lib/
  core/                  # cross-cutting only, NO business logic
    bootstrap/           # everything that runs before runApp
    constants/           # cross-feature constants classes
    db/                  # AppDatabase (composes feature-owned tables)
    env/                 # the ONLY place String.fromEnvironment appears
    logging/             # logger + crash reporter
    router/              # routes + shared navigation rules
    theme/               # palette, type scale, ThemeData
    utils/               # utils shared by more than one feature
    widgets/             # the ONLY widgets/ folder under core/
  l10n/                  # ARB files (+ generated output)
  features/
    <feature>/
      domain/            # pure Dart, no Flutter imports
        entities/ enums/ repositories/ services/
      data/
        tables/ repositories/ datasources/
      presentation/
        controllers/     # notifiers: view state + orchestration
        screens/
          <name>_screen/ # <name>_screen.dart + its part files, together
        widgets/
      providers.dart     # dependency wiring for the feature
test/features/           # mirrors lib/features
test/helpers/            # shared setup + navigation helpers
packages/<design_system>/  # the design system, its own repo (submodule)
```

**Dependency rule:** `presentation -> domain <- data` inside a feature. Across
features, import only another feature's `domain/` or its `providers.dart` -
never its `data/` or `presentation/`. Database tables live with their feature;
`core/db` only composes them. **One folder per screen**; screens never sit
loose in `screens/`. A widget a second feature needs moves to `core/widgets/`
immediately.

## 13. Stack defaults

- **State**: Riverpod. Pick one and never mix state families.
- **Local DB**: Drift (SQLite). On-device is the source of truth for user data;
  cloud is a synced copy, never the only copy.
- **Navigation**: go_router. Plain pushes live at the call site; a move with a
  *rule* attached (an order of screens, a condition deciding where the user
  lands) goes in a shared `NavigationUtils` so the second caller cannot
  reimplement it without the rule.
- **Sizing**: `flutter_screenutil`, one design size, `minTextAdapt: true`.
- Prefer boring, well-maintained pub.dev packages (>1k likes, recent commits).
  Ask before adding any new third-party service or SDK.

## 14. The design system package

A **separate git repo, checked out as a submodule**, wired in as a path
dependency, with exactly one import - its index.

### The admission test - both must be true, there is no third case

1. **It takes every user-facing string as a parameter.** No localization
   lookup, no ARB, no hardcoded English. Tooltips and semantics labels count.
2. **It imports nothing from the host app.** No repository, provider, router,
   domain entity, analytics or logger. If a widget must know a domain concept
   to render, the app keeps that widget and passes the package a plain value
   type instead.

Failing either test is not a reason to weaken the rule - it is the answer: the
widget stays in the app and composes the package's pieces.

### Naming, generations, layout

Everything carries a short **prefix** and a **generation suffix**.

| Thing | Rule | Shape |
| --- | --- | --- |
| Widget class | prefix + name + generation | `XyBannerV2` |
| Enum / value type | same | `XyButtonVariantV2` |
| Static-only holder | same, `final class` | `XyChartStyleV2` |
| Presenter function | `show` + prefix + name + generation | `showXyBottomSheetV2` |
| File and folder | snake_case of the class | `xy_banner_v2/xy_banner_v2.dart` |
| Anything in `core/` | prefix + name, **no suffix** | `XySpacingConstant` |

The suffix is the **generation of the design system**, not a version of one
widget. A widget is never bumped alone; a new generation gets its own folder
and both ship at once while apps migrate.

- **One generation, one product. A new project never adopts an existing
  generation - it reads the highest one in the package and builds `n+1`.** If
  the latest is `vN`, the joining product starts `vN+1`, copies forward
  whatever ideas it wants, and leaves every existing folder untouched. A
  project already on a generation stays there; this fires when a product
  *joins*, never as a reason to migrate one that has shipped.
  - This is what makes "a frozen generation stays frozen" enforceable rather
    than aspirational. A generation with two consumers has no frozen state:
    the first edit made to suit product B lands in product A's shipped UI, and
    the only way to find out is to ship it.
  - The cost is real and accepted - two products both needing a button write
    it twice. Same trade the admission test makes: duplication is cheaper than
    coupling, and `core/` already carries what genuinely is shared.
- **Every project records the generation it renders in its own README**, one
  line near the top, moved in the same change as any generation move. The
  submodule gitlink records which *commit* an app pins, never which *folder* it
  imports, so nothing on the package side can tell who a change to a generation
  breaks unless each app writes it down. Keep the matching generation -> product
  table in the package's own rules file, and add a row when a generation is
  created, not when it is finished.
- **No file in one generation may import from another, either direction.**
  Generations rest on incompatible premises (dark-only with chrome the body
  scrolls behind, vs light-and-dark chrome taking real layout space); sharing
  drags one product's chrome into the other's.
- **`core/` is the only shared part** - raw dimensions, no look. Adding a
  getter there is additive; changing one is a change to every shipped app.
- **A frozen generation stays frozen.** Copy the idea forward; never edit an old
  generation to suit a product it does not ship in.
- **Every generation-scoped name carries its suffix, including extension
  members** (`theme3`, `semiBold3`), so a file importing the index gets both
  generations without either shadowing the other.

**One folder per widget.** Adding one is: one folder, one file, one `export`
line in the generation's index. Never a grouping folder (`buttons/`,
`charts/`) - the flat list keeps the index mechanical. `core/` is not a dumping
ground: a file belongs there only if it has no look at all and every future
generation would use it unchanged.

### The palette stays in the app

Palette, type scale and `ThemeData` live in `lib/core/theme/`. The app builds a
theme extension from its own colours and registers it on
`ThemeData.extensions`; package widgets read `context.colorScheme` /
`context.textTheme` / that extension and **never name a colour**. That is what
makes the package droppable into the next project.

A static holder needing a colour or a text style **takes a `BuildContext`** - a
static getter cannot reach the theme, and a value baked in at authoring time is
exactly the coupling the package exists to avoid. Only pure dimensions stay
parameterless.

The extension asserts when the app forgot to register it, so **a widget test
pumping a bare `MaterialApp` fails loudly**. Pump the app's real theme via a
shared `pumpApp`, which also pins the view to the design size - the default
800x600 test surface scales `.sp` fonts ~2x and breaks layout.

The package must `flutter analyze` **standalone**. If it only analyzes from
inside the app, an app dependency leaked in.

## 15. UI primitives - never a raw Material widget in feature code

| Need | Primitive | Never |
| --- | --- | --- |
| Card | the card primitive | raw `Card` |
| Icon | the icon primitive, always an explicit resolved size | raw `Icon` |
| Labeled button | one button, look chosen by a `variant` prop | `FilledButton`/`OutlinedButton`/`TextButton` |
| App-bar icon action | the app-bar button primitive | `IconButton` in an app bar |
| Divider | the divider primitive | Material `Divider` |
| Snack bar | the snack-bar presenter | `ScaffoldMessenger.showSnackBar` |
| Dialog | the dialog presenter | raw `showDialog` |
| Bottom sheet | the sheet presenter | raw `showModalBottomSheet` |
| Screen + bottom action | the action-view primitive | hand-rolled Column + Spacer |
| Filter over a list | the collapsing-filter scaffold | hand-rolled Stack + pinned bar |

`IconButton` is still fine inside content - list rows, text-field suffixes.

Each row is a bug that shipped:

- **`Card` carries an invisible `EdgeInsets.all(4)`** - a list whose separator
  said 8 came out 16, and sat 8 narrower than the next tab. The card primitive
  is colour + radius and nothing else: **no padding, no margin**. Spacing
  between cards belongs to whoever places them; the inset inside belongs to
  whatever they hold.
- **`Divider` reserves a whole `height` (16 by default) around a 0-thickness
  rule** - a "1px line" silently costs 16 of vertical space and two rows drift
  apart for reasons nothing at the call site explains. The primitive occupies
  exactly the line it draws. Draw it **between items only**; a rule on a
  container's own edge reads as a border it does not have.
- **A `ScaffoldMessenger` renders into the nearest registered `Scaffold`**, so a
  route without one (a modal sheet) sends its messages to the screen
  underneath, where the very sheet that raised them covers them up. Draw into
  the root `Overlay` instead. Widget tests do not catch this: `find.text`
  matches a widget the user cannot see - assert on the card the presenter draws.
- **A sheet presenter must use the root navigator**, or sheets slide *under* the
  bottom navigation bar.
- **Padding is one fixed value for every button variant**, so filled, outlined
  and text buttons never sit at different sizes side by side; a `size` prop
  multiplies padding, icon and gap together, so a smaller button is a scaled
  version of the same shape. Lay icon + label out yourself rather than using
  Material's `.icon` constructors, whose per-variant padding is what makes two
  brand buttons sit differently.
- **Sheets and dialogs are a widget class + a `.show()` extension**, never a
  top-level `showFooSheet()`. Name it `<Widget>Ext`, call it
  `FooSheet(...).show(context)` - presentation stays off file-scope functions
  while still routing through the shared presenter.

## 16. Spacing, colour and type

- **Every dimension goes through the spacing constants class**: `w*`
  horizontal, `h*` vertical, `r*` square/radius, `sp*` font. Never a raw
  literal in a widget. A design measuring 13 becomes 12 - snap to the ladder.
- **Every colour comes from the palette class**; no hex read off a mockup.
- **Every text style comes from the type scale.** No inline `TextStyle(...)`,
  no `context.textTheme` at a call site. **Every `Text` carries an explicit
  `style:`** - an ambient default is invisible at the call site and drifts
  silently when the theme changes.
- **No widget holds spacing logic - one content-padding class does, and nothing
  else.** Not the scaffold, not the app bar, not a screen. Any inset another
  widget pads by is a static on that class; a widget keeps only its **own
  intrinsic size**.
- **One named gap per job**: one `listItemGap` for every list's item spacing
  (and for the gap from a filter row to its list), one `sectionGap` for
  stacking cards on a screen.
- **The scaffold adds no padding at all** - no SafeArea, no insets. Every screen
  pads its own scrollable, **inside** the scrollable, so content scrolls behind
  translucent chrome. A scaffold-level SafeArea plus a body that also clears a
  floating bar is how insets get applied twice.
- **Insets come off the view, not the ambient `MediaQuery`.** `Scaffold` strips
  its body's top padding when there is an app bar and subtracts the bottom
  inset when there is a bottom bar, so the same read returns different numbers
  above vs inside the body, and content lands *under* the floating bar. Feature
  code reads the padding class; the padding class reads the view. **A bug here
  costs 0 pixels in a test whose view has no insets** - give the test view a
  notch.

## 17. Dart style

- **Never `var`.** Explicit types everywhere; prefer `final`/`const` with the
  type written out. Explicit types keep reviews clear and prevent silent
  inference bugs.
- **No standalone top-level functions.** Every function lives in a class - a
  widget method, or a static on a `*Utils` class. The sanctioned exceptions are
  a widget's `.show()` extension and the design system's low-level presenters.
- **No `_buildX()` methods for UI.** A `Widget _buildHeader()` inside a `State`
  is a fake split - Flutter cannot scope the rebuild (no const, no keys), so
  the whole parent rebuilds. Extract a real widget class.
- **Split big presentation files with `part of`**, named
  `<main_file>_<widget>.dart`, beside the file they belong to.
- **`abstract final class` is not a thing here - plain `final class`** for
  static-only holders; `abstract interface class` for `domain/repositories/`
  and `domain/services/` contracts.
- **No business logic in widgets.** View state and orchestration (state
  machines, save/export/delete flows, filtering) live in a controller; screens
  are `ConsumerWidget`s that watch state and call controller methods. Dialogs
  and snack bars stay in the widget.
- **Repositories**: interface in `domain/`, implementation in `data/`. Return
  domain models, never Drift rows.
- **`main.dart` holds `main()` and nothing else**; startup work lives in
  `AppBootstrap`, which guards each step separately (Part 1 section 4) and runs before
  `runApp`, where an unhandled throw stops the app from starting at all.

## 18. Flutter testing

- `melos run analyze` (or the repo's equivalent) with `--fatal-infos`, zero
  findings, app **and** design system package separately.
- Scope every run: `flutter test test/features/<x>/<y>_test.dart`, narrowed
  with `--plain-name`. Never the whole suite.
- `pumpApp` supplies the real theme **and** pins the view to the design size.
  A bare `MaterialApp` asserts; the default surface breaks `.sp` layout.
- Widget tests do not prove visibility - `find.text` matches a widget the user
  cannot see. For anything drawn into an overlay, assert on the presenter's own
  widget.
- Give the test view real insets when testing anything that reads padding;
  the default view has none, so the bug costs 0 pixels.

## 19. iOS/build notes worth writing down

- Native dependency managers: pick one, record which plugins are exceptions and
  why, and don't re-litigate the choice without new facts - record the numbers
  (cold build time, upstream deprecation dates) in `DECISIONS.md`.
- When a build fails in a way the code cannot explain - a precompiled module
  refused, a header resolving to a version you no longer depend on, a failure
  that comes and goes on one commit - reach for the cache-clearing setup
  command; it is almost always right after a native dependency moved.
- Archiving from the IDE cannot pass `--dart-define-from-file`, and the
  resulting crash names nothing to do with the missing flag. Build through the
  repo's own script, and never "simplify" a release lane back into the IDE's
  archive step.

---

## Before calling anything done

1. Static analysis passes with zero findings, every package separately.
2. Scoped tests for what changed - never the whole suite.
3. Diff check: a magic literal, a hardcoded user-facing string, a `catch` with
   no log, an inferred type hiding what a value is, a cross-boundary import,
   a constant bolted onto a model, a comment longer than 3 lines. In Flutter,
   add: a raw `Card`/`Icon`/`Divider`, a `var`, a `_buildX()`, a `Text` with no
   explicit `style:`.
