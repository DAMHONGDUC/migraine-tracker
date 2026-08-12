# BaroEase — UI spec (ARCHIVED, 9 Aug 2026)

> **Archived. This describes the app BEFORE the Insights redesign** — before
> the tabbed Insights cards, the weather card's day strip and metric picker,
> the six quick-access tiles and the four-card explore grid. It is kept as the
> brief the redesign was measured against, not as a description of the app.
>
> For what the UI is now, the rules are the authority:
> `docs/rules/DESIGN_SYSTEM.md` and each `lib/features/<x>/CLAUDE.md`.

A brief for a design tool. Everything below described what the app looked like
at the time. Section 1 is non-negotiable and still holds; everything after it
was open to being redrawn — and most of it was.

---

## 1. Hard constraints — a design that breaks any of these cannot ship

1. **Dark theme only. There is no light mode.** The users are photophobic
   (migraine sufferers). Do not produce a light variant.
2. **No pure white anywhere.** Brightest allowed surface is `#1C1C1E`.
   Brightest allowed text is `#E4E2E8`. No `#FFFFFF`, ever, including icons.
3. **No flashing, strobing, pulsing or high-contrast animation.** Motion is
   fade / scale / slide, ≤400ms, gentle curves.
4. **Low-glare, low-saturation palette.** No neon, no vivid gradients across
   a whole screen, no bright alarm reds.
5. **Platform is iOS first**, 393×852pt design frame (iPhone 15/16 class).
   The look is iOS-native, not Material. No Material underline tab bars, no
   FABs, no Android-style app bars.
6. **Type is the platform font (SF Pro).** Do not specify a custom typeface.
7. **Two languages ship: English and Vietnamese.** Vietnamese strings run
   ~25–30% longer and carry stacked diacritics. Every label must survive
   both — no fixed-width buttons sized to English, no single-line labels
   that would need to ellipse.
8. **Accessibility**: minimum 44×44pt tap targets, text contrast ≥4.5:1
   against its surface, and colour is never the only signal (an icon or
   label always accompanies it).

---

## 2. Design tokens in use today

### Colour

| Token | Hex | Used for |
|---|---|---|
| `background` | `#0E0E10` | Screen background |
| `surface` | `#1C1C1E` | Every card, the one card colour |
| `surfaceModal` | `#161618` | Every bottom sheet and dialog — a step *darker* than a card |
| `surfaceElevated` | `#2C2C2E` | Anything sitting *on* a card/sheet: option tiles, filter chips, snack bars, chart tooltips, dividers |
| `primary` | `#A594F9` | Accent — muted lavender. Primary buttons, selected states, links |
| `onPrimary` | `#1C1C1E` | Text/icon on a primary fill |
| `secondary` | `#7FB8B0` | Soft teal. Additive/confirm actions ("save" ticks, positive buttons) |
| `error` | `#E5766E` | Errors, destructive actions, unread badges |
| `chartSeries` | `#9182EC` | Chart line/bar fill |
| `chartGrid` | `#2C2C2E` | Chart gridlines |
| `textPrimary` | `#E4E2E8` | Body and heading text |
| `textSecondary` | `#9E9CA6` | Supporting copy, captions, disabled |
| `barrier` | `#000000` @ 60% | Scrim behind modals |

**Severity scale** (pain intensity 1–10), used for fills and borders only —
never for text, because the red is below the text contrast floor:

| Band | Hex | Range |
|---|---|---|
| Mild | `#6FA890` (green) | 1–3 |
| Moderate | `#D9C24E` (yellow) | 4–6 |
| Severe | `#E8823A` (orange) | 7–8 |
| Extreme | `#CF3B34` (red) | 9–10 |

These four are colour-blind validated against the dark surface (each adjacent
pair clears ΔE ≥ 15 normal vision / ≥ 8 CVD). **Do not shift these values.**

### Type scale (pt at the 393pt design width)

| Role | Size / line-height / weight | Where |
|---|---|---|
| displaySmall | 36 / 44 / 400 | Big numeric readouts |
| headlineMedium | 28 / 36 / 400 | Screen hero numbers |
| headlineSmall | 24 / 32 / 400 | Card hero values |
| titleLarge | 22 / 28 / 400 | App bar titles |
| titleMedium | 16 / 24 / 500 | Card titles, section titles |
| titleSmall | 14 / 20 / 500 | Sub-titles |
| bodyLarge | 16 / 24 / 400 | List row primary text |
| bodyMedium | 14 / 20 / 400 | Body copy, list row subtitle |
| bodySmall | 12 / 16 / 400 | Captions |
| labelLarge | 14 / 20 / 500 | Button labels |
| labelSmall | 11 / 16 / 500 | Chips, badges |
| labelTiny | 10 / — / 500 | Bottom-nav labels, step-bar labels |

