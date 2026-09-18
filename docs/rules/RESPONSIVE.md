# Tablet and window sizes

iPad is a shipping target (`TARGETED_DEVICE_FAMILY = "1,2"`, reviewed on iPad
Air 11" M3) and multitasking is on — there is no `UIRequiresFullScreen`, so
Split View hands the app a phone-width window on an iPad.

Three rules, and **every one of them is a no-op on a phone**.

## Rule 1 — the scale has a ceiling

screenutil multiplies every `.w` / `.h` / `.r` / `.sp` by `window / designSize`,
and that ratio had no upper bound. `SdScreenScale.designSize` grows the design
to match the window instead, so the ratio can never pass
`SdScreenScale.maxScale` (1.15).

| Window | Design handed to screenutil | Scale | A 16 gutter paints at |
|---|---|---|---|
| 393×852 — iPhone 15 | 393×852 | 1.00 | 16 |
| 440×956 — iPhone 16 Pro Max | 393×852 | 1.12 | 18 |
| 820×1180 — iPad 11" portrait | 713×1026 | 1.15 | 18 |
| 1180×820 — iPad 11" landscape | 1026×852 | 1.15 / 0.96 | 18 |

Before the ceiling, the last two rows were **2.09** and **3.00** — a 16 gutter
at 33 and 48, while `minTextAdapt` (which takes the *smaller* of the two ratios
for text) made landscape type *smaller* than an iPhone's. The app was a
screenshot blown up in one direction and shrunk in the other.

1.15 is "the same app at arm's length": every number in `SdSpacingConstant`
moves by it and nothing else, so the rhythm they were drawn at survives.

## Rule 2 — one gap, everywhere

Owner's rule. **Screen edge → rail, rail → content, content → far edge are the
same number**, and it does not change with the screen or the orientation:
`SdContentPaddingV2.tabletMargin`, 40 design units = **46 rendered**.

```text
iPad 11" landscape, 1180 x 820
┌──────┬────┬──────────────────────────────────┬────┐
│      │    │ app bar — same margins as below  │    │
│ ▓▓▓▓ │ 46 ├──────────────────────────────────┤ 46 │
│ ▓▓▓▓ │    │ card 978 — fills what is left    │    │
│  64  │    │                                  │    │
└──────┴────┴──────────────────────────────────┴────┘
 |<46>|                        rail column = 46 + 64 = 110
 5 cells of 92 = a 462-long rail, centred vertically
```

It replaced a column capped at 920 and centred. A cap plus centring produced
three *different* gaps — 46 at the edge, 107 to the rail in landscape, 79 at
the far side — because two of them were leftover page margin and only one was a
decision. One number is a decision.

Measured, not calculated — what the app renders at:

| | Card | Rail column | Rail thick | Cell | Rail length | All three gaps |
|---|---|---|---|---|---|---|
| phone 393×852 | window − 32 | — | — | — | — | — (16 gutter) |
| iPad portrait 820×1180 | 618 | 110 | 64 | 110 | 552 | **46** |
| iPad landscape 1180×820 | 978 | 110 | 64 | 92 | 462 | **46** |

### A screen with no shell nav gets the same width, centred

Owner's rule. Every detail screen is a route pushed **above** the shell —
`app_router.dart` lists them as siblings of `StatefulShellRoute`, not inside its
branches — so it has no rail beside it. A plain `tabletMargin` there would make
it a rail's column wider than the tab screen it was opened from, and the content
would jump outward on the way in and back on the way out. It takes half the
rail's column extra on each side instead, which is the one inset that makes the
two widths identical:

```text
iPad 11" portrait, 820 wide — both land on a 618 card
tab screen     |46| rail 64 |46|      card 618      |46|
pushed detail  |     101     |46|      card 618      |46|     101     |
```

`SdContentPaddingV2.pageMargin` owns both cases and
`SdFloatingBarScopeV2.edgeOf` is how it tells them apart: `leading` is the rail,
`bottom` is the phone's pill, and **null is no shell nav at all**.

### The app bar is inside the margin

`SdScaffoldV2` pads the whole `Scaffold`, not just its body, so a title and the
cards under it share one leading edge — a header spanning the window over an
inset body reads as two screens stacked. A `ColoredBox` behind it paints the
margin, because a pushed route has no surface of its own and the strips either
side would otherwise show black.

The margin lives in `SdScaffoldV2` rather than in the shell for the reason
above: the detail screens never see the shell.

### The ceilings that are still in force

| Ceiling | Value | Applied by |
|---|---|---|
| `SdBreakpointV2.contentMaxWidth` | `w800` (920 on iPad) | the modal sheet, the paywall, onboarding |
| `SdBreakpointV2.dialogMaxWidth` | `w480` (552 on iPad) | `SdDialogV2` |
| `SdBreakpointV2.floatingBarMaxWidth` | `w480` (552 on iPad) | the phone's nav pill |

Those are **panels, not pages**: a sheet floating over a screen still wants to
stop growing. Only the page took the margin rule instead, and `SdPageWidthV2`
is what applies a ceiling to the two screens that build their own `Scaffold`
(onboarding, the paywall).

## Rule 3 — the shell's nav moves to the leading edge

| Window class | Width | Chrome | Bottom inset on a tab screen |
|---|---|---|---|
| `compact` | < 600 | `SdBottomNavigationV2` — floating pill, body scrolls behind it | pill footprint + 18 ≈ 100 |
| `medium` / `expanded` | ≥ 600 | `SdNavigationRailV2` — the pill stood on its end | `detailBottom` ≈ 20 |

**Same destinations, same cell, same thumb.** `SdNavSegmentV2` is one widget
used by both chromes and `SdNavDestinationV2` is one list built once in
`AppShell`, so a tab cannot look like one control on a phone and another on an
iPad. What differs follows from the axis:

| What | Pill (phone) | Rail (tablet) |
|---|---|---|
| Layout | floats; body passes behind the glass | takes a real 110 column |
| Thickness | `h56` — vertical, correctly | `w56` — thickness is horizontal on a standing rail |
| Cell per tab | 64 wide (`floatingBarHeight`) | 92–110 long (`floatingRailCellHeight`) |
| Inner margin | — | **none**; the gap to the content is the content's own `pageMargin` |
| Swipe between tabs | yes, 48pt drag | **no** — at this width a horizontal drag is a chart being panned |
| `SdFloatingBarScopeV2` | `edge: bottom` | `edge: leading` |

That last row reclaims the bottom inset. `floatingNav: true` means *"I am a tab
screen"*, not *"there is a bar below me"*; `SdContentPaddingV2.bottom` asks the
scope which chrome is up, so the five tab screens stop reserving a pill's height
of nothing. The scope imports nothing from `SdContentPaddingV2` — content
padding is what asks the question, so the answer must not depend on it.

**The rail's thickness is a `.w`, never a `.h`.** screenutil scales the two axes
by different amounts, and a landscape iPad's height ratio is 0.96 against a
width ratio of 1.15 — taken off the vertical ladder, the rail came out 54 thick
in landscape against 64 in portrait: one control, two thicknesses, depending on
how the iPad was held. `floatingRailCellHeight` is deliberately the other way
round, because cell *length* runs down the screen — 110 portrait against 92
landscape, so the short window gets the shorter rail.

## The grids are unchanged — and that is now a choice, not a conclusion

`QuickAccessSection`, `DashboardExploreSection`, `IconOptionGrid` and
`HeadRegionGrid` still use their phone column counts. A 2-up cell measures:

| Window | Card | 2-up cell | 3-up cell would be |
|---|---|---|---|
| phone 393 | 361 | 175 | 111 |
| iPad portrait 820 | 618 | 302 | 197 |
| iPad landscape 1180 | 978 | 482 | 320 |

While the card was capped at 690 a third column would have gone *below* the
phone's cell width, which settled it. At 618–978 it no longer would, so this is
an open question rather than a closed one — see the decisions below.

## Measure the window, never the device

`MediaQuery.sizeOf(context).width`, never `shortestSide` and never a platform
check. An iPad in Split View is a 507-wide window, and chrome that asked "am I
on an iPad" would put a navigation rail in it.

## Testing

`pumpApp(tester, surfaceSize: ...)` sets the window; the default stays 393×852,
so every existing test still measures the screen the app was drawn for.
`test/core/tablet_layout_test.dart` is the only file that pumps anything wider.
It asserts, at 820×1180 and 1180×820 **and that none of it engages at 393**:

- the scale ceiling holds;
- the three gaps are equal and equal to `tabletMargin`;
- a pushed detail screen is the same card width, centred;
- the app bar shares the content's margins;
- which chrome the shell picks, and that the content clears the rail;
- the rail is longer than it is thick, and one thickness in both orientations;
- all five tabs still switch from the rail;
- the bottom inset is reclaimed on a tablet and kept on a phone;
- no tab screen and no log-flow step overflows.

## Not done yet — open decisions

| Question | State |
|---|---|
| iPhone landscape | `Info.plist` allows it; a 390-tall log flow and paywall are unverified. Owner to decide portrait-only. |
| Dashboard as two columns at ≥840 | Not built. `sections` is already a `List<Widget>`, so it is a split, not a rewrite. |
| History master–detail | Not built. Needs `app_router.dart` — the detail is a pushed route today. |
| Rail labels beside the glyphs at ≥840 | Not built, and deliberate: the rail is glyph-only like the pill, so both stay one control. |
| A third grid column on a tablet | Not built. Now viable (197–320 cells against a phone's 175) since the card stopped being capped at 690. Owner's call. |
