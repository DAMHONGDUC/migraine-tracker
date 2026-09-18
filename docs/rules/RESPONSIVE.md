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
| `SdBreakpointV2.contentMaxWidth` | `w600` (690 on iPad) | `SdScaffoldV2`, `SdPageWidthV2`, the modal sheet, the paywall |
| `SdBreakpointV2.floatingBarMaxWidth` | `w480` (552 on iPad) | the shell's nav pill |
| `SdBreakpointV2.dialogMaxWidth` | `w480` (552 on iPad) | `SdDialogV2` |

Three fields holding two numbers on purpose, the same way `topGap` and
`bottomGap` are separate: a page, a bar of five glyphs and a one-question dialog
are different things that measure alike today.

```text
iPad 11" landscape, 1180 wide
┌──────────────────────────────────────────────────────────┐
│ app bar — chrome, spans the window                       │
├──────────┬────────────────────────────────┬──────────────┤
│  245     │  body, capped at 690           │     245      │
│  margin  │  (cards, charts, lists)        │   margin     │
├──────────┴───────┬───────────────┬────────┴──────────────┤
│                  │  nav pill 552 │                       │
└──────────────────┴───────────────┴───────────────────────┘
```

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
it asserts both ceilings hold at 820×1180 and 1180×820, **and that neither
engages at 393**.

## Not done yet — open decisions

| Question | State |
|---|---|
| iPhone landscape | `Info.plist` allows it; a 390-tall log flow and paywall are unverified. Owner to decide portrait-only. |
| Dashboard as two columns at ≥840 | Not built. `sections` is already a `List<Widget>`, so it is a split, not a rewrite. |
| History master–detail, and a nav rail | Not built. Both need `app_router.dart` changes — the detail is a pushed route today. |
