# Bootstrap prompt — new project, same rulebook

You are setting up a brand-new project. Before writing any product code, build the
**documentation architecture** in section 1, because it is what governs every later
change. Everything below is ported from a shipped app of mine; where a rule carries
a war story, the story is the reason it is not up for renegotiation.

---

## 0. What I'm building

<!-- REPLACE THIS BLOCK -->
Product: <one paragraph — who it's for, the core promise, the platform>
Stack: <e.g. Flutter iOS-first / Next.js / FastAPI>
Backend: <e.g. Firebase / Supabase / none>
Monetization: <e.g. subscriptions via RevenueCat / none>
<!-- END REPLACE -->

Ask me before adding ANY third-party service, SDK or analytics tool that isn't
listed above. Prefer boring, well-maintained packages (>1k likes, recent commits)
over clever solutions — and when you take an exception to that bar, write down why
in the same turn.

---

## 1. Meta-rules — how the rulebook itself works

- **`CLAUDE.md` is an index, not the rulebook.** It holds only what applies to
  *every* change, plus a routing table mapping "working on X" → "read file Y".
  Everything else is split into `docs/rules/<TOPIC>.md` and read only when the work
  touches it. Never read them all.
- **Every rule I state goes into the right file, in the same turn I state it** —
  with its reason, before the work it governs. A rule that lives only in chat is
  gone by the next session. App-wide → `CLAUDE.md`; one feature →
  `<feature>/CLAUDE.md`; one topic → `docs/rules/<TOPIC>.md`.
- **Any edit to a `CLAUDE.md` or a `docs/rules/` file gets its own commit, right
  away** — never folded into an unrelated change. Message:
  `docs: update docs - detail is <what changed>`.
- **Product non-negotiables are a numbered list in `PLAN.md`, and every rules file
  cites them by number** ("Hard rule 12", "hard rules 1, 2, 8"). One list, one
  number per rule, referenced from everywhere — that is what stops the same
  constraint being restated in four files and drifting in three of them.
- **`docs/rules/DECISIONS.md` records what was tried and reverted, with what it
  cost.** Read it before changing a rule that looks arbitrary. A rule with no
  recorded reason is a rule the next session "cleans up".
- **Numbers live in code, and docs point at the field rather than repeating the
  value.** My last project's doc says a gap is 8 where the class says 12 — a number
  copied into a sentence goes stale silently. Write "`listItemGap`", not
  "`listItemGap` (8)", anywhere outside the class that defines it.
- **Every document in this repo is written in English, in full** — no mixed
  language, no untranslated quotes. User-facing strings are the exception: they live
  in the i18n files and ship in every locale.

## 2. How you talk to me

- **Explaining a change means showing before and after** — the old code and the new
  one side by side, then what the difference does. A description of a diff is me
  taking your word for it; the diff is me checking.
- **Go straight to the point, no rambling.** Answer what was asked, then stop.
  Length is not thoroughness.

## 3. Workflow rules

- **The lint/analyze command must pass with zero findings** before any task is
  considered done. It is what CI runs. Write the exact command into
  `docs/rules/COMMANDS.md` on day one.
- **Never run the whole test suite to verify a change, no exception** — not even one
  touching shared code, not "just before a commit". Scope to what changed. The full
  suite is minutes of wall clock to re-learn what one scoped file already told you.
- **Never read secret files** (`env/`, and any generated config that carries the
  same values under another name). Not with Read, not with `cat`/`grep`, not "just
  one field". The harm is the copy landing in a transcript, not the size. Commit
  **key-only `*.example.json` templates** instead, so "what keys exist" is
  answerable without values. A tool-permission deny list is a guard rail, never the
  guarantee — the shell can always route around it; the rule is the guarantee.
- **Commit style: conventional commits** (`feat:`, `fix:`, `chore:`, `docs:`). No
  parenthetical scope — scope goes inline after the colon, then a dash:
  `feat: medications - a screen per medication`, never `feat(medications): ...`. The
  scope names the part of the app touched, never the tool that made the change. No
  `Co-Authored-By` trailer.
- **Commit freely; never push.** Everything stays local — app repo and submodules
  alike — until I explicitly ask.
- **PR descriptions are short bullets, never prose**: one-line summary, then
  bulleted groups, about a screen total. The *why* belongs in the commit message and
  the code comment, which reviewers reach from the diff. No mention of Claude
  anywhere — no attribution footer, no tool name.

## 4. Architecture

Feature-based clean architecture, fixed subfolder names inside every feature:

```
<feature>/
  domain/       # pure — no framework imports: entities/, enums/, repositories/ (interfaces), services/
  data/         # tables/, repositories/ (implementations), datasources/
  presentation/ # controllers/ (state + orchestration), screens/<name>_screen/, widgets/
  providers.dart
```

- Dependency rule: `presentation → domain ← data`. Across features, import only
  another feature's `domain/` or `providers.dart` — never its `data/` or
  `presentation/`.
- `core/` is cross-cutting only, **no business logic**. Tables live with their
  feature; `core/db` only composes them.
- Create a layer folder only when it gets its first file — no empty placeholders.
- One `<feature>/CLAUDE.md` per feature, loaded when work is in that directory.
- **Repositories: interface in `domain/`, implementation in `data/`, returning
  domain models — never database rows.**

---

## 5. The design system — clone it, then open a NEW generation

The design system is a separate repo, shared across my products, checked out as a
**git submodule**:

```bash
git submodule add -b main https://github.com/DAMHONGDUC/flutter-system-design-kit packages/flutter-system-design-kit
```

Wire it in as a path dependency. There is exactly one import for the whole package,
and it is the index: `import 'package:system_design/index.dart';`

**This product does not render an existing generation — it gets its own.**

1. List `packages/flutter-system-design-kit/lib/` and find the highest `v<N>/` folder. As of
   today that is `v3`, so the new one is `v4` — but check, don't assume.
2. **Copy `v2/` into `v<N+1>/`** (v2 is the generation this rulebook was written
   against), rename every symbol's suffix, give it its own `index.dart`, and export
   that index from `lib/index.dart` alongside the existing generations.
3. Every widget is `Sd<Name>V<N+1>` in its own folder `v<N+1>/sd_<name>_v<N+1>/`.
   Adding one is a folder, a file, and one `export` line — nothing else.
