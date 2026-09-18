# Tablet and window sizes

iPad is a shipping target (`TARGETED_DEVICE_FAMILY = "1,2"`, reviewed on iPad
Air 11" M3) and multitasking is on — there is no `UIRequiresFullScreen`, so
Split View hands the app a phone-width window on an iPad. Two rules make that
work, and both are **no-ops on every phone**.

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

## Rule 2 — the content column has a ceiling

| Ceiling | Value | Applied by |
|---|---|---|
| `SdBreakpointV2.contentMaxWidth` | `w800` (920 on iPad) | `SdScaffoldV2`, `SdPageWidthV2`, the modal sheet, the paywall |
| `SdBreakpointV2.floatingBarMaxWidth` | `w480` (552 on iPad) | the shell's nav pill |
| `SdBreakpointV2.dialogMaxWidth` | `w480` (552 on iPad) | `SdDialogV2` |

**The app bar is inside the column.** `SdScaffoldV2` caps the whole `Scaffold`,
not just its body, so a title and the cards under it share one leading edge — a
header spanning the window over a narrower column reads as two screens stacked.
A `ColoredBox` behind it paints the margin either side, because a pushed route
has no surface of its own and would otherwise show black strips.

That is also why `SdCollapsingFilterScaffoldV2` has nothing special to do any
more: its pinned filter strip is positioned inside the capped screen, so it
lines up under the app bar it continues.

Three fields holding two numbers on purpose, the same way `topGap` and
`bottomGap` are separate: a page, a bar of five glyphs and a one-question dialog
are different things that measure alike today.

## Rule 3 — the shell's nav moves to the leading edge

| Window class | Width | Chrome | Bottom inset on a tab screen |
|---|---|---|---|
| `compact` | < 600 | `SdBottomNavigationV2` — floating pill, body scrolls behind it | pill footprint + 18 = ~100 |
| `medium` / `expanded` | ≥ 600 | `SdNavigationRailV2` — pill stood on its end, leading edge | `detailBottom` = ~20 |

```text
iPad 11" landscape, 1180 x 820
┌─────┬──────────┬──────────────────────────┬──────────────┐
│     │          │ app bar, capped at 920   │              │
│ ▓▓▓ │    75    ├──────────────────────────┤      75      │
│ ▓▓▓ │  margin  │ body, capped at 920      │   margin     │
│ 110 │          │ (cards, charts, lists)   │              │
│     │          │                          │              │
└─────┴──────────┴──────────────────────────┴──────────────┘
  rail  64 thick + 23 air either side = a 110 column
        5 cells of 110 = 552 long, centred vertically
  body  1180 - 110 = 1070 available, column capped at 920
```

An 11" **portrait** window is 820 wide, so the body gets 710 and the 920 cap
never bites — the column is the window. The cap is a landscape rule, which is
the one window with room to waste.

**Same destinations, same cell, same thumb.** `SdNavSegmentV2` is one widget
used by both chromes, and `SdNavDestinationV2` is one list built once in
`AppShell` — a tab cannot look like one control on a phone and another on an
iPad. Two things differ, and both follow from the axis:

| What | Pill (phone) | Rail (tablet) |
|---|---|---|
| Layout | floats; body passes behind the glass | takes a real 110 column |
| Cell per tab | 64 wide (`floatingBarHeight`) | 110 long (`floatingRailCellHeight`) |
| Swipe between tabs | yes, 48pt drag | **no** — at this width a horizontal drag is a chart being panned |
| `SdFloatingBarScopeV2` | wraps the body | absent: nothing is on the bottom edge |

That last row is what reclaims the bottom inset. `floatingNav: true` means
*"I am a tab screen"*, not *"there is a bar below me"*; `SdContentPaddingV2.bottom`
asks the scope which chrome is actually up, so the five tab screens stop
reserving a pill's height of nothing on a tablet. The scope is presence-only
and imports nothing from `SdContentPaddingV2` — content padding is what asks
the question, so the answer must not depend on it.

**A screen built on `SdScaffoldV2` gets this for free.** Reach for
`SdPageWidthV2` by hand only where a screen builds its own `Scaffold`
(onboarding, the paywall) or where part of the body is chrome —
`SdCollapsingFilterScaffoldV2` passes `constrainBodyWidth: false` and wraps its
list, so the frosted filter strip still spans the window like the app bar it
continues.

## What the cap already solved, so do not "fix" it again

A 2-up grid inside a 690 column gets **339-wide cells against a phone's 361**.
Widening those grids to 3 or 4 columns on a tablet would make every cell
*narrower* than it is on an iPhone. The grids are correct as they are:
`QuickAccessSection`, `DashboardExploreSection`, `IconOptionGrid`,
`HeadRegionGrid`.

## Measure the window, never the device

`MediaQuery.sizeOf(context).width`, never `shortestSide` and never a platform
check. An iPad in Split View is a 507-wide window, and a layout that asked
"am I on an iPad" would put a tablet layout in it.

## Testing

`pumpApp(tester, surfaceSize: ...)` sets the window; the default stays 393×852,
so every existing test still measures the screen the app was drawn for.
`test/core/tablet_layout_test.dart` is the only file that pumps anything wider —
it asserts all three rules hold at 820×1180 and 1180×820, **and that none of
them engages at 393**: the scale ceiling, the column ceiling, which chrome the
shell picks, that the app bar shares the content column's leading edge, that
the column clears the rail, that the rail is longer than it is thick, that all
five tabs still switch from it, and that the bottom inset is reclaimed on a
tablet and kept on a phone.

## Not done yet — open decisions

| Question | State |
|---|---|
| iPhone landscape | `Info.plist` allows it; a 390-tall log flow and paywall are unverified. Owner to decide portrait-only. |
| Dashboard as two columns at ≥840 | Not built. `sections` is already a `List<Widget>`, so it is a split, not a rewrite. |
| History master–detail | Not built. Needs `app_router.dart` — the detail is a pushed route today. |
| Rail labels beside the glyphs at ≥840 | Not built, and deliberate: the rail is glyph-only like the pill, so both stay one control. |