Two modifiers only: `.secondary` (recolour to `#9E9CA6`) and `.w600`
(semi-bold).

### Spacing & geometry

- Screen gutter: **16** either side, for every screen.
- Gap under the app bar to first content: **8**.
- Gap between two rows of the same list: **12**.
- Gap between two distinct cards/sections stacked on a screen: **20**.
- Gap above/below a pinned bottom button: **16**.
- Card corner radius: **16**. Modal sheet top radius: **20**.
- Floating bar (nav pill, log step bar): **56** tall, fully rounded
  (radius = 28), **24** off each side edge, **16–20** off the bottom edge.
- Allowed spacing steps: 2, 4, 6, 8, 12, 14, 16, 20, 24, 28, 32, 40, 44, 48,
  56, 64. Nothing off this ladder.
- Default icon size **24**; app-bar icon glyphs **20** inside a 48 tap target.

### Material treatments

Three, and only three:

1. **Flat opaque** — cards (`#1C1C1E`), sheets and dialogs (`#161618`).
   Sheets are never translucent.
2. **Liquid Glass (frosted blur + hairline edge)** — reserved for *chrome*:
   the app bar, the floating nav pill, the log flow's step bar, the round
   icon buttons in a sheet header, and the segmented tab track on the
   notifications screen. Content scrolls *behind* frosted chrome.
3. **One deliberate exception** — the paywall panel is frosted glass even
   though it is a sheet.

---

## 3. Component inventory

Everything below already exists as a built component. A redesign should
restyle these rather than invent parallel ones.

**Structure**
- App bar: frosted, centred title, optional back chevron left, actions right.
- Floating bottom nav: a 5-segment pill floating over content, with a sliding
  selection indicator. Tabs: Dashboard, History, Medications, Insights,
  Settings. Icon + tiny label, selected item tinted lavender.
- Section header: small caps-ish label above a group of rows.
- Card: flat `#1C1C1E`, radius 16, no built-in padding or margin.
- Chart card: a card with a title row and a chart body.
- Banner: a card variant carrying an icon, a message and one action.
- Divider: 1px `#2C2C2E`, drawn only *between* rows, never on a card edge.

**Controls**
- Button, 5 variants: primary (lavender fill), secondary (tonal), outlined,
  text, destructive (red fill), positive (teal fill). One shared padding
  (24 horizontal / 12 vertical) so all variants read the same size. Three
  sizes: small ×0.75, medium ×1, large ×1.25. Optional leading icon; when
  buttons are stacked, glyphs and label starts align on the same x.
- App-bar icon button: 20pt glyph in an invisible 48pt target, optional
  frosted circle behind it.
- Segmented tabs: a rounded track with per-segment labels and counts.
- Filter pill / chip: rounded, `#2C2C2E` at rest, lavender when active.
- Text field: rounded, `#2C2C2E`, with an optional trailing glyph.
- Switch, value slider, progress row.
- Badge: a dot, or a count capped at a max (renders "99+").
- Empty state: icon, headline, supporting line, optional action.

**Modals**
- Bottom sheet: `#161618`, top radius 20, drag handle, max height 85% of the
  screen, optional pinned footer.
- Sheet header: X on the left (leave), centred title, tick-or-pencil on the
  right (commit, tinted teal). Both are frosted circles.
- Dialog: `#161618`, radius, title + body + a row of text buttons.
- Snack bar: `#2C2C2E` card with an accent icon and a hairline edge — never a
  full-bleed coloured fill. One at a time.

**Charts** (all custom-drawn, `#9182EC` series on `#2C2C2E` gridlines)
- Donut (severity breakdown, four bands)
- Bar chart (weekly frequency, sleep hours, step counts)
- Line chart (48h pressure forecast, intensity trend)
- Horizontal breakdown bars (head location, time of day)

---

## 4. Screens

22 screens. 5 are tabs behind the floating nav; the rest are pushed.

### Tab 1 — Dashboard (`/dashboard`)
The home screen. Vertically stacked, 20 between sections:
- App bar: app name, a **bell icon with a red unread count badge**.
- **The log button** — the single most important element on the screen. A
  large primary CTA that opens the 3-tap logging flow. A user reaching for
  this is often mid-migraine; it must be findable without reading.
- Quick access row — shortcuts.
- Optional banners (any of): next medication reminder, free-plan record limit
  reached, premium trial countdown.
- Week summary card — attack count and trend for the last 7 days.
- Severity card — the donut, four bands.
- Explore section — cards leading into Insights.

### Tab 2 — History (`/history`)
- Two views behind a toggle pill (which lives *in* the list, not in chrome):
  **list** and **calendar**.
- A filter row (date range, intensity, location, medication).
- List view: one card per attack — time, intensity number in its severity
  colour, head location, medication.
- Calendar view: a month grid, each day tinted by that day's worst intensity;
  tapping a day reveals its attacks below.