4. **Read `packages/flutter-system-design-kit/WIDGET_RULES.md` first.** It is the authority on
   what may go in and how it must be written; sections 5–6 here only summarise it.

Rules the new generation inherits:

- **All generations ship at once and none imports another.** No file under
  `v<N+1>/` may import from `v3`/`v2`, or the reverse. They are built on different
  premises (v2 is dark-only with frosted chrome the body scrolls behind; v3 ships
  light and dark with opaque chrome that takes real layout space), and sharing a
  token drags one product's look into another's. Repeating a widget name across
  generations is fine — the suffix keeps `SdButtonV3` and `SdButtonV4` in one file
  without collision.
- **Every generation-scoped name carries its suffix, including extension members.**
  `context.sdTheme3` / `.semiBold3` exist precisely so a file importing the index
  gets both generations' extensions without either shadowing the other. An
  unsuffixed member on a generation's extension is a bug, not a convenience.
- **An older generation is frozen for this work.** It is what a shipped app is
  rendering. Copy the idea into the new generation; never edit the old one to suit a
  product it does not ship in.
- **`core/` is shared and is the only shared thing** — raw dimensions any generation
  measures in, no look, no suffix. Adding a getter is additive and fine; changing or
  removing one is a change to a shipped app. It is not a dumping ground: a file
  belongs there only if every future generation would use it unchanged. When in
  doubt it goes in the generation folder — moving down into `core/` later is cheap,
  pulling it back out after two generations depend on it is not.
- **Even the glass/blur helper is copied, not shared.** Each generation declares its
  own support gate and its own settings, because tuning differs per product. The
  check is four lines; copying it is cheaper than the coupling.
- **The submodule is its own repo**: commit inside it separately, same commit style,
  and never push it either.

## 6. What may go in the package (the admission test)

**Both halves must hold. There is no third case.**

1. **It takes every user-facing string as a parameter** — no i18n lookup, no
   hardcoded English. Tooltips and semantics labels are user-facing strings too.
2. **It imports nothing from a host app** — no repository, no provider, no router,
   no domain entity, no analytics, no logger.

Failing either is not a reason to weaken the rule; it is the answer: the widget stays
in the app and composes the pieces from the package. If a widget needs a domain
concept to render, the app keeps the widget and hands the package a plain value type.

- **The palette is NOT in the package — the app owns it.** Colours, text styles and
  the theme live in the app's `core/theme/` and are handed to the design system by
  registering a theme extension. Package widgets read from context and never name a
  colour. The extension getter **asserts when the app forgot to register it**, so a
  widget test pumping a bare app fails loudly — pump the app's real theme.
- **Nothing in the package hardcodes a colour, a font size or a dimension.** Every
  value comes from the theme extension, the text styles, or the spacing class.
- **A static holder that needs a colour or a text style takes a `BuildContext`** —
  a static getter cannot reach the theme, and a value baked in at authoring time is
  exactly the coupling the package exists to avoid. Pure dimensions stay
  parameterless.
- **The package analyzes standalone** (`flutter analyze` inside it, without the
  app). If it only analyzes from inside an app, an app dependency leaked in.
- **Four greps catch almost every violation** before a commit: a literal colour, a
  raw number in a widget, a hardcoded string, and an import that starts with
  anything other than the framework, a declared dependency, or a sibling widget.
- **One folder per widget, flat.** Never a grouping folder (`buttons/`, `charts/`) —
  the flat list with one folder each is what keeps the index mechanical.

## 7. Code rules

- **No business logic in views.** View state and orchestration (state machines,
  save/export/delete flows, filtering) live in a controller; views watch state and
  call controller methods. Dialogs and snackbars stay in the widget.
- **Every action logs, and it logs the DATA with it.** Every API call, every tap,
  every submit: a line going in with what was sent, a line coming out with what came
  back. `"Sync failed"` answers nothing; `"Sync failed — {collection: attacks,
  pushed: 12}"` does.
- **Every `catch` logs before returning its substitute** — wherever it sits, not
  just in controllers. A block that turns a failure into `null`/`false`/an enum
  holds the only copy of what went wrong. Log the **full error object and the
  response**, never a hand-written string: an exception's `code`/`details` and a
  call's body are exactly what is needed and exactly what a `toString()` throws away.
  - **Catch the broadest error type, not just the exception type.** In Dart,
    `on Exception` lets every `Error` subtype (`StateError`, `TypeError`, a failed
    cast) through untouched *and* unlogged — the unexpected ones, precisely.
  - **Successes are logged too**, so an empty console means nothing ran rather than
    everything worked.
  - **No closure-taking log wrapper** (`logger.guard(action)`): a combinator hides
    the flow. Plain inline try/catch, every time, even though it is more verbose.
  - Two narrow exemptions: a widget re-catching what its controller already logged
    (say so in a comment), and a user cancellation, which is not a failure.
  - **This rule exists because three features failed silently at once**: an API
    answered every call 401 and the app said "no data", a backend call was refused,
    and neither left a line anywhere. A caught error is invisible by construction.
- **Analytics goes through one typed class**, a method per event, so the full
  inventory of what we send is one file. Never call the SDK directly and never type
  an event name at a call site. Events sit next to the matching log line in a
  controller, never in a view's build. Sensitive data never becomes a parameter.
- **Crash reporting goes through one reporter class**, alongside the log line that
  serves the debug console. `domain/` stays pure — report from the layer that catches.
- **The entry point holds the entry point and nothing else.** Startup work lives in
  a `Bootstrap` class, so the entry point reads as a list of what happens rather
  than how.
- **`Bootstrap` guards each step separately, never the whole function.** Its
  concerns are independent, and one try around all of them lets the first failure
  skip everything after it — including the crash reporting that would have named it.
  **Crash reporting initialises first**, so it is up before anything else can fail.
  Anything here runs before the app starts, where an unhandled throw does not show
  an error screen — it stops the app from starting at all.
- **Extract specialised logic on its FIRST use, not its second** — date and duration
  math, parsing, formatting, axis arithmetic, filename building. A view's job is
  layout and a controller's is orchestration, so a calculation inside either is in
  the wrong place whether or not anything else needs it yet. Shared → `core/utils/`;
  real domain logic → the feature's `domain/services/`.
