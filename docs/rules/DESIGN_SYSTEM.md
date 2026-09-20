# The design system, and how the app uses it

`packages/system_design` is a separate git repo checked out here as a submodule
and wired in as a path dependency. Its own `WIDGET_RULES.md` is the authority on
what may go in; this file is how the app consumes it, plus every UI primitive
rule.

## The package

There is exactly one import, and it is the index:

```dart
import 'package:system_design/index.dart';
```

- Every widget is `Sd<Name>V2` in its own folder `v2/sd_<name>_v2/`. Adding one
  is a folder, a file and one `export` line in `v2/index.dart` — read
  `WIDGET_RULES.md` first.
- `v2` is the widget generation and everything with a look lives there. The
  package's `core/` holds only what belongs to no generation: today
  `SdSpacingConstant`, which is why it alone carries no `V2` suffix.
- **This app renders `v2`, and the package's `README.md` says so.** One
  generation belongs to one product: a project joining the design system takes
  the highest generation there and builds `n+1` (`v3` is Seller OS, so the next
  product starts `v4`). That is what keeps `v2` frozen in fact rather than in
  principle — a generation with a second consumer gets edited to suit it, and
  BaroEase finds out by shipping. The gitlink records which *commit* this app
  pins, never which *folder* it imports, so nothing on the package side can tell
  who a change to `v2` breaks unless each app writes it down. Move that README
  line in the same change as any generation move.
- **The palette is NOT in the package — this app owns it.** `AppColors`,
  `AppTextStyle`, `AppTheme` and `AppScrollBehavior` stay in `lib/core/theme/`.
  `AppTheme.dark` hands the design system its colours by registering an
  `SdThemeV2` on `ThemeData.extensions`; package widgets read
  `context.colorScheme`, `context.textTheme` and `context.sdTheme` and never name
  a colour. **A widget test that pumps a bare `MaterialApp` will assert** — pass
  `theme: AppTheme.dark`, which `pumpApp` already does.
- **A widget may move into the package only if it takes every user-facing string
  as a parameter and imports nothing from this app** — no `context.l10n`, no
  provider, repository, router or domain entity. That is what keeps the package
  droppable into the next project.
  - Which is why these stay in `lib/core/widgets/`: `AppTimePickerSheet`,
    `MedicationNameDialog`, `PermissionSettingsSheet` (localized copy),
    `PremiumGate` (watches a provider), `SeverityBreakdownChart` (owns the app's
    severity bands, then composes `SdDonutChartV2`) and `sections/` (settings
    rows bound to auth / alerts / health / premium).
- `context.l10n` stays in the app (`core/extensions/context_extensions.dart`);
  `context.theme` / `.colorScheme` / `.textTheme` / `.sdTheme` come from the
  package. A file needing both imports both — normal, not a smell.
- Run `flutter analyze` inside `packages/system_design` too: it must pass on its
  own, without the app.

## Redesign mockups are reference, not authority — owner's rule

`docs/archive/UI_SPEC.md` briefs a redesign whose mockups come from an AI design
tool (Stitch). **They are visual direction only.** Where a mockup and these rules
disagree, the rules win silently — build what the rules say and tell the owner
what was overridden.

The reason is what the first two mockups did: asked for an exact 13-colour
palette, the tool returned a Material 3 scheme with tonal ramps running to
`#FFFFFF`, a near-white "inverted" button, two invented colour roles and no
severity scale at all — then ignored a correction listing all five. A tool that
answers a palette with its own palette cannot be the source of truth for one.

Never up for negotiation, however good the mockup looks:

- **Every colour comes from `AppColors`.** No hex is read off a mockup. The four
  `AppColors.intensity` bands are measured for colour-blind separation; a mockup
  that shifts, harmonises or drops them is wrong, not a proposal.
- **Every dimension goes through `SdSpacingConstant` and `SdContentPaddingV2`**,
  snapped to the existing ladder. A mockup measuring 13 becomes 12.
- **Every text style comes from `AppTextStyle`.** The app ships no UI font, so
  mockups drawn in Inter render in SF Pro and come out slightly smaller — never
  approve a label that only fits at the mockup's metrics.
