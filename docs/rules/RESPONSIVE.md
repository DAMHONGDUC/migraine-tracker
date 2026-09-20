# Tablet and window sizes

iPad is a shipping target (`TARGETED_DEVICE_FAMILY = "1,2"`, reviewed on iPad
Air 11" M3) and multitasking is on — there is no `UIRequiresFullScreen`, so
Split View hands the app a phone-width window on an iPad.

Three rules, and **every one of them is a no-op on a phone**. The phone build
is asserted at 393 in the same file that asserts the tablet one, which is what
lets any of this change without re-verifying it by hand.

**Porting this to another app?** `packages/system_design/RESPONSIVE_SPEC.md` is
the same three rules written portably — no BaroEase names, with the traps, the
code to copy, a test spec and a step order. This file is what *this* app does;
that one is what any app should do.

## Rule 1 — one scale, with a ceiling

screenutil multiplies every `.w` / `.h` / `.r` / `.sp` by `window / designSize`,
and that ratio has no upper bound. `SdScreenScale.designSize` grows the design
to match the window instead, so the ratio can never pass
`SdScreenScale.maxScale` — **1.25** (raised from 1.15, owner's call
2026-09-20: at 1.15 an iPad read as a phone layout with a lot of empty page
around it).

**Four ladders, four of screenutil's ratios, and they must not disagree.**

| Token | Used for | screenutil ratio |
|---|---|---|
| `w*` | horizontal spacing | width |
| `sp*` | type | width — `ScreenUtilInit`'s default `fontSizeResolver` is `FontSizeResolvers.width`, which is what actually decides type here. `minTextAdapt: true` sits beside it, inert. |
| `h*` | vertical spacing | height |
| `r*` | **icons, radii, square tap targets** | the **smaller** of the two |

That last row is why the design's *height* follows the same ceiling as its width
once the clamp engages, instead of never dropping below the phone design. A
landscape iPad is 820 tall against an 852 design, so the height ratio came out
0.96 — and `.r` takes the minimum:

| | Gutter | V gap | Body | Title | Icon | Tap target | App bar |
|---|---|---|---|---|---|---|---|
| phone 393×852 | 16 | 16 | 14 | 22 | 24 | 44 | 56 |
| iPad portrait, at 1.15 | 18.4 | 18.4 | 16.1 | 25.3 | 27.6 | 50.6 | **56** |
| iPad landscape, at 1.15 | 18.4 | **15.4** | 16.1 | 25.3 | **23.1** | **42.3** | **56** |
| iPad, either orientation, now | 20 | 20 | 17.5 | 27.5 | 30 | 55 | 70 |

Turning the iPad used to shrink every glyph below its phone size and every tap
target **under Apple's 44 minimum**, beside gutters and type that had grown. Both
orientations now render one number, and the phone column is byte-identical to
what it has always been — the clamp cannot engage below `393 × 1.25` = 491, and
the widest iPhone is 440.

**The app bar grows with them.** `kToolbarHeight` is a raw 56 the framework never
scales, so at 1.25 its leading button is 55 and its title 27 inside it.
`SdAppBarV2.toolbarHeight` is `h56` instead, and
`SdContentPaddingV2.appBarInset` and the nav panel's own header read that one
number so the three cannot drift.

"The same app at arm's length" is the whole of the reasoning: every number in
`SdSpacingConstant` moves by one factor and nothing else, so the rhythm they were
drawn at survives. Past ~1.4 that stops being true and an iPad is a phone
screenshot blown up — which is the bug this rule exists to close, in the other
direction.

## Rule 2 — the panel is joined, and the gutter is the only gap

Owner's rule, 2026-09-20. The nav panel meets the content region **with no gap
at all** — the joined sidebar/pane composition of iPad Settings, not a control
floating in a margin — and inside the content region the screen keeps the same
16 gutter it has on a phone. One gap, and it is a gutter the app already had.

```text
iPad 11" portrait, 820 x 1180
┌───────────────┬────┬──────────────────────────────┬────┐
│ panel 164     │ 16 │ app bar — same margins below │ 16 │
│ (window / 5)  │    ├──────────────────────────────┤    │
│ Home          │    │ card 624 — fills what is left│    │
│ History  …    │    │                              │    │
└───────────────┴────┴──────────────────────────────┴────┘
```

It replaced `tabletMargin`, a 46 margin applied on three sides of the old rail.
That rule existed to stop a capped-and-centred column producing three different
gaps; a joined panel has only one gap left to get wrong, so the constant went
with the rail it was measured against — and with it `pageMargin`, which had no
case left to answer. **No screen in the app adds a horizontal margin any
more**: `SdScaffoldV2` is a plain `Scaffold` and the gutter inside each
screen's own scrollable is the whole of it.

Measured, not calculated — what the app renders at:

| | Panel | Content region | Card | Gutter either side |
|---|---|---|---|---|
| phone 393×852 | — | 393 | 361 | 16 |
| iPad portrait 820×1180 | 164 | 656 | 624 | 16 |
| iPad landscape 1180×820 | 236 | 944 | 912 | 16 |
| collapsed, portrait | 0 | 820 | 788 | 16 |
| pushed detail, portrait | — | 820 | 788 | 16 |

### A screen with no shell nav fills the window

Owner's call, 2026-09-20. Every detail screen is a route pushed **above** the
shell — `app_router.dart` lists them as siblings of `StatefulShellRoute`, not
inside its branches — so it has no panel beside it, and **nothing to leave room
for**. It runs the full width of the window with its own gutter and nothing
else.

It was the other way first: half a panel per side, so the card came out the same
width as the tab screen it was opened from. That rule was written against the
rail, where matching cost 55 per side and nobody saw it. Against a panel it
costs `window / 10` — 82 in portrait, 118 in landscape — and it buys a detail
screen a phantom margin the shape of a chrome that is not there. **A collapsible
panel also has no single width to match**: collapse it and the tab screen is
788 wide while the detail it opens would still be 624.

The cost, stated: pushing a detail from an expanded panel widens the content by
a fifth of the window. The panel disappearing is the larger change on screen,
and it is the one the transition is about.

### The app bar spans the window with the body

`SdScaffoldV2` is a plain `Scaffold`: the bar and the body share one leading
edge because neither is inset. What lines the title up with the cards under it
is the screen's own gutter, applied inside its scrollable.

### The ceilings that are still in force

| Ceiling | Value | Applied by |
|---|---|---|
| `SdBreakpointV2.contentMaxWidth` | `w800` (920 on iPad) | the modal sheet, the paywall, onboarding |
| `SdBreakpointV2.dialogMaxWidth` | `w480` (552 on iPad) | `SdDialogV2` |
| `SdBreakpointV2.floatingBarMaxWidth` | `w480` (552 on iPad) | the phone's nav pill |

Those are **panels, not pages**: a sheet floating over a screen still wants to
stop growing. A page takes no ceiling and no margin at all, and `SdPageWidthV2`
is what applies one to the two screens that are panels wearing their own
`Scaffold` (onboarding, the paywall).

## Rule 3 — the shell's nav is a collapsible panel on the leading edge

| Window class | Width | Chrome | Bottom inset on a tab screen |
|---|---|---|---|
| `compact` | < 600 | `SdBottomNavigationV2` — floating glass pill, body scrolls behind it | pill footprint + 18 ≈ 100 |
| `medium` / `expanded` | ≥ 600 | `SdNavPanelV2` — a fifth of the window, glyph **and label** | `detailBottom` ≈ 20 |

**Same destinations, same list, same order.** `SdNavSegmentV2` is one cell used
by both chromes and `SdNavDestinationV2` is one list built once in `AppShell`,
so the breakpoint chooses the frame and never the contents. A destination that
existed only on a tablet is the bug that rule exists to stop.

| What | Pill (phone) | Panel (tablet) |
|---|---|---|
| Layout | floats; body passes behind the glass | a real column, joined to the content |
| Material | Liquid Glass | flat `colorScheme.surface` — nothing behind it to refract |
| Cell | glyph only — no room for five words at 393 | `SdNavSegmentShapeV2.row`: glyph, 12, label |
| Width | window − 48, capped at 552 | `window / 5`, proportional |
| Collapses | no | yes, to **nothing at all** |
| Swipe between tabs | yes, 48pt drag | **no** — at this width a horizontal drag is a chart being panned |
| `SdFloatingBarScopeV2` | `edge: bottom` | `edge: leading`, open or collapsed |

That last row reclaims the bottom inset. `floatingNav: true` means *"I am a tab
screen"*, not *"there is a bar below me"*; `SdContentPaddingV2.bottom` asks the
scope which chrome is up, so the five tab screens stop reserving a pill's height
of nothing.

**The width is a raw fraction of the window, never a `.w`.** It is a slice of
the window, which screenutil knows nothing about; scaling it would apply the
design ratio on top of the proportion. The row *height* is on the vertical
ladder, correctly — it is measured along the panel, not across it.

### Collapsed, it draws nothing — and the reopen control lives in the app bar

Not a narrow rail, not a strip of chrome above the content. `SdNavPanelV2`
publishes `SdNavPanelScopeV2` over the content column, carrying `isExpanded`,
the callback and the localized label — **state and a callback, never a
widget**. `SdAppBarV2` asks `SdNavPanelToggleV2.collapsedOf` for its leading
slot, and **no screen does**: a screen that could place the control is a screen
that could forget to, and the one that forgets is the one a user gets stuck on.

The alternative — a strip holding a menu icon above the content — was rejected:
it belongs to no screen, pushes every one of them down, takes a second claim on
the top safe inset the screen's app bar already owns, and leaves an empty band
under the icon. With the control in the chrome, the inset has one owner in both
states and collapsed content starts exactly where it would with no panel at all.

Three rules keep it unambiguous:

- **A back arrow outranks it.** A route with something to pop is a route the
  panel is not beside, so it keeps its back button (the detail screens are
  pushed above the shell and read no scope at all).
- **A screen passing its own `leading` keeps it** — the medications tab owns
  that slot while its search field is up, and gets the control back on close.
- **The key `SdNavPanelToggleV2.toggleKey` is on exactly one control at a
  time**, including mid-animation: the panel carries it only while expanded,
  `collapsedOf` only while it is not.

### It is painted after the content, and that is load-bearing

`SdNavPanelV2` lays the two regions out in a `Row` and then draws the panel over
its own strip from a `Stack`. **A full-screen route's modal barrier blocks the
semantics of everything painted before it**, and the content column is a
`Navigator` full of them — so a panel painted first is a panel VoiceOver cannot
reach at all. The rail before it was exactly that, undetected for its whole
life; `tablet_layout_test.dart` now switches every tab through the semantics
tree, which is the assertion that would have caught it.

### Motion

250ms, `Curves.easeInOutCubic`, on the joined widths — the panel and the content
move as one pair, because the transition is about where the working space goes
and a cross-fade hides the one thing worth seeing. `MediaQuery.disableAnimationsOf`
makes it a width change on the next frame instead. The panel's contents are laid
out at full width the whole way and clipped by an `OverflowBox`, so reversing
mid-collapse cannot reflow them into an overflow.

## The grids are unchanged — and that is now a choice, not a conclusion

`QuickAccessSection`, `DashboardExploreSection`, `IconOptionGrid` and
`HeadRegionGrid` still use their phone column counts. A 2-up cell measures:

| Window | Card | 2-up cell | 3-up cell would be |
|---|---|---|---|
| phone 393 | 361 | 175 | 111 |
| iPad portrait 820, panel open | 624 | 304 | 199 |
| iPad landscape 1180, panel open | 912 | 448 | 299 |

While the card was capped at 690 a third column would have gone *below* the
phone's cell width, which settled it. At 624–912 it no longer would, so this is
an open question rather than a closed one — see the decisions below. Note the
card now has two widths per window, open and collapsed, so a column count
chosen off one of them is a count that changes under the toggle.

## Measure the window, never the device

`MediaQuery.sizeOf(context).width`, never `shortestSide` and never a platform
check. An iPad in Split View is a 507-wide window, and chrome that asked "am I
on an iPad" would put a fifth of it behind a nav panel.

## Testing

`pumpApp(tester, surfaceSize: ...)` sets the window; the default stays 393×852,
so every existing test still measures the screen the app was drawn for.
`test/core/tablet_layout_test.dart` is the only file that pumps anything wider.
It asserts, at 820×1180 and 1180×820 **and that none of it engages at 393**:

- the scale ceiling holds on all four ladders, the same in both orientations,
  and does not engage at 393;
- the panel is exactly a fifth of the window at 600, portrait and landscape,
  and exactly 0 collapsed;
- the content keeps one gutter either side in both states, and is wider than a
  phone's in both orientations;
- a pushed detail screen fills the window it is given;
- the app bar shares the content's edges;
- the reopen control is in the panel while open and inside the `SdAppBarV2`
  while collapsed, **never both**, including mid-animation in either direction;
- reduced motion moves the width on the next frame, and motion on does not;
- the toggle's target clears 48;
- all five tabs still switch **through the semantics tree**, by label — the
  assertion that catches a chrome a screen reader cannot reach;
- the bottom inset is reclaimed on a tablet and kept on a phone;
- no tab screen and no log-flow step overflows, open or collapsed.

## Not done yet — open decisions

| Question | State |
|---|---|
| iPhone landscape | `Info.plist` allows it; a 390-tall log flow and paywall are unverified. Owner to decide portrait-only. |
| Dashboard as two columns at ≥840 | Not built. `sections` is already a `List<Widget>`, so it is a split, not a rewrite. |
| History master–detail | Not built. Needs `app_router.dart` — the detail is a pushed route today. |
| The panel at exactly 600 | Shipped, and tight: a fifth of 600 is a 120 column, and `SdFittedTextV2` shrinks the five labels to fit it. Reached only by an iPad split at exactly half; owner to decide whether the panel should stay glyph-only below 840. |
| Persisting the collapse across launches | Not built, deliberately. The panel is what names the five destinations for a user arriving on an iPad, and a remembered collapse hides that on the one launch it matters. |
| A third grid column on a tablet | Not built. Now viable (197–320 cells against a phone's 175) since the card stopped being capped at 690. Owner's call. |