- **Anything shared gets extracted; the second copy is the trigger**, not a later
  cleanup. Duplicated UI becomes a widget, duplicated logic becomes a `*Utils`
  method. Same in tests: shared setup and navigation helpers live in `test/helpers/`,
  never re-declared per file.
- **A widget used by more than one feature moves to `core/widgets/` immediately** —
  and that is the only `widgets/` folder in `core/`. Otherwise the importer reaches
  into another feature's `presentation/` and breaks the dependency rule. A shared
  widget may import a feature's `domain/` or `providers.dart`; feature → feature
  `presentation/` is never allowed.
- **One subject, one utility class.** All date and time arithmetic in one place, not
  a second date-shaped class — two classes is how the same call site ends up
  computing midnight two different ways.
- **Constants live in their own `*Constant` class**, never bolted onto a model,
  entity, controller or view: a number a class does not itself use is not that
  class's business. Cross-cutting → `core/constants/` (free limits, every
  preferences key so a collision between two features is visible rather than
  silent, sync and export constants). The exceptions: a component's own intrinsic
  size, a canonical empty instance of a type, and a constant inside the algorithm
  that *is* the class.
- **Never use implicit types (`var`/`auto`).** Explicit types everywhere,
  `final`/`const` where possible — it keeps reviews clear and prevents silent
  inference bugs.
- **No standalone top-level functions** — every function lives on a class. The one
  sanctioned exception is a widget's own `.show()` extension and the low-level
  presenters it calls.
- **No `_buildX()` helper methods for UI.** A `Widget _buildHeader()` inside a
  `State` is a fake split — the framework cannot scope the rebuild. Extract a real
  widget class.
- **Small components, extract at ~80 lines.** Composition over config flags: two
  booleans selecting three looks should be one enum prop.
- **Split big presentation files** into siblings joined by the language's
  partial-file mechanism, named `<main_file>_<part>.<ext>`. One folder per screen.
- **Declarations first, blank line, then logic.** No declare-run-declare.
- **Comments: short and plain, max 3 lines**, saying *why* not what. A multi-point
  comment is a bullet list, one `-` line per point — never a run-on `does X, and
  also Y, but watch out for Z`. If it needs a 4th line, the longer rationale moves
  into the doc comment of the function it belongs to.
- **Shared navigation lives in one `NavigationUtils`.** A plain "push this route"
  belongs at its call site; a move with a *rule* attached — an order of screens, a
  condition deciding where the user lands — goes in `NavigationUtils`, so the second
  caller cannot reimplement it without the rule.
- **Every user-facing string goes through the i18n files**, all locales, every time.

---

## 8. Spacing — one class owns every number

**The one law: no widget and no screen holds spacing logic —
`SdContentPaddingV<N>` does, and nothing else.** Not the scaffold, not the app bar,
not a screen. Any inset another widget pads by is a static on that one class. The
only thing a widget keeps is its **own intrinsic size** (a bar's height, a badge's
max count, a card's radius) — what the widget *is*, not configuration about it.

Below it sits `SdSpacingConstant` in the package's `core/`: every screenutil
dimension, one home, **no version suffix**. Naming is unit prefix + design-size
value: `w*` horizontal, `h*` vertical, `r*` square/radius, `sp*` font. Getters, not
consts — screenutil resolves at runtime. **No raw `16.w` / `12.h` / `20.r` in any
widget, ever.** A mockup measuring 13 becomes 12: snap to the ladder rather than
adding a rung.

**The fields, and why each exists** (values are v2's — change one only for a stated
reason, in the doc comment):

*The screen frame*
- `horizontal` (16) — the gutter either side of all content.
- `topGap` (8) — app bar to first item. **A separate field from the bottom on
  purpose**: breathing room under chrome and thumb room above the home indicator are
  different problems, and each must move without dragging the other.
- `bottomGap` (16) — last item to whatever is below it.
- `screen(context, {floatingNav})` — gutter + `top` + `bottom`, the whole thing.
- `fullBleed(context, {floatingNav})` — same vertical insets, no gutter, for rows
  that inset themselves. Adding the gutter on top of theirs pushes them off the grid
  the rest of the app sits on.

*Rhythm inside the content*
- `listItemGap` (12) — between two items of the same list. **One number for every
  list in the app**; three screens spelling the same number out separately is three
  chances to disagree. Lists of self-insetting rows take **no** gap and sit flush.
  The gap from a filter row down to its list is this one too — a filter sits above
  the list like one more item above the first, not a bespoke number.
- `sectionGap` (20) — between two whole cards/sections. A distinct section, not a
  repeated row, so it gets the roomier number.
- `sectionHeader({first})` — a heading's own insets, `first` dropping the top gap
  because the screen's `topGap` already placed it (adding both is what made one
  screen start visibly lower than another). Its gutter is the *list's*, so the
  heading lines up with the rows under it.
- `button` — the one padding every button variant wears, so filled, outlined and
  text buttons never come out different sizes next to each other.
- `pinnedActionsGap` (16) — above a pinned bottom action. Its own field, not
  `bottomGap`: that one is the air *below* the last item, and pinning created a
  second edge on the side the content arrives from. Equal to it on purpose.

*Chrome the content must clear — port only what this product actually has*
- `appBarInset(context)` — status bar + toolbar **while the bar is frosted and the
  body passes behind it**; `0` when the bar is opaque, because the scaffold already
  subtracted it. Use it only to *align* something to the bar; content wants `top`.
- `top(context)` = `appBarInset` + `topGap`.
- `bottom(context, {floatingNav})` — `floatingNav: true` on tab screens whose
  content scrolls behind a floating nav; everything else takes `detailBottom`.
- `detailBottom(context)` — the device's safe area **floored** at `minDetailBottom`
  (20), and **deliberately not `bottomGap` on top of it**: a device reporting 34
  already gives more room than the floor asks for, and stacking a gap on a generous
  inset makes a detail screen look like it ends early.