- **Flat opaque surfaces stay flat**, Liquid Glass stays on chrome plus the
  paywall, and `surfaceModal` stays darker than `surface`. Material trains every
  one of these tools to raise a modal instead.
- **The log flow does not grow a step** (rule 5).

What a mockup IS for: hierarchy, rhythm, density, where the eye lands, how a card
is composed, what a chart should say. Take that; leave the tokens.

## Width, on a screen wider than a phone

One ceiling on the scale (1.25, the same on every ladder and in both
orientations) and one chrome that changes — the phone's
floating pill becomes `SdNavPanelV2`, a collapsible panel a fifth of the window
wide, joined to the content. Both do nothing on a phone. Full rule, with the
numbers and what is deliberately NOT responsive: `docs/rules/RESPONSIVE.md`.

## Surfaces and colour

- **One card colour: `AppColors.surface` (`#1C1C1E`)** — dashboard, insights,
  `SdChartCardV2`, every `Card` via `cardTheme`.
- **One modal colour, worn by bottom sheets and dialogs alike:
  `AppColors.surfaceModal` (`#161618`).** A dialog opening over a sheet must
  never be a second shade of dark, so both read the same `SdThemeV2.surfaceModal`
  slot — the sheet used to take `colorScheme.surface` and the dialog
  `surfaceElevated`, which is the drift this closes. It sits a step *below* the
  card, not above: a modal already separates itself with the barrier scrim and
  its corners, and going darker keeps a card on it reading as the nearer layer.
  `ThemeData.dialogTheme` carries the same colour so a raw `showDialog` cannot
  come out different.
- **Anything that must stay visible while sitting *on* a card, sheet or dialog
  goes up to `AppColors.surfaceElevated`** — snack bars, chart tooltips, the log
  flow's option tiles, filter chips. A tile left on `surface` disappears the
  moment its sheet is that colour.
- **Liquid Glass is for chrome** — app bar, the shell's nav pill, the log flow's
  step bar, a sheet header's two `SdAppBarButtonV2`s — plus one deliberate
  surface: the **paywall** panel. Every other sheet is flat and opaque.
  - **The tablet's nav panel is the one piece of chrome that is not glass.** It
    is a full-height column joined to the content with nothing behind it to
    refract, so it takes `colorScheme.surface` — the card colour — the way iPad
    Settings' sidebar sits against its pane. Its toggle is still an
    `SdAppBarButtonV2` in its glass circle, in the panel and in the app bar
    alike, so the control that closes it and the one that reopens it are one
    control.
- **Every card is an `SdCardV2`**, never a raw Material `Card`. It is the card
  colour and `SdCardV2.radius` and nothing else: **no padding and no margin**,
  because Material's `Card` carries an invisible `EdgeInsets.all(4)` that made a
  list whose separator said 8 come out 16 and sit 8 narrower than the next tab's.
  Spacing between cards belongs to whoever places them, the inset inside to
  whatever they hold, and `onTap` clips its own ink to the radius.
  `SdChartCardV2` and `SdBannerV2` compose it; `ThemeData.cardTheme` is a
  backstop for any `Card` Flutter builds internally, same colour, zero margin.
- **A bordered box is drawn with `SdOutlineV2`, never a hand-rolled
  `Border.all`.** One width, one radius, and a colour that is the secondary text
  colour at `SdOutlineV2.opacity` rather than a slot of its own — a border is the
  quietest thing on a surface, and its own palette entry would invite it to drift
  from the text it frames. `SdTextFieldV2` and the Insights health switch read
  the same three values, so a field and the row beside it cannot come out a
  different grey.