- A deck of charts below: severity donut (free), plus 4 premium charts
  (intensity trend, weekly frequency, time of day, location breakdown).
  **Premium charts are shown blurred under a scrim with an unlock button
  centred on them** — the blurred content is sample data, never the user's.

### Tab 3 — Medications (`/medications`)
- A search field in the app bar; a filter row below it.
- One card per medication: name, type, and its reminder count.
- Empty state when none.

### Tab 4 — Insights (`/insights`)
Three cards, each tappable through to a detail screen:
- **Pressure card** — a 48h barometric forecast line chart above a
  correlation readout ("X of your Y attacks fell during a pressure drop").
- **Activity card** — exertion + step correlation.
- **Sleep card** — sleep correlation, plus a summary bar chart of the window.

Each correlation body has **six possible states** and all six need a design:
1. *Empty* — no data at all yet.
2. *Progress* — free user, "keep logging: 7 of 15 attacks" with a progress bar.
3. *Count-only* — sample too thin for a percentage, shows raw counts ("2 of 3").
4. *Preliminary* — a real figure plus a note saying it will still move.
5. *Settled insight* — the headline figure, large.
6. *No variation* — "your pressure barely changed over this window".

Plus a **premium teaser** state for free users.

### Tab 5 — Settings (`/settings`)
Grouped `ListTile` rows (flush, no gap between rows, dividers between them),
under section headers: General, Your data, About. Rows lead to: language,
notifications (with unread count), alerts, sleep, activity, premium, account,
sync (with a live spinner + % while a sync runs), export, delete all data,
contact, legal.

### The log flow (`/log`) — the most important flow in the app
A 4-step wizard with a floating **step bar** at the bottom (4 nodes, a label
under each), and a "Next" button in the app bar.
1. **Intensity** — a large circular dial, 1–10, filling with the severity
   colour of the current value.
2. **Head location** — a head diagram with a 3-column grid of location tiles
   below it (5 tiles).
3. **Medication** — a 2-column grid of medication tiles, plus "No medication".
4. **Exertion** — a 2-column grid of 4 tiles (none / light / moderate / hard).
   Skippable.
Then a **saved** confirmation step.

Design constraint: steps 1–3 are sacred and must stay one tap each. Selected
tiles carry a 2px border where unselected carry 1px — tiles must stay the
same size either way.

### Pushed screens
- **Attack detail** (`/attack/:id`) — everything logged, editable, plus the
  weather snapshot at the time.
- **Medication detail** (`/medication/:id`) — an edit-in-place name field
  (pencil glyph at rest, teal tick while focused), a reminder list, and a
  pinned "Add reminder" button at the bottom edge.
- **Pressure** (`/pressure`) — alert switch and threshold slider *first*, then
  the forecast chart and correlation. On every insight detail screen the
  controls come first and the readings last.
- **Activity** (`/activity`), **Sleep** (`/sleep`) — same shape: an Apple
  Health connect switch first, then summary + correlation cards.
- **Notifications** (`/notifications`) — two segmented tabs (Reminders /
  Pressure) with counts, a list of rows each carrying an unread dot in red.
- **Notification detail** (`/notification/:id`).
- **Paywall** (`/paywall`) — a frosted glass sheet. Three plans (monthly
  $4.99 / yearly $29.99 / lifetime $44.99), a benefit list, a CTA, restore
  and legal links.
- **Premium** (`/premium`) — the entitlement status screen.
- **Login** (`/login`) — Apple and Google buttons, stacked, glyph- and
  label-aligned, plus a privacy note.
- **Account** (`/account`) — profile, sign out, delete account.
- **Sync** (`/sync`) — a determinate progress bar with a percentage while
  running, last-synced time when idle, one manual sync button.
- **Export** (`/export`) — format picker, date range, and a history list of
  past exports. **Export preview** (`/export/:id`) renders a CSV as a table
  and JSON as text.
- **Onboarding** (`/onboarding`) — including a mandatory medical disclaimer.
- **Contact** (`/contact`).

---

## 5. Recurring states every screen design must cover

- **Loading** — skeleton or spinner.
- **Empty** — icon + headline + line + optional action.
- **Error** — a snack bar, never a red screen.
- **Offline** — logging must still work fully; weather is simply absent.
- **Premium-locked** — either a blurred sample under a scrim with an unlock
  button, or a teaser body. Never an empty box.
- **Free-limit reached** — a banner on the dashboard and a dialog naming the
  limit before the paywall opens.

---

## 6. What the redesign is being asked to improve

The current UI is correct and consistent but visually plain: flat dark cards
in a vertical stack, one accent colour, little hierarchy between a hero number
and its supporting copy, and charts that read as data dumps rather than
answers. The brief is to raise the perceived quality — hierarchy, rhythm,
depth, motion — **without** touching any constraint in section 1 and without
adding a step to the log flow.