- `floatingBarHeight` (56) and `floatingBarRadius` (**derived**, half the height).
- `floatingBarHorizontal` (24) — side margin shared by every floating bar.
- `navBarOffset(context)` — the device's bottom inset **clamped** between 16 and 20.
- `floatingBarInset(context)` = offset + height — a bar's whole footprint.
- `belowPinnedFilterBar(context)` = `appBarInset` + the filter strip's own height.

**The traps — each cost a real bug:**

- **Insets come off the view, not the ambient `MediaQuery`.** The scaffold strips its
  body's top padding when there is an app bar and its bottom when there is a bottom
  bar, so the same read returns different numbers above vs inside the body. A
  body-side caller got the toolbar height where the screen's build got the full
  height (the bar covered the first 47px of content), and got 0 for the home
  indicator where the screen got 34 (the last row of every tab screen ended up
  *behind* the nav pill). Read from the **view** — the inset is a property of the
  window, so that is the one place with a stable answer. **Feature code never reads
  `MediaQuery` for spacing at all.**
- **Never re-add an inset the class already applied.** The scaffold adds no padding —
  no SafeArea, no insets — and every screen pads its own scrollable **inside** the
  scrollable, so content still scrolls behind the frosted bar. A scaffold-level
  SafeArea plus a body clearing a floating bar is how insets double up.
- **Two things that must line up get the value measured ONCE and handed to both.**
  The pinned filter strip takes its top inset as a parameter rather than reading it,
  because a read inside the scaffold body differs from the read at the site padding
  the list — and then the strip and the gap never agree.
- **A floating bar's height is one field, never typed twice.** Ours drifted once (68
  assumed against a 56-tall bar) and the difference was silently eaten out of
  `bottomGap`. Same for the radius: a literal 34 against a 56 bar only looked right
  because the shape clamps it — derive it.
- **A separator occupies exactly the line it draws.** Material's `Divider` reserves
  16 of height around a 0-thickness rule, so a "1px line" costs 16 of vertical space
  and two rows drift apart for reasons nothing at the call site explains. The gap
  around a divider belongs to whoever places it.
- **The default test view has no notch, so every one of these bugs costs 0 pixels in
  a widget test.** A test covering insets must give the view one. Tests must also pin
  the view to the design size — `.sp` on the default 800×600 surface scales fonts
  ~2× and breaks layout.

**What to re-derive for this product.** The copied generation is not a binding.
Where the chrome differs, the field changes and its doc comment says why — that is
what v3 did:
- Opaque app bar → **delete `appBarInset` entirely** and let `top` be `topGap` alone.
- **`topGap` as a `SizedBox` at the top of content rather than padding**, if you
  want it visible at the call site: a gap folded into `screen()` is invisible, and a
  gap added to the bar's height makes the bar measure taller than it draws — which
  is how a docked control ends up mis-set in a row whose height nobody can point at.
- No floating nav → no `floatingNav`, no `navBarOffset`, no `floatingBar*`. Don't
  port dead fields "for later": an unused inset is one more number that can disagree
  with reality.
- Values are fair game (v3 runs `bottomGap` at 24), but change them in the class,
  once, never at a call site.

**A new spacing need is a new field on the class, on its first use** — not a literal
now and a cleanup later. If two call sites would want the same indent, that is the
moment it becomes a field, never a number typed twice.

## 9. Bottom nav — a floating pill, not a Material bar

- **The nav is a floating glass pill over the content, and `extendBody` is
  unconditional** so the body flows behind it and the glass has something to
  refract. Never a `NavigationBar`/`BottomNavigationBar` slab.
- **Its offset off the bottom edge is one field on the spacing class**
  (`navBarOffset`): the device's bottom inset **clamped** between 16 and 20. The
  floor covers a device asking for too little (Home-button phone, most Androids, the
  default test view, an iPad, landscape); the ceiling stops a deep inset pushing the
  pill up the screen. **Write down what the ceiling costs**: a portrait iPhone's
  indicator inset is 34, so the pill lands 14 short and its lower edge sits inside
  the strip iOS reserves for the edge-swipe gesture — a deliberate trade, reversible
  by raising the ceiling.
- **One height for every floating bar**, one radius derived from it. Any bar that
  legitimately differs (one resting on the full safe area rather than clamping) says
  so in a comment.
- **Content clears the pill through the spacing class, never by hand**:
  `floatingNav: true` adds offset + height + `bottomGap`, so scrolling a tab screen
  to its end leaves exactly `bottomGap` of daylight between the last item and the pill.
- **Anything drawn over the app must know the pill is there.** Put a floating-bar
  scope around the branch content so a snackbar in the root overlay clears it.
- **The selection indicator slides, it does not fade.** A 1/N-wide thumb aligned to
  the selected segment, 250ms ease-out — the same 250ms every other piece of chrome
  moves in. No flash, no strobe.
- **Sheets and dialogs go through the shared presenters**, which use the root
  navigator so they cover the nav; a raw modal sheet slides *under* it.
- **Tabs are branches of an `IndexedStack`, so no route is pushed and the navigator
  observer sees nothing** — log the screen view from the shell's `didUpdateWidget`,
  or tab analytics are silently empty.
- **No FAB on a screen with the floating nav.** The pill overlays the content and
  eats the tap. Every tab puts its primary action in the app bar instead.

## 10. App bar, the status bar, and the filter that lifts into it

### The bar itself

- **One app bar widget, reached through the scaffold** — a screen never constructs
  an `AppBar`.
- **The bar is not a glass slab.** Its strip is the app background colour at ~0.65
  alpha over a backdrop blur: no visible edge, no divider, `elevation: 0`,
  `scrolledUnderElevation: 0`, transparent surface tint. Content scrolling behind it
  simply blurs out. Liquid Glass is applied **per element** instead — the leading
  button and each icon action sit in their own glass circle.
- **The leading button is centred, not bare.** `AppBar`'s tight `leadingWidth` box
  (56 by default) stretches a full-width child into an oval wider than the action
  circles, and the two then visibly disagree.
- **The bar inserts its own leading button for any route that can pop**, and passes
  `automaticallyImplyLeading: false` so the framework cannot add a second on top.