- **A divider inside a card runs edge to edge, never inset by the card's
  gutter** (owner's rule). Inset, it reads as a line under the column above it;
  full width, it reads as the break between two sections, which is what every
  divider in a card is for. Insights' cards use `InsightCardDivider`, which
  cancels `InsightCard.gutter` — a negative padding cannot do it, because
  `Padding` and `Container.margin` both assert their insets are non-negative.

## Type

- **The app ships no UI font — `AppTextStyle` sets no `fontFamily`, on purpose.**
  Flutter falls through to the platform's own: SF Pro on iOS, Roboto on Android.
  That is right for an iOS-first app (optical sizing, full Dynamic Type, correct
  Vietnamese diacritics), and Apple's licence forbids bundling SF Pro anyway. A
  missing `fontFamily` here is the decision, not an oversight. Shipping one font
  for both platforms would mean Inter, not Roboto (Roboto reads as Android on an
  iPhone), and would mean re-checking the type scale: Inter's x-height is taller,
  so the same `fontSize` renders larger.
- `assets/fonts/noto_sans/` is **not** a UI font: `ExportController` loads it
  through `rootBundle` for the PDF report, which needs a font it can embed. Don't
  register it under `fonts:`, don't delete it as unused.
- **Every style comes from `AppTextStyle`** — no inline `TextStyle(...)`, no
  `context.textTheme` / `Theme.of(context).textTheme` in widgets (the extension
  getter was removed on purpose). Sizes go through `SdSpacingConstant.sp*`; line
  heights are the shared `_height*` ratios in `AppTextStyle`. Use `.secondary` /
  `.w600` for muted and semi-bold (the package's own are `.muted(context)` /
  `.semiBold`), anything else via `copyWith`. `AppTheme` feeds `AppTextStyle`
  into `ThemeData.textTheme` so ambient defaults match.
  - Because of `.sp`, **widget tests must pin the view to the 393×852 design
    size** — `pumpApp` does; the default 800×600 surface scales fonts ~2× and
    breaks layout.
- **Every `Text` carries an explicit `style:`**, even where the ambient theme
  would look identical: the default is invisible at the call site and drifts
  silently when a theme changes. Use what the surface implies — app-bar titles
  `AppTextStyle.titleLarge`, `ListTile.title` `bodyLarge`, `ListTile.subtitle`
  `bodyMedium.secondary`, `SnackBar.content` `bodyMedium`.

## Icons and buttons

- **Every icon is an `SdIconV2`** — never a raw `Icon(...)` in feature or core
  code (the only raw one lives inside `SdIconV2`). It always resolves to a
  concrete size: `SdSpacingConstant.r24` by default, anything else passed
  explicitly via `size:`, never inherited from an ambient theme. `color` falls
  back to the ambient `IconTheme` when omitted.

### Which glyph: `AppIconConstant`, always

- **Every icon in the app comes from `AppIconConstant` (`core/theme/`), and no
  call site writes a glyph name.** Owner's rule. `medication` was spelled out
  at nine call sites and `pressure` at five, so changing either meant finding
  them all; and `Icons.compress` names the picture rather than the reading, so
  the same idea kept arriving as a different drawing on a different screen.
- **It is named for what it MEANS in this product**, not for the glyph:
  `pressure`, not `compress`; `attackLog`, not `addCircle`. Where the meaning
  genuinely is the picture — a chevron, a close cross — the name stays literal.
- **Material Symbols Rounded, one family at one optical weight.** The app used
  to mix Material's filled and outlined sets, so a filled `medication` in the
  tab bar sat beside an outlined one on the card it opened, and a screen of
  glyphs at two stroke weights reads as two apps. `SimpleIcons` is the one
  exception, for the Apple and Google marks: a brand glyph is the brand's.
  - **The design system draws the same family**, so `material_symbols_icons` is
    a dependency of the package too. A sheet whose close cross came from
    Material Icons while everything under it came from Symbols was the same
    defect one layer down.
- **A filled variant is a `fill:` on `SdIconV2`, never a second constant.**
  Symbols is a variable font, so selected/unselected is one glyph at two fill
  values — which is what the nav bar's selected tab uses, alongside its colour,
  so colour is never the only signal (hard rule 3).

### What size: `AppIconSize`, never a raw `r*`

- **Every icon size is a step on `AppIconSize` (`core/theme/`)**. Never an
  `SdSpacingConstant.r*` at an icon call site. Pick the step, never the number.

| Step | Size | Where |
|---|---|---|
| `xSmall` | 16 | punctuation inside a line of text — the pin before a place name |
| `small` | 20 | the chevron, and nothing else |
| `medium` | 24 | **the default** — what a row, a settings tile or a compact reading IS |
| `large` | 32 | a tile whose whole content is one glyph and one word |
| `xLarge` | 48 | an empty state, a permission sheet |
| `xxLarge` | 64 | the one-per-screen illustration |

- **The rule it encodes: a glyph that identifies is always a step above a glyph
  that only decorates.** The app had no ladder — identifying glyphs at r16, r18,
  r20 and r24 depending on which screen wrote them, chevrons at r20 in some rows
  and at `SdIconV2`'s implicit r24 in others, and three sibling picker sheets in
  one feature drawing the same shape at two sizes. On a settings row the arrow
  saying "tappable" carried exactly as much weight as the glyph saying what the
  row was about.
- **The steps are named by size, not by job.** The first ladder named them for
  the role — `inline`, `affordance`, `row`, `tile`, `hero`, `display` — and a
  role name claims one number without saying where on the scale it sits, so the
  ladder went 16-20-24-28 four apart and then jumped to 44 and 64. Sizes are what
  these are, and every step above `medium` is a multiple of 8, on the same grid
  the spacing uses.
- **`AppIconSize` and the palette live in the app, not the package**, for the
  same reason the type scale does: it is this product's look, and the package
  must stay droppable into the next one.
- **Every labeled button is an `SdButtonV2`, and the look is a prop, never a
  named constructor**: `SdButtonV2(variant: SdButtonVariantV2.primary, …)`.
  Variants: `primary` (main CTA), `secondary` (tonal), `outlined`, `text` (low
  emphasis, dialog cancel), `destructive` (error-filled confirm), `positive`
  (teal additive). Never raw `FilledButton`/`OutlinedButton`/`TextButton` in
  feature code.
  - **Padding is one fixed value for every variant** — `SdContentPaddingV2.button`
    — so filled, outlined and text buttons never sit a different size next to
    each other. `size` (`SdButtonSizeV2.small`/`medium`/`large`, scale
    0.75/1/1.25) multiplies that padding plus the icon and icon gap together, so
    a smaller button is a scaled-down version of the same shape. `medium` is the
    default and unscaled.
  - **With an `icon` the button lays the content out itself** —
    `SdButtonV2.iconSize` glyph, `SdButtonV2.iconGap`, then the label —
    deliberately avoiding Material's `.icon` constructors, whose per-variant
    padding made the filled Apple button and the outlined Google button sit
    differently.
  - Placement is a second prop. `SdButtonIconPlacementV2.inline` (default) is a
    centred cluster that shrink-wraps, so a longer label pushes the glyph
    sideways. `aligned` start-aligns the label in a slot of
    `SdButtonV2.alignedLabelWidth`, so **stacked buttons put their glyphs on the
    same x and start their labels on the same x whatever the label lengths** —
    what the login screen's Apple/Google pair uses. The slot is a minimum, not a
    cage: a longer label widens, then wraps, and never ellipses.
  - The glyph is `SdButtonV2.defaultIconSize` unless a call site passes
    `iconSize` (an `SdSpacingConstant.r*`, never a raw number) to optically
    correct a brand mark. Under `aligned` that resizes the glyph but not the slot
    it is centred in, so the pair stays lined up.
  - **A labeled button in `SdScaffoldV2.actions` is always
    `size: SdButtonSizeV2.small`** — see `LogScreen`'s "Next". `compact` forces
    that scale regardless of what a call site passes, so the two can never
    disagree; a plain `size: small` without `compact` still gets the scaled icon
    and padding but not `compact`'s tighter fixed padding and `h34` minimum
    height.
- **Icon-only app-bar actions — leading back arrow and trailing alike — are
  `SdAppBarButtonV2`**, never a raw `IconButton`: an
  `SdAppBarButtonV2.iconSize` (20) glyph inside an invisible
  `SdAppBarButtonV2.tapSize` (48) target, with an `SdPopScaleV2` swell on touch
  (it grows out from under the fingertip; a press-*in* would vanish under it).
  `SdAppBarV2` inserts one for any route that can pop and wraps each action in
  the glass circle — an action that is not one passes through undecorated.
  `IconButton` is still fine inside content: list rows, text-field suffixes.

## Tags

- **A state worth reading at a glance is an `SdTagV2`, not a line of grey
  text** — the alert row's "On · 7 hPa", the `PremiumBadge`. One tinted pill,
  the label's own colour at `SdTagV2.fillOpacity`, never a foreground and a
  background that can drift apart. **Never hand-roll the pill again**: both of
  those were separate copies of the same `Container` before this widget existed.
- **The colour carries the meaning, and it comes from a ramp the app already
  owns.** `AlertSummaryTag` tints itself with `AppColors.intensity` at the
  chosen threshold — the same ramp the slider that sets it uses — so the row and
  the control behind it cannot say different things about one number. Off sits
  off that ramp on `onSurfaceVariant`: a threshold nothing acts on has no
  severity, and green there would read as "all good".
- **A tag stands where a value string would, and the chevron stays.**
  `SettingsTile.valueTag` is that slot; `trailing` replaces the whole cluster
  and takes the chevron with it.

## Waiting, and having nothing

- **A wait whose shape is known is drawn, never spun for — owner's rule.**
  `SdSkeletonV2` and its two compositions (`SdListSkeletonV2`,
  `SdChartSkeletonV2`) reserve the space the content will take, so nothing jumps
  when it lands. A `CircularProgressIndicator` is left for two cases only: an
  action the user just started (a sign-in, a dev tile), and a determinate bar
  that is reporting real progress (`sync`, the free-limit meter).
  - **Two waits are deliberately blank and must stay blank.** Insights' tab card
    and the correlation bodies' error branch: the engines run over the local
    database and settle in a frame or two, so a placeholder there would flash —
    which hard rule 3 forbids outright. The bodies that DO skeleton
    (`InsightBodySkeleton`) are waiting on a HealthKit read, which takes as long
    as it takes.
- **An empty state is never text alone — owner's rule.** `SdEmptyStateV2`, glyph
  over message. A line of grey prose where content should be reads as a caption
  on something missing, or as a failure; the glyph is what says "this is a
  state, and it is a normal one".
  - **`SdEmptyStateSizeV2.compact` is for a slot inside something that is not
    empty** — a chart's plot area, one section of a card — where the full 64pt
    glyph would push the card to twice the height its content needs. Reach for
    it rather than dropping back to a bare `Text`.
  - **Empty and loading are not the same screen.** The paywall showed "no plans"
    while the store was still answering; a card with no data yet and a card whose
    source is switched off say different things and get different glyphs.

## Sheets and dialogs

- **Every sheet wears `SdSheetHeaderV2`**: X on the left that leaves, title
  centred, nothing on the right. The X is an `SdAppBarButtonV2` wearing
  `SdAppBarButtonSurfaceV2.glassCircle` — the sheet is a flat opaque panel, so a
  frosted disc on it has real background to refract. The right slot stays
  reserved so the title sits on the sheet's centre. It brings its own insets;
  nothing pads around it.
- **A sheet that updates or adds anything commits from a labelled button pinned
  along its bottom edge — owner's rule.** `SdSheetContentV2` draws it from
  `confirmLabel` + `onConfirm`: full width, `SdButtonVariantV2.primary`, always
  the last thing above the safe area. The commit used to be a tick or a pencil
  opposite the X, which put the button that writes something in the corner
  furthest from the thumb and sized it like an icon. `SdSheetActionV2` is gone
  with it; the promise is now the word:
  - **`commonSave`** — an answer given for the first time.
  - **`commonUpdate`** — a value being overwritten.
  - Anything else only when the sheet is not recording a value at all (a filter
    applies with `commonDone`).
  - **`confirmLabel` null is what says a sheet has no commit** — a menu whose tap
    on a row IS the answer. **`onConfirm` null with a label disables the button
    rather than removing it**: a commit that appears and disappears as the
    selection changes moves everything under the thumb.
  - `footer` is for the answers that are neither commit nor leave — a "clear", a
    "not recorded" — and sits above the button.
- **`SdSheetContentV2`** is that header plus content scrolling under a ceiling of
  85% of the screen, with an optional pinned footer. Pass
  `isScrollControlled: true` when showing it, or the route caps itself near half
  the screen and the ceiling never applies. **Every sheet in the app wears one**,
  a menu whose tap IS the answer included — that one simply passes no
  `onConfirm`, and the reserved slot keeps its title on the same centre as
  everyone else's. A sheet that draws its own title in a `Padding` is the drift
  this closes.
- **A sheet that edits something commits from the header tick, never from a
  button in its body.** The pairing is the whole point: X abandons, tick writes,
  and a primary button below the content is a third answer competing with both.
  A footer is for the answers that are neither — "not recorded", a clear.
- **A `ListTile` inside a sheet takes `contentPadding: EdgeInsets.zero`.**
  `SdSheetContentV2` already holds the gutter, and the tile's own 16 on top of it
  insets those rows past everything else in the sheet.
- **Bottom sheets and dialogs: widget + `.show()` extension, never a top-level
  `showX()`.** The sheet or dialog is a public widget class, and its opener is an
  extension named `<Widget>Ext` exposing
  `Future<T?> show(BuildContext context) => showSdBottomSheetV2<T>(context, builder: (_) => this);`
  (or `showSdDialogV2<T>` for dialogs). Call it as `FooSheet(...).show(context)`.
  This keeps presentation off file-scope functions while still routing through
  the shared presenters (root navigator, calm animation). An opener with no
  dedicated widget — a thin wrapper over the generic `showSdFilterSheetV2` — is
  dead weight; inline the generic presenter at the call site.

## Spacing

**No widget or class holds spacing logic — `SdContentPaddingV2` does, and nothing
else.** Not `SdScaffoldV2`, not `SdAppBarV2`, not a screen: any inset another
widget pads by is a static on that one class. Widgets keep only their own
intrinsic size (`SdPinnedFilterBarV2.barHeight`, `SdAppBarV2.preferredSize`).

- **One gap between list items: `SdContentPaddingV2.listItemGap` (8)** — never a
  per-screen `SdSpacingConstant.h8`. The attack list, a calendar day's attacks
  and the medications list each spelled the same 8 out separately, and three
  copies of a number is three chances to disagree. **Any place that spaces one
  item from the next uses it**, the gap from a filter row down to its list
  included — a filter sits above its list like one more item above the first.
  Lists of `ListTile`s take no gap at all: those rows carry their own insets and
  sit flush (Settings, the export history).
- **One gap for stacking whole cards or sections: `SdContentPaddingV2.sectionGap`
  (20).** Dashboard's mixed cards and Insights' correlation/forecast/sleep cards
  both read it, so the two screens' rhythm cannot drift apart. A section is a
  distinct card, not one row of a repeated list, so it gets the roomier number —
  and never a raw `SdSpacingConstant.h*` at a call site either.
- **`SdContentPaddingV2.screen(context)` is the one screen inset.** Content sits
  `topGap` (8) below the app bar and `horizontal` (16) either side; the two
  vertical gaps are separate fields, so the edge under the chrome and the edge
  above the thumb move independently.
  - **The bottom depends on what is below.** A tab screen clears the nav pill and
    then `bottomGap` (16); every other screen takes `detailBottom` — the device's
    safe area floored at `minDetailBottom` (20), with nothing stacked on top,
    because a device reporting 34 already gives more room than the floor asks
    for.
  - `fullBleed(context)` drops the gutter for rows that inset themselves (a
    `ListTile`). `floatingNav: true` additionally clears the shell's nav pill on
    the five tab screens — `navBarOffset` + `floatingBarHeight` + `bottomGap` —
    so scrolling to the end leaves exactly `bottomGap` between the last item and
    the pill.
  - **`navBarOffset` is the pill's own rule and the one place it lives**: the
    device's bottom inset clamped between `minNavBarOffset` (16) and
    `maxNavBarOffset` (20). The floor covers a device asking for too little — no
    indicator at all (a Home-button phone, most Androids, the default test view)
    or a shallow one (iPad, landscape). The ceiling keeps a deep inset from
    pushing the pill up the screen, and **costs system clearance on a portrait
    iPhone**: its indicator inset is 34, so the pill lands 14 short and its lower
    edge sits inside the strip iOS reserves for the indicator and the edge-swipe.
    Deliberate — raise `maxNavBarOffset` to 34 to give that back.
  - **The log flow's step bar does not clamp**: it rests on the full safe area
    (`bottomBar`), so the two bars legitimately differ.
  - **`floatingBarHeight` (and `floatingBarRadius`, half of it) is the ONE height
    for both floating bars.** The nav pill and the step bar read it and neither
    types its own — the day they disagreed, the difference was eaten out of the
    gap above them.
- **Insets come off the view, not the ambient `MediaQuery`.** `Scaffold` strips
  its body's top padding when there is an app bar, and subtracts `padding.bottom`
  from `viewPadding.bottom` whenever there is a `bottomNavigationBar` — so an
  ambient read inside the shell loses the home indicator entirely and the last
  row lands *under* the pill. `SdContentPaddingV2` reads the view; feature code
  reads `SdContentPaddingV2`. **Never read `MediaQuery.paddingOf(...)` for
  content spacing at a call site, and never re-add an inset the class already
  applied.** The default test view has no notch, so a bug here costs 0 pixels in
  every widget test — see `test/core/constants/app_content_padding_test.dart`,
  which gives the view one.
- **`SdScaffoldV2` adds no padding at all** — no SafeArea, no insets. Every
  screen pads its own scrollable via `SdContentPaddingV2`, applied **inside** the
  scrollable so content still scrolls behind the frosted bar. A scaffold-level
  SafeArea plus a body that also clears a floating bar is how insets used to get
  applied twice.
- **The bottom action sits 16 above the safe area, never twice.** On a screen
  that is `SdContentPaddingV2`'s business the class has already applied it — do
  not add it again, and do not leave the button flush against the home indicator.
  Sheet routes still take `MediaQuery.paddingOf(context).bottom + h16` themselves
  (they are not screens). Floating chrome is exempt and each has its own line
  above.

## Layout scaffolds

- **A filter over a scrolling list: `SdCollapsingFilterScaffoldV2`**, in place of
  `SdScaffoldV2` — never hand-rolled, and never a `Stack` +
  `SdPinnedFilterBarV2` assembled at the call site again. The filter row sits in
  a frosted strip under the app bar while reading; as soon as the list scrolls on
  it, it **lifts into the app bar, whose `title` and `actions` step aside**, and
  scrolling back (or reaching the top) returns everything.
  - Pass the filter as a **bare row of chips** — both places supply the
    horizontal scrolling, so a scroll view of your own nests two.
  - `filter: null` is "nothing to filter yet" (an empty export history): no
    strip, no hand-off. `collapsible: false` pins it all in place for a bar
    something else owns (the medications tab while its search field is up).
  - **The body pads its own top and that inset must not change with the
    collapse**: `SdContentPaddingV2.belowPinnedFilterBar` throughout, so the
    reserved strip height cannot make content jump mid-scroll.
  - Used by `medications_screen` and `export_screen`. History's own pill lives
    IN its list and is a different mechanic.
- **Content plus a bottom action: `SdActionViewV2`**, passed straight as
  `SdScaffoldV2.body` — never hand-rolled. Content on top, `actions` hugging the
  bottom edge, `spaceBetween` between them, and it owns the two things such a
  screen otherwise forgets: the vertical insets (from `SdContentPaddingV2`) and
  the minimum height that gives `spaceBetween` its free space. Nothing inside
  `content` adds a top gap of its own. `actions` is a stretched `Column`, so
  buttons come out full width and equal. It scrolls itself — long locales and
  large text sizes overflow a fixed `Column`, and a bare `ListView` is wrong
  because under short content the buttons drift into the middle. Used by
  `login_screen`, `account_screen`, `premium_screen`.
  - **`placement` decides what happens once the two outgrow one viewport.**
    `SdActionsPlacementV2.scrolling` (default) scrolls content and actions
    together — right where the actions are the end of the content. `pinned`
    scrolls only the content and holds the actions at the bottom edge, **for
    content that grows without bound**, where an action at the end of a list is
    one the user will not find. `medication_detail_screen` created it: its
    reminder list has no ceiling, and "Add reminder" was being pushed off.
  - Under `pinned` the actions sit BELOW the scroll view, never over it, so
    content can never pass behind them — which is why the footer needs no surface
    and no blur. What separates the two is `SdContentPaddingV2.pinnedActionsGap`,
    its own field rather than `bottomGap`: that one is the air *below* the last
    item, and pinning created a second edge on the side the content arrives from.
    Equal to it on purpose, so a pinned footer has the same air above and below.
  - **`actions` holds what the screen is for, and nothing else** (owner's rule).
    A destructive escape hatch — "Delete account" — is a red `SettingsTile` in
    the list, not a second button under the thumb: side by side with Sign Out
    the two read as a pair of equals, and the one that cannot be undone gets
    the same reach as the one done every week. Account has one action now, Sign
    Out; deletion is a row after the Subscription section, tinted
    `colorScheme.error` like Settings' own destructive rows, with the dialog
    behind the tap doing the actual confirming.

## Loading and separators

- **A wait whose shape is known is an `SdSkeletonV2`, not a spinner.**
  `SdChartSkeletonV2` / `SdChartCardSkeletonV2` for a plot, `SdListSkeletonV2`
  for rows, the primitive for anything else — all reserve the space the real
  content will take, so a screen does not reflow under the user's thumb. **The
  spinner is still right for a wait with no shape**: an action the user just
  started (a delete, a seed, an export) and a viewer that draws its own
  placeholder. Picking by "is there a spinner already" rather than by "do I know
  the shape" is what gives one app two answers to the same wait.
  - **It shimmers, and that is the one loop the system allows** (owner's call,
    2026-09-04 — it was a still block before, on the reading that hard rule 3
    covers a placeholder looping for as long as the network takes). What keeps
    it inside the rule: one band, 1400ms a pass, 8% lighter than
    `surfaceElevated`, one direction, off both edges — grey over grey, no
    white and no opacity flash — and iOS Reduce Motion puts the still block
    back. Nothing else may loop. Long version in `WIDGET_RULES.md` § 6.
  - **Every skeleton is a rectangle at `SdSkeletonV2.radius` (8)** — owner's
    rule, no prop to override it. One shape means a screen's placeholders read as
    one loading state, and it deliberately does not copy what is underneath: a
    pill for a line and a card radius for a card had each placeholder
    impersonating a different component. No circles.
  - Inside, it is `SdSkeletonV2.lineGap` and `SdContentPaddingV2.listItemGap`,
    never numbers typed at a call site — a placeholder list at a different pitch
    from the real one shuffles everything the moment data arrives.
- **Every separator line is an `SdDividerV2`**, never a Material `Divider`. One
  thickness (`SdSpacingConstant.h1`) and one colour (`sdTheme.surfaceElevated`,
  the same step up everything sitting on a card takes), so two lists cannot come
  out different greys. **It occupies exactly the line it draws**: Material's
  `Divider` reserves a whole `height` (16 by default) around a 0-thickness rule,
  so a "1px line" silently costs 16 of vertical space and two rows drift apart
  for reasons nothing at the call site explains. The gap around it belongs to
  whoever places it. It carries no props — an indent is a `Padding` at the call
  site, and a second call site wanting the same indent is when it becomes a field
  on `SdContentPaddingV2`, never a number typed twice.
  - **Between items only, never on a container's own edge.** The reminder list
    draws `if (index > 0) const SdDividerV2()` — a rule above the first row lands
    on the card's edge and reads as a border it does not have.