- **Glass is a capability, not a style choice — one gate decides.** It is a fragment
  shader, so only Impeller can run it: true on iOS, true on Android devices that get
  Vulkan, **false on Android's Skia fallback and false in widget tests**. When it is
  off, three things change together: the bar falls back to a plain surface, the
  scaffold stops extending the body behind it, and the spacing class's `appBarInset`
  returns 0. One `isSupported` getter owns all three. **Give it a test-only override
  and pin it true in `pumpApp`**, or every widget test exercises the fallback layout
  instead of the shipped one.
- **The bar holds no spacing logic** — the scroll-under body pads its own top from
  the spacing class.

### The device status bar — one source, and the two platforms disagree

- **The status bar style belongs to the app bar theme, set once, never at a screen.**
  `AppBarTheme.systemOverlayStyle` is the one place it is decided.
- **Never call `SystemChrome.setSystemUIOverlayStyle` from a screen.** It is global
  and nothing restores it on pop, so the style leaks into the next route and the bug
  only shows up in whatever screen you happened to visit afterwards. A screen that
  legitimately differs — a full-bleed photo header, a light sheet over a dark app —
  wraps itself in an `AnnotatedRegion<SystemUiOverlayStyle>`, which unwinds when the
  route does.
- **The two platform fields are inverted, and getting it wrong breaks exactly one
  platform.** `statusBarIconBrightness` (Android) describes the **icons**;
  `statusBarBrightness` (iOS) describes the **background behind them**. So:

  | Bar background | `statusBarIconBrightness` (Android) | `statusBarBrightness` (iOS) |
  | --- | --- | --- |
  | dark  | `Brightness.light` | `Brightness.dark` |
  | light | `Brightness.dark`  | `Brightness.light` |

  Set **both** every time. A style that names only one field looks correct on the
  platform you tested and renders invisible icons on the other.
- **Derive it from the resolved theme brightness, in one place** — a
  `SystemUiOverlayStyle` computed from `ThemeData.brightness`, not two hand-written
  constants that can disagree with the palette they are supposed to match. If the app
  follows the system theme, it **cannot be a `const`**: it has to be recomputed when
  the theme changes, or a device switching to light mode keeps light icons on a light
  bar.
- **A transparent or glass bar defeats the framework's automatic inference.** The
  default is inferred from the bar's own background colour, which here is transparent
  — so the answer is meaningless and the style must be set explicitly.
- **`statusBarColor` is Android-only and stays transparent.** Painting it opaque
  gives back the band the glass bar exists to blur, and iOS ignores it anyway — so it
  reads as "fixed on Android, still broken on iOS".
- **Android needs edge-to-edge turned on in bootstrap** for the body to actually run
  under the status bar; without it the glass bar has nothing to refract.
- **A single-theme app pins the platform's interface style too** (iOS
  `UIUserInterfaceStyle`). Otherwise the OS surfaces the app does not draw — the share
  sheet, the keyboard, a system alert — come out in the other appearance and the app
  flashes light for a moment mid-flow.
- **Assert on it rather than eyeballing it**: a widget test can read the
  `AnnotatedRegion` value, and that is the only way this stays correct after a theme
  change.

### The filter that lifts into the bar

- **A screen that is "a filter plus a scrolling list" uses the collapsing filter
  scaffold, never a hand-rolled `Stack` + pinned bar.** One widget owns the whole
  behaviour so two screens cannot drift into two: the filter row sits in a frosted
  strip under the app bar while reading, and as soon as the list scrolls on it
  **lifts into the app bar, whose title and actions step aside**; scroll back, or
  reach the top, and everything returns.
- **The hand-off has hysteresis.** Track drift in the current direction, reset it
  when the finger turns around, and only flip after ~16 of sustained movement — or a
  jittery finger flips the bar back and forth. At the top it is always expanded.
- **Listen only to the body's own scrollable** (`notification.depth != 0` → ignore),
  or a horizontal chip row nested inside it drives the collapse.
- **The filter is ONE widget, shown in the strip or in the bar, never both** — a
  stateful chip that exists twice can disagree with itself. Pass it as a **bare row
  of chips**: both places supply the horizontal scrolling, so a scroll view of your
  own nests two.
- **The body pads its own top and that inset must NOT change with the collapse** —
  one constant throughout. The strip's height stays reserved at the very top of the
  content, only ever on screen while expanded, so nothing jumps mid-scroll.
- **`filter: null` is "nothing to filter yet"**: no strip, no hand-off, the title
  keeps the bar. **`collapsible: false` pins everything** for a bar something else
  owns — a search field, for one: collapsing the field away mid-typing would take the
  search with it.
- **The pinned strip is a plain overlay box, NOT a sliver** — a `Stack` child at the
  top of the scrollable, with its top inset passed in (section 8's measure-once trap).

## 11. Lists that scroll behind the glass

The default for every scrolling screen: the list runs the full height of the window
and passes **under** the frosted bar. That is one behaviour, and these are the pieces
that make it hold.

- **`extendBodyBehindAppBar` is on exactly when glass is supported** — the scaffold
  decides it from the one capability gate, never a screen.
- **The screen pads INSIDE the scrollable, never around it.** A `SafeArea` or a
  `Padding` wrapping the list clips the scrollable to below the bar, and the content
  then *stops* at the bar instead of passing under it — the effect disappears and
  nothing at the call site says why. Padding goes on the `SliverPadding` / the list's
  own `padding`.
- **The top inset is `appBarInset + topGap` from the one class** — or
  `belowPinnedFilterBar` where a filter strip is pinned under the bar. Never
  `kToolbarHeight`, never a `MediaQuery` read at the call site (section 8).
- **The bottom inset comes from the same class**, with `floatingNav: true` on tab
  screens, so the last item clears the floating bar's whole footprint plus
  `bottomGap`.
- **A list is a `CustomScrollView` of slivers, and padding is per sliver.** That is
  what lets a header sit flush under the bar while the items below take the gutter
  and the item gap — one `ListView` padding cannot express that, and screens that try
  end up with a header inset differently from its list.
- **Item spacing is `SliverList.separated` with `listItemGap`**, never a margin on
  the tile and never a raw number (section 8).
- **Physics: one app-wide scroll behaviour, bouncing only when the content actually
  overflows.** The Material default wraps iOS physics in
  `AlwaysScrollableScrollPhysics`, so every short list drags and bounces against
  nothing — idle motion on a screen that has none to give. Pass
  `AlwaysScrollableScrollPhysics` **explicitly and only** where pull-to-refresh must
  work on content shorter than the viewport.
- **Pull-to-refresh is one wrapper, and its spinner needs an `edgeOffset`** of the
  app-bar inset plus a margin — or, where a filter strip is pinned, the strip's
  height plus a margin, so the spinner drops in below the chips rather than over
  them. The indicator lives in the body, which is painted *behind* the glass; without
  the offset the spinner emerges under the bar and looks clipped.
- **An empty state still scrolls.** Wrap it so it fills the viewport as a
  `SliverFillRemaining(hasScrollBody: false)`, or an empty screen is the one screen
  that cannot be refreshed. **Use the sliver, not a `LayoutBuilder`**: a
  `LayoutBuilder` builds its child *during* layout, and a state consumer resuming
  inside that build throws "setState() called during build". Give the wrapper the
  same top inset so the message clears the bar.
- **Chrome driven by scroll position reads it from a `NotificationListener` on the
  list**, comparing `metrics.pixels` against the element's own extent — and ignores
  nested notifications (`depth != 0`), or a horizontal row inside the list drives it.
  The threshold is a static on the widget it belongs to; an element that must scroll
  fully out before it fires has to start at offset 0, so nothing may be padded in
  above it.
- **Never nest two scrollables in the same axis.** Where a widget supplies its own
  horizontal scrolling, hand it a bare row.
- **Widget tests take the fallback layout unless the glass gate is pinned on** — so
  every inset assertion in a test is measuring the wrong layout by default.

## 12. Search — the bar, and the field inside it

### The search bar (search that takes over the app bar)

- **Search is a mode of the app bar, not a widget parked above the list.** Entering
  it swaps three slots at once: the **title becomes the field**, the **leading
  becomes a cancel button**, and the **actions become the clear button**. A bar that
  changes only one of the three leaves the user with a search field and a back arrow
  that pops the route out from under it.
- **A search affordance in the actions is what opens it** — an icon action next to
  the screen's primary action, never a permanent field taking a row of vertical
  space from the list on every visit.
- **The visibility flag is screen state; the query is not.** `_searching` is a
  `setState` bool because it dies with the screen. **The query lives in a
  controller/provider** so filtering survives a tab switch, a rebuild and a rotation —
  a query held in the widget resets the moment the shell rebuilds the branch and the
  user's list silently repopulates.
- **Opening focuses the field in the same action.** Revealing a field the user then
  has to tap is two taps for one intent.
- **Cancel clears, unfocuses and exits — in that order, in one method.** Leaving the
  query behind on exit is the bug that ships: the field is gone, the list is still
  filtered, and nothing on screen explains why. Clear (the controller *and* the text
  controller), drop focus, then flip the flag.
- **Clear is a separate action from cancel, and it keeps focus.** The X in the
  actions empties the query and **re-requests focus** so typing continues; the
  leading button leaves search altogether. One control doing both is why users end up
  dropped out of search when they meant to fix a typo.
- **The clear action is present only while the query is non-empty** — an X over an
  empty field is a control that does nothing.
- **While search owns the bar, the collapsing filter is pinned** (`collapsible:
  false`, section 10): collapsing the bar mid-typing would take the field with it.
- **The empty state says which empty it is.** "No medications yet" and "nothing
  matches that search" are different situations and get different copy, chosen off
  the trimmed query — otherwise a search with no hits reads as data loss.
- **Own the `TextEditingController` and the `FocusNode`, and dispose both.** They are
  screen-lifetime objects; a `State` that creates them and forgets `dispose()` leaks
  one per visit.

### The field inside it

- **There is exactly one text field widget, and search is a configuration of it** —
  never a second field type, never a raw `TextField` in feature code.
- **The label sits above the box, never floating inside it.** A floating label
  animates between two type sizes and two colours on focus — motion nobody asked for
  on a form — and leaves the field ambiguous the moment it has text. A static line
  above says the same thing and never moves.
- **The box is drawn by the widget, not by `InputDecoration`**: a 1px outline, no
  fill, so the same field reads correctly on a page, on a card and inside a dialog.
  Material's underline and its dense filled variants both fight the card language.
- **Focus is legible without hue**: the outline goes 1px → 2px *and* takes the
  accent. Two values, because colour alone is not an accessible focus signal.
- **In search configuration:** no label — the bar it sits in, or the magnifier in
  front of it, is the label, and a "Search" line above only pushes the list down. The
  hint carries the wording; the keyboard action is search.
- **Where the field is NOT in the bar** (a picker sheet, a step in a flow), it takes
  the magnifier as a prefix icon and the clear button as its own suffix, driven by a
  `hasText` flag the caller already tracks — the field keeps no second copy of state.
- **The search field is app-owned, not package-owned**: a localized hint and a
  localized clear tooltip fail the package admission test (section 6). It composes
  the package field, and moves to `core/widgets/` the moment a second feature uses it
  — ours is shared by the log flow's picker and the medication sheet.
- **Filtering is not the field's job.** The query lives in a controller, the matching
  is a `*Utils` method or a domain service, the field only reports `onChanged`.

## 13. The rest of the UI primitives

One widget per job, and feature code never reaches past it to the raw framework one.

- **Cards**: one card widget, one card colour, one radius — **no padding and no
  margin**. Material's `Card` carries an invisible `EdgeInsets.all(4)` that made a
  list whose separator said 8 come out 16, and sit 8 narrower than the list on the
  next tab. Spacing between cards belongs to whoever places them; the inset inside
  belongs to whatever they hold.
- **Buttons**: one button widget; **the look is a prop, never a named constructor**.
  One padding for every variant, so a filled, outlined and text button read the same
  size side by side. Size is a scale factor over that padding plus icon and gap, so a
  small button is the same shape scaled, never differently proportioned.
- **Dialogs and sheets: a widget class plus a `.show()` extension, never a top-level
  `showX()`.** Call it as `FooSheet(...).show(context)`. Both presenters use the
  **root navigator** so they cover the bottom nav. An opener with no dedicated widget
  is dead weight — inline the generic presenter at the call site.
- **Snackbars**: one utility, never the raw messenger. **It draws into the root
  overlay, not a `ScaffoldMessenger`** — a messenger renders into the nearest
  registered scaffold, so a route without one (a sheet) sent its messages to the
  screen *underneath*, where the very sheet that raised them covered them up. Widget
  tests did not catch it: a text finder matches a widget the user cannot see, so
  assert on the card widget instead.
- **Icons**: one icon widget, and it **always resolves to a concrete size** — never
  let an icon inherit an ambient one.
- **Text**: every `Text` carries an explicit `style:` from the app's text styles.
  Never lean on the ambient theme, even where it looks identical — the default is
  invisible at the call site and drifts silently when a theme changes. No inline
  `TextStyle(...)`.
- **Dividers**: one divider widget, one thickness, one colour, no props. **Between
  items only** (`if (index > 0)`) — a rule above the first row lands on the
  container's edge and reads as a border it does not have.
- **Modal colour is one slot, and sheets and dialogs both wear it.** A dialog opening
  over a sheet must never be a second shade. It sits a step *below* the card, not
  above: a modal already separates itself with the scrim and its corners, and going
  darker keeps a card on it reading as the nearer layer. Material trains every design
  tool to raise a modal instead — override the theme so a raw dialog cannot differ.
- **Anything that must stay visible while sitting *on* a card or sheet is a step up**
  in an elevated surface colour — a tile left on the card colour disappears the
  moment its sheet is that colour.
- **Animations stay calm**: fade / scale / slide, ≤400ms, gentle curves. Nothing
  flashes, strobes or pulses. Not negotiable for a "delightful" micro-interaction.
- **Colour is never the only signal.** A state told by colour is also told by an
  icon, a label, or a shape.
- **Charts hide their marks from screen readers and expose a summary instead.** A
  chart without that label is unreadable to VoiceOver.
- **Tapping outside a focused field drops focus**, wired once in the scaffold with a
  translucent hit-test so it never eats a tap meant for a button or a row.
- **A design mockup is reference, not authority.** Where a mockup and these rules
  disagree, the rules win silently — build what the rules say and tell me what was
  overridden. Every colour comes from the palette, every dimension from the ladder,
  every text style from the styles file. What a mockup IS for: hierarchy, rhythm,
  density, where the eye lands. Take that; leave the tokens.

---

## 14. Data and schemas

- **Never put two kinds of record in one table or collection.** Each entity gets its
  own, on both sides. No shared table with a `type` column standing in for three
  schemas. The one sanctioned exception is bookkeeping that is not a user record
  (tombstones), and it says so.
- **Never edit a schema version in place once any database has run it — bump
  instead.** A column renamed in an "unshipped" version left a dev device stuck at
  that version with the old column and no step that would ever fix it; every insert
  then died. **"Unshipped" means no database anywhere has run it, and your own
  simulator counts.** The undo migration *recreates* the table rather than renaming
  back, because nothing records what the intermediate version looked like.
- **Test every schema change with a migration test.**
- **The source of truth for user data is on-device; the cloud is a synced copy,
  never the only copy.**
- If records are scoped by an owner id: **every query must filter on it** (rules
  cannot be evaluated over a whole collection), and **one class builds every
  reference** to those collections, with no method that omits the filter.
- **Security rules: `read` gets its own rule; never fold it into `allow read,
  write`.** A query has no single document, so the backend proves it safe from the
  query's own filters — and that proof only works when the read condition is a plain
  constraint on a field. One combined rule needs a disjunction to cover creates,
  which leaves a branch constraining nothing: **every query is denied while writes
  still succeed**, and a permission error on a read looks identical to rules that
  were never deployed. Run the real rules against an emulator in CI.
- **Check both directions of ownership on a write**: the stored document *and* the
  incoming one. Without the second, a user can rewrite the owner id and plant a
  record in someone else's account.
- **Indexes and rules deploy together.** A missing composite index fails at runtime,
  not at build. A test can prove the files are right; it can never prove the project
  has them.
- **Local change tracking is a counter, not a timestamp.** Whole-second storage means
  an edit in the same second as the push before it looks unchanged and silently never
  syncs; a counter also survives the clock stepping backwards.
- **Mark synced only after the server confirms, and pull before pushing.** A kill
  mid-pass must cost a re-push, never a lost record. A payload that will not decode
  is counted and skipped, never retried forever — one bad record must not wedge every
  later one behind it. Each collection keeps its own cursor.
- **A payload codec refuses only versions NEWER than it knows, never merely
  different**, and ignores fields it does not recognise. Otherwise the first bump
  orphans every record already uploaded, and an added optional field stops two builds
  in the wild reading each other.

## 15. Backend

- **Fail open on anything that can lock the user out.** A force-update gate blocks
  only on an explicit flag against a strictly newer build; offline, a missing record,
  an unreadable field or a malformed link must all let the user in.
- **Compare versions segment by segment as numbers, never as strings** — `"1.10.0" <
  "1.9.0"` is true for a string.
- **Functions are idempotent, log structured JSON, and fail loud** on upstream
  errors (retry with backoff). Never silently skip a cohort.
- **Group before fanning out to a paid API** — one call per cell, never per user —
  and dedupe user-visible pushes with an explicit window.
- **One upstream provider per kind of data, backend included.** Two providers let the
  alert that wakes a user at 3am disagree with what the app shows them at breakfast.
- **A key that signs upstream requests never ships in a binary.** The app asks the
  backend; the backend asks the vendor. Everything in the app still depends on the
  repository interface, so the swap is a data source, not a rewrite.
- **A proxy concentrates quota**: what used to be per-device calls now all land on
  one key. Anything the app can reach must be rate-limited, or one caller burns the
  month. Ask for what you need in **one** request where the vendor bills per call
  rather than per dataset, and cache the two shapes under different keys so one can
  never be served the other's entry.
- **Every field below the top level is optional, on both sides of the wire.** A
  missing reading is an absent row, never a row reading "—".
- **An unknown enum code maps to null, never to a wrong neighbour.**

## 16. Privacy, secrets and destructive actions

- **Local-first, account optional.** Every feature that can work without an account
  does.
- **Never read secret files** — see section 3. Writing to them (a setup script
  creating them from templates) is the one thing that should touch them.
- **Analytics carries usage only**, never the sensitive fields the product exists to
  hold.
- **Two destructive actions, deliberately separate**: "delete all data" clears the
  records but **keeps the account** (someone clearing history usually wants to carry
  on, and losing the account would unbind their subscription), and "delete account"
  is the whole teardown. The auth user is deleted **last** — delete it first and
  every remaining step is unauthorised, leaving records nobody can reach.
- **Anything that persists a copy of user data inherits the wipe's obligation.**
  Past exports on disk, an app-group cache feeding a home screen widget — "delete
  everything" that leaves a copy behind is a lie about what it did.
- **A long destructive action shows progress, spinner and percentage both** — a row
  that only spins cannot tell slow from stuck. **Count fixed steps, never records**:
  counting rows means discovering more work mid-run, and a bar that jumps backwards
  reads as a bug even when the run is fine. A step added means moving the constant in
  the same change, with a test asserting the count is reported 0..steps with nothing
  skipped or repeated.
- **The privacy policy is a deliverable that moves with the code.** Adding a data
  flow means editing it **before the feature is called done** — a new synced
  collection, a new analytics parameter, a new third-party SDK. Nothing enforces
  this, which is why it is written down. Two claims must never soften: say exactly
  how far the encryption goes (if the server holds the key, it is not end-to-end and
  no wording may imply otherwise), and list the analytics and crash SDKs you actually
  ship — mine said "no third-party analytics" for months after they shipped.

## 17. Testing

- **Name the four things that must be tested, in priority order**, in
  `docs/rules/TESTING.md` — the pure-logic engine users pay for, migrations, the
  backend's edge cases, and the entitlement gating that proves a free user's tree
  holds no paid data. Everything else is negotiable; those are not.
- **Shared setup lives in `test/helpers/`**, never re-declared per file: one
  `pumpApp` that pins the view to the design size, passes the real theme, and pins
  the glass capability gate on — plus a fakes file per subsystem that would otherwise
  reach the network.
- **Override every provider that fires on app start.** Without the fakes, a widget
  test reaches for the network, a spinner renders, and every settle waits out its
  full 10-minute timeout — the suite went from 30 seconds to 10 minutes.
- **A finder matches widgets the user cannot see.** Where visibility is the thing
  under test, assert on the concrete widget that draws it.
- **If tests are ever suspended for a redesign, the suspension is written down with
  what it does NOT cover** (analysis still passes with zero findings; non-UI tests
  stay honest) **and with an end condition.** Don't let it quietly become permanent.

## 18. Commands, tooling and release

- **The scripts are shared, not written per app.** Add
  `https://github.com/DAMHONGDUC/script-tools` as a submodule at
  `packages/script-tools` and a two-line root `Makefile`
  (`SCRIPT_TOOLS := packages/script-tools`,
  `include $(SCRIPT_TOOLS)/flutter/flutter.mk`); `make` lists the commands.
  `docs/rules/COMMANDS.md` is the only place this app documents them.
- **A missing command is added to script-tools** (a `flutter/<verb>_<object>.sh`
  plus one line in `flutter.mk`), never as a script in the app repo.
- **Exactly two setup entry points**: the normal one, and the one that also clears
  the native build cache (which costs a full cold build, hence separate). Setup
  **wipes first, unconditionally** — it is the one answer to "it built yesterday and
  not today". Don't add a third clean-shaped command.
- **Config comes from gitignored env files via build-time defines, read through ONE
  `AppEnv` class** — the only place the environment lookup may appear. Everything
  else, generated config included, reads `AppEnv.*`.
- **A dev seed fills EVERY table**, and anything that is not a table (a read-only OS
  data source) gets a generated fake behind a non-production guard, because that data
  does not exist on a simulator and an empty read is indistinguishable from a refusal.
  Derived ids come from the real derivers, never a fresh UUID: a random id is a row no
  real writer could ever match, which is what idempotence depends on.
- **Version and build number are edited in the version file, never passed as a
  flag** — a build whose version exists nowhere in git is one the repo cannot account
  for. CI bumps by **rewriting the file** and pushing that commit **after** the upload
  succeeds: a bump commit with no build is a gap in the numbering, a build with no
  commit is the failure the rule exists to prevent.
- **The archive step must carry the same build-time defines as a local run.** An IDE's
  own archive action cannot pass them, and the resulting crash names nothing to do
  with the missing flag — which is why the build goes through a script, and why CI
  shells out to that same script instead of the plugin's built-in build step.
- **Clear the output folder before building.** Two environments writing the same
  filename to the same folder makes a leftover artifact indistinguishable from the one
  just built — and they carry different keys.
- **Upload debug symbols after the store upload, best effort** — every failure there
  is a warning, not a raise: the build is already up, and missing symbols are
  something to fix rather than a reason to re-cut a release.
- **Keep a pipeline diagram** (`docs/release/PIPELINE.md`) and keep every credential
  out of the repo, listed in `docs/rules/PENDING_SETUP.md`.

---

## 19. Deliverable for this first session

1. `PLAN.md` — the product spec from section 0, expanded with me, ending in the
   numbered list of product non-negotiables everything else cites.
2. `CLAUDE.md` — index + routing table + the "always" rules, nothing more.
3. `docs/rules/` — `COMMANDS.md`, `CODE_STYLE.md`, `DESIGN_SYSTEM.md`, `TESTING.md`,
   `PRIVACY_AND_SECURITY.md`, `DECISIONS.md` (empty but present), plus whatever this
   stack needs (`TECH_STACK.md`, `BACKEND.md`, `DATA_AND_SYNC.md`, `PENDING_SETUP.md`).
4. `docs/rules/DESIGN_SYSTEM.md` — how this app consumes the package: the one import,
   which generation is ours, the palette-stays-here rule, and a pointer to
   `WIDGET_RULES.md` as the authority on what may go in.
5. `docs/rules/PENDING_SETUP.md` — everything unconfigured (keys, IDs, products), so
   "it doesn't work" has one place to look first.
6. The submodule added and the new generation folder created — copied from `v2`,
   suffixes renamed, wired into `lib/index.dart`, analyzing standalone.
7. Commit each doc file per section 1's rule, then stop and show me the routing table
   and the generation number you picked, before writing product code.
