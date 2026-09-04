# Dashboard

**Cards in a set are all one size — same width and same height, whatever they
hold.** Owner's rule, governing both of the dashboard's card groups. A group
whose cards each shrink to their own content reads as ragged rather than as a
set: the eye sees several different objects instead of several of the same thing,
and the biggest one silently becomes the most important.

**The dashboard's list carries the gutter, not each section** —
`SdContentPaddingV2.screen(context, floatingNav: true)`. There is no `_Gutter`
wrapper any more; it existed only because the scrolling quick-access row had to
reach the physical screen edge.

**The screen decides whether a section is placed, never the widget.** The list
inserts `sectionGap` between every entry, so a section that hides itself leaves
its gap behind — the double gap the list is built to avoid.

## Today

**Three one-line readings**: pressure, activity and sleep, each a label and a
value, each opening its own Insights tab through `NavigationUtils.toInsights`. A
row whose reading has no value is left out rather than printed as a dash, and
`hasTodayReadingsProvider` answers whether any survive.

- **There is no weather row.** `CurrentWeatherCard` sits on the same screen and
  says the temperature in full, so the row was the same reading printed twice —
  and `InsightsTab.weather`, which it opened, no longer exists.
- **Each row follows the gating of the reading it shows, not the section's.**
  Steps and sleep are free readings (hard rule 1, `docs/PREMIUM_RULES.md`), so a
  free user gets those two; pressure is the one that is sold, so only that row is
  withheld — and `hasTodayReadingsProvider` discounts it for a free user too, or
  the section would be placed and then come up a row short.

## Quick access

**Three tiles on one row, and nothing scrolls** — History, Medications,
pressure-drop alerts. Owner's call, down from six over two rows: a third of the
screen is the narrowest a tile can be and still show its name, and a horizontally
scrolling row advertises a gesture with a cut edge that revealed nothing.

- **The Chart, Insights and Premium tiles are gone** (owner's call). Each led
  somewhere the app already puts in front of the user — Insights and History have
  nav bar tabs, Premium leads Settings — so the row is only the destinations with
  no other one-tap door.
- **Every cell is ONE fixed height (`QuickAccessSection.cellHeight`)**, summed
  from a glyph plus ONE line of label. The label was two lines, because
  "Pressure-drop alerts" needed them at a third of the design width; that tile
  says "Alert" now
  (`dashboardAlertShortcut`), and "Medications" is the widest label left. Check a
  new label against the third-width — a longer one ellipses rather than
  overflowing the fixed cell. A `childAspectRatio` ties height to leftover width,
  which is how the old weather card's details grid came to overflow, so the extent
  is stated instead.
  - **It sums `AppIconSize.large`, the same constant the glyph is drawn at**, so
    the cell and what sits in it cannot drift. `large` (32) is the step here
    rather than `medium`: a third of the screen holds a glyph and one word, so
    the glyph carries the shortcut's identity on its own.
- **The glyph sits above the label**, not beside it: a third of the screen is too
  narrow for both on one line. **A label may wrap to two lines rather than be
  cut** — ellipsing a shortcut's name leaves the user unable to tell what they are
  about to tap.
- **The pressure-alert tile goes through `NavigationUtils.toPressureAlert`**,
  like the Settings row: it selects the pressure tab and opens the threshold
  sheet over it. "Take me to it" is a tab selection plus a branch switch plus the
  sheet, and three call sites must not each half-remember it. (The alert
  notification still uses plain `toPressure` — it is telling the user what
  happened, not asking them to change a setting.)
- `_QuickAccessCard` has no `width` any more, which retires it as the
  constants-rule exception it used to be cited as. Nothing calls
  `medicationAddRequestProvider` either — the Medications screen still honours it,
  so it is a live mechanism with no caller.

## Explore

**A grid two to a row, one cell size for all of them** — `GridView.count` at
`DashboardExploreSection.cellHeight`. Hand-laid rows equalised height *within* a
row but never across them, so cards of different content read as unrelated pairs.

- **Four cards, and four is the point**: reminders, insights, export, About. Two
  columns divide into it evenly — at three, the last row carried one card and half
  a row of nothing.
- **The About card opens the same `/about` the Settings row does**, which is the
  feature list and the free plan's limits. Someone asking "what is this app" wants
  that, not a marketing page.
- **Sleep and steps are no longer in it** (owner's call). They say what Today now
  says in one line each, and they were the only cells carrying a reading and a
  button — which is what forced the whole grid tall enough to hold one.
  `DashboardSleepCard`, `DashboardStepsCard` and `DashboardExploreReading` went
  with them.
- **The cell states its height (`mainAxisExtent`), never a `childAspectRatio`.** A
  ratio ties height to whatever width is left over, which is how the weather
  card's details grid came to overflow. It is summed from what is in a cell: the
  padding, the header row, the gaps, one line of title and two of subtitle — and
  `DashboardExploreSubtitle` caps at two for that reason.
  - **The header row reserves `DashboardExploreCard.headerHeight`, stated as
    `AppIconSize.medium + h4` so it moves when the glyph does**, and `cellHeight`
    reads that constant rather than repeating a number. The extra four is the
    `PremiumBadge` the export cell wears: a badge is a line of `labelSmall`
    inside its own padding — a shade taller than the icon beside it — and a fixed
    cell cannot grow for it. The cells without one simply have four spare, which
    is invisible. It was a bare 24 against a 20 glyph, which stopped being slack
    the moment the glyph went to `AppIconSize.medium`.
- **The export cell is badged and gated.** Export is premium in full, so the cell
  says so before it is tapped and goes through `NavigationUtils.toExport` — a
  paywall out of a card that looked free reads as a bug rather than an offer, the
  same rule `RecordLimitDialog` exists for elsewhere.
- **Every cell clips inside its own box rather than overflowing the grid.** The
  cost of a fixed cell is real and was why this was not a grid before: it cannot
  grow for a long Vietnamese subtitle or a large accessibility text size. So
  `DashboardExploreCard` puts the content in an `Expanded` and every string is
  capped with an ellipsis. Judge a copy change against the cell, not the text.
- **`padding: EdgeInsets.zero` is not optional on that grid.** A scroll view with
  a null padding helps itself to the ambient `MediaQuery` inset, so it arrived
  with the device's safe area stacked on the screen padding the dashboard had
  already applied — a notch's worth of blank space above the first row.
- **`DashboardExploreCard` keeps its `content` slot** rather than a pile of
  optional fields. Today every card puts a sentence there
  (`DashboardExploreSubtitle`), and the slot is what let the health cards carry a
  reading before they moved out.

## The premium banner

**The dashboard leads with `PremiumBanner`, one line offering premium, above
everything else** (owner's call, reversing the call that moved the promo to
Settings). What left this screen was `PremiumCountdownBanner` — a ticking discount
panel with its own Unlock button — which competed with the log button under it.

- **Free users only, and never beside `AttackLimitBanner`.** That one is this same
  pitch with a reason attached, and two premium banners on one screen is how both
  stop being read. Quick access still carries no Premium tile — the banner is the
  dashboard's one premium door.
- **It is the one tinted card on the screen** (owner's call): `SdCardV2`'s
  `fillColor` at `AppColors.primary` **and 0.12 alpha**, inside a `borderColor` of
  the same accent at **0.35** — the exact treatment `PremiumCountdownBanner` wore,
  asked for by name. The fill is what lifts it; the hairline
  (`SdCardV2.borderWidth`) only draws the edge. The dashboard is a stack of cards
  all wearing `AppColors.surface`, so an offer among readouts needs an edge to be
  seen first, and an outline is how a card is picked out without being brighter
  than its neighbours (hard rule 3). **Two earlier attempts were rejected**: a
  solid accent outline at 2 with no fill (owner: too loud — it read as a frame
  drawn around the card rather than the card's own edge), then the same outline as
  a bare hairline, which left the card with nothing but an edge. Both times the
  lesson was that the quiet belongs in the alpha and the *highlight* in the fill,
  not in the thickness of a line. Nothing else on the dashboard takes a border; a
  second one and neither leads.
- **It is one line, and it is NOT an `SdBannerV2`** (owner's call). A banner is a
  44 badge and two lines inside 16 of padding — 76 tall, which made the offer the
  tallest thing above the fold on the screen whose job is the log button. This is
  a 36 badge, the title, the chevron and 8 above and below: 52. **The supporting
  sentence went with the second line**, `dashboardPremiumBannerBody` deleted from
  all seven ARB files — the paywall it opens is where the offer is explained, and
  a dashboard row only has to be worth a tap.

## The weather card

**The weather the user is standing in is a dashboard card, `CurrentWeatherCard`,
directly under quick access** (owner's call). It replaced the Insights weather
tab, whose day strip, metric picker and hourly chart were a screen's worth of
forecast reached by a tab switch — what a user wants at a glance is the conditions
right now, and the dashboard is where a glance happens. `InsightsTab.weather`,
`WeatherMetric`, `weatherMetricProvider` and `weatherDayProvider` are gone.

**The card itself is `core/widgets/weather/WeatherCard`, shared with the attack
detail screen** (owner: "tôi muốn đồng nhất"). Two features draw it, so it cannot
live in either one's `presentation/`. It draws and never fetches: each caller
builds a `WeatherCardData` from its own source — live conditions through
`WeatherCardData.of`, an attack's stored snapshot through `.ofSnapshot`.

### A miss is a moment, never a state

Three things kept the card saying "unavailable" while the user watched, and all
three are fixed together — take any one out and the symptom comes back looking
like the others.

1. **`GeolocatorLocationSource` falls back to `getLastKnownPosition`** when a
   fresh fix fails. A fix indoors or seconds after launch routinely outruns the
   10s limit, the throw came back as no position, and no position is no weather.
   Everything is rounded to ~11km anyway (hard rule 2), so an hour-old position is
   a better answer than an empty card; null only survives on a device that has
   never had a fix.
2. **A null report schedules `ref.invalidateSelf` after `weatherRetryDelay`.** A
   null is a *completed* value — Riverpod does not recompute it because a new
   watcher arrived, so the card kept the miss for as long as the dashboard stayed
   open. The timer dies with the `autoDispose` provider, so a backgrounded app
   retries nothing.
3. **Granting location invalidates `weatherReportProvider` and
   `placeNameProvider`, not just the permission.** Both may already hold a null
   from before the permission existed, so the card would swap the ask for
   "unavailable" the instant the user said yes.
   `weather_location_prompt_test.dart` and `weather_card_retry_test.dart` each
   fail without their half of this.

### Placement and the location prompt

- **It is placed unconditionally, unlike Today beside it.** The card carries its
  own loading skeleton and its own one-line unavailable state, so it always fills
  the slot the list's `sectionGap` reserves. It also means a user who denied
  location still sees that the feature exists, rather than a screen that quietly
  lost a card.
- **With no location permission the card asks for it — `_LocationPrompt`, the
  card's third state** (owner's call). The unavailable line is the honest answer
  for offline and for a backend with no WeatherKit credentials, which are states
  the user can do nothing about; it was also what someone who answered "Not now"
  in onboarding saw forever, which reads as broken rather than switched off. The
  prompt keeps the card's gradient and shape, so the dashboard neither gains nor
  loses a card as the permission changes.
  - **It asks through `AppPermission.ensure`, not the geolocator's own request**,
    so a denial iOS will no longer prompt for falls through to
    `PermissionSettingsSheet` and the Settings app. A second ask that silently does
    nothing is worse than no second ask.
  - **`locationPermissionProvider` only READS the status** — the split
    `LocationSource` keeps between `currentPosition` and `requestPermission` (hard
    rule 2) applies to it too. It is asked BEFORE `weatherReportProvider` is
    watched, so a device with no position spends no callable round trip on a fetch
    that can only come back empty. It is invalidated after the ask and on resume,
    because a permission granted in the Settings app is answered while the app is
    not running.

### What the card draws

- **TWO lines, and no heading** (owner's call, twice). The sky and the temperature
  share one row with the caption; the readings sit under it as bare glyphs and
  numbers. It had a title row and a named grid first, which made a readout the
  user passes on the way somewhere the tallest thing on the dashboard. The `title`
  callers still pass names the SHEET, never the card.
- **The CARD draws no pressure; the detail screen does, for everyone** (owner's
  call, and it moves the paid line — see `docs/PREMIUM_RULES.md`). Keeping it off
  the card is a layout decision: Today, a card below, already prints the reading
  for premium users, so a cell here would be the same number twice on one screen.
  Keeping it in the sheet is a product decision the owner asked for, ungated.
  `_metrics` enforces both by order alone.
  - **That 24h change is FORWARD-looking**, unlike an attack snapshot's. The
    stored one is the 24 hours before the attack; this is the coming 24 hours,
    taken from the report's own hours — the same window the drop alert runs on.
    Same label, because both answer "how far is the pressure moving" and a user
    reading a forecast is already reading the future.
- **The card shows at most `_MetricStrip.maxOnCard` (4) readings**; the detail
  screen shows all. Four is what fits the design width with a number under each
  still legible. **The ORDER in `_metrics` is the gate between the two surfaces** —
  the four free readings of the sky lead, then pressure, the chance of rain,
  sunrise and sunset. There is no second list and no `isCompact` flag; moving a
  reading up the list puts it on the card.
- **The sky sits in a tinted tile and the readings share one tray.** The glyph was
  a bare icon and the four readings floated loose on the gradient, which read as a
  settings row that mentioned the weather. `_ConditionTile` gives the condition an
  object to be (44 square, `AppColors.primary` at 0.14, radius 12) and
  `_MetricStrip` puts the four on one `surfaceElevated` tray — **not a chip each**,
  whose padding ate the width until "12 km/h" no longer fitted a quarter of the
  card. The temperature is `headlineMedium`, the one number the card exists to
  show.
  - **The tile and the tray both publish their size** (`_ConditionTile.size`,
    `_MetricStrip.height`) and the loading skeleton reads both, so the placeholder
    is the size of what replaces it rather than a guess that drifts.
- **Loading is a skeleton in the card's own shape, not a spinner**: the card is a
  fixed two lines, so the dashboard does not reflow when the fetch lands. The
  unavailable state stays a sentence — that one is an answer, not a wait, and a
  skeleton that never resolves is the worst of both.
- **Only what has a value is drawn.** The snapshot never stored a condition code,
  wind, UV or visibility, and WeatherKit omits whatever it has no reading for — so
  the metric grid is four cells on one surface and three on another, and neither
  is missing anything. The headline glyph is drawn only where there IS a
  condition: the "unknown" glyph beside a real temperature reads as a failed load.
- **It is the one card in the app wearing a gradient** (owner's call), so the
  weather reads as the screen's subject rather than one more panel in a stack of
  identical ones. `WeatherCard.gradient` is a tint of `AppColors.primary` over the
  card colour, 0.18 down to 0.04 across the diagonal — **one hue at low alpha,
  never two saturated colours meeting**, because hard rule 3's users are
  photophobic and a card may be distinct without being bright. The far stop is
  0.04 rather than 0, so the corner still reads as the same surface instead of an
  edge. **It does not change with the weather**: a card that turned orange in the
  sun would say what the glyph already says, more loudly, and would be brightest
  exactly when the user's day is. `SdCardV2` takes the `gradient` as a prop — the
  look is a prop, never a second card widget — and the colours come from the app,
  because the design system holds no brand.

### The detail screen

**The whole card opens `WeatherDetailScreen`, and the chevron is a mark rather
than a button** (owner's call). A card-sized target is what a readout with nothing
else to tap should have; an icon button inside a tappable card is a second,
smaller way to do the same thing. Tap and chevron drop together where there is no
reading.

- **It is a screen, and it was a sheet** (owner's call). A sheet is capped at 85%
  of the display and the content outgrew it: ten named readings are five grid
  rows, ten days are ten rows, and every way of dividing that ceiling took room
  from one half to give it to the other. It is pushed by route name
  (`AppRoutes.weather`) with the reading handed over as `extra`, so nothing outside
  the router imports the screen and the two callers — the dashboard's live card,
  an attack's stored one — can mean different readings by it.
- **The page does not scroll; the ten-day forecast inside it does** (owner's
  call). The place, the temperature and every named reading stay on screen, and
  `_RainfallForecast` takes what is left through an `Expanded`. Reaching the last
  day must never push the temperature off the top.
- **The Apple mark sits top-right, beside the place name** (owner's call), drawing
  Apple's logo as `SimpleIcons.apple` rather than the U+F8FF character the ARB used
  to carry — that glyph is Apple's logo only in Apple's own fonts, so with the
  app's bundled face it rendered as a blank box.
- **It is MORE than the card, not the card enlarged** (owner's call). Three things
  are only ever here: every reading named in the two-column `_MetricGrid`, sunrise
  and sunset, and the week ahead. **Sunrise and sunset are last in `_metrics` on
  purpose**, so they fall past `maxOnCard` and reach this surface alone.
- **The metric grid is rows of `Expanded`, two to a row, never a `GridView` with a
  `childAspectRatio`** — same trap as everywhere else on this screen. An odd count
  leaves the last cell at half width rather than stretching it, so it stays the
  size of the five above it. `IntrinsicHeight` per row is what lets
  `CrossAxisAlignment.stretch` match two cells' heights inside a `ListView`'s
  unbounded axis.
- **`WeatherAttribution` is here, not on the card** (owner's call). The credit cost
  the card a whole line to say something no user came for, and the card is one tap
  from it — so the mark is still reachable from every surface drawing Apple's
  data. This is the compact reading of the WeatherKit rule: **if App Review
  objects, put it back on the card, never take it out of the detail screen.** The
  mark belongs to the shared widget, not to the caller — a screen that had to
  remember it is a screen that will forget, which is how the attack detail screen
  gained the mark it was previously missing entirely.

### The week ahead

**`_WeekForecast` is the seven-day list, and it is what the retired Insights
weather card was worth keeping.** One row a day: the weekday (today says
"Today"), the condition glyph, the chance of rain, then the low and high. The old
day strip could show none of that — seven cells sharing a card's width fit a
weekday, a glyph and one temperature, which is why "Today" was an accent rather
than a word there.

- **It comes from `WeatherReport.week` through `WeatherCardData.days`**, so
  `WeatherCardData.of` takes the whole report rather than its `current` block. An
  attack's snapshot leaves it empty and the section is absent — the week a
  migraine happened in is not something the app can reconstruct after the fact.
- **A `Column`, not a `ListView`**: seven rows is fixed and small, and the sheet
  already scrolls — a scroll view inside one needs `shrinkWrap` and gives two
  places to put a scrollbar.
- **A day can be tapped, and the whole grid above follows** (owner's call).
  `WeatherCardData.dayAt(index)` rebuilds the readings against that day; the sheet
  holds only the index. **Day 0 is returned untouched**, so today keeps the live
  reading rather than being replaced by its own forecast. The picked row is marked
  by a tinted fill, never by a colour on its text: the row already spends its
  accent on the condition glyph.
- **What a forecast carries comes straight off `WeatherDaily`**: the condition,
  the UV peak, the chance of rain, sunrise and sunset. **Humidity, wind,
  visibility and pressure are the day's MEAN of its hours**, because WeatherKit
  reports those hourly and never daily — a day has no single value, so one has to
  be chosen. The mean, not the maximum: a maximum answers "how windy could it
  get", a different and scarier question. Only ever shown against a future day,
  where every number is a forecast already.
- **A future day has no temperature and no feels-like** — a day that has not
  happened has no "now" — so the headline falls back to its high and low.
  `WeatherCardData.forecast` is the day the data describes, kept separate from
  `days` (the whole week) for exactly this: one is what the headline reads, the
  other is what the list draws. The headline also falls back to today's high and
  low where the report carried a forecast but no current conditions, so a card with
  a week behind it never comes up blank at the top.

## The risk card

**`RiskScoreCard` is the one forward-looking number on the dashboard**, drawn
from `RiskScoreEngine` (weights, thresholds and the score's own rules:
`lib/features/insights/CLAUDE.md`). What this file owns is how it reads.

- **The title says it is a forecast, and the line under it says it is a
  prediction** (owner's rule). It used to be titled "Next 7 days", which names a
  window and leaves the number to be read as a measurement of something. A
  percentage on a health screen is taken for a fact unless the card says
  otherwise, so it says otherwise twice: `riskCardTitle` = "Attack risk
  forecast", `riskCardSubtitle` = "Next 7 days · a prediction".
- **Every number carries its percent sign** (`riskPercent`). "62" beside a word
  reads as a rating out of ten as easily as a probability.
- **The week is seven labelled `SdProgressRowV2` rows, not seven bars**
  (owner's call). The column of bars could be compared with itself and nothing
  else: the value each bar stood for appeared nowhere, so "how likely is
  Thursday" had no answer on the card. A progress row names the day, shows the
  share and writes the percentage at the end — which is what the design system
  built it for.
- **It carries the same info glyph as every analysis card**, opening
  `AnalysisInfoSheet` with four paragraphs: what the number is, the four signals
  and their weights, why an unreadable signal is named rather than scored zero,
  and that every threshold is the user's own. The card states a probability
  about the user's health; the sheet is where "not a diagnosis" is allowed the
  room to be said.
- **The card still opens the Pressure tab**, where the forecast it is built on
  is drawn in full — the glyph and the card body are two different destinations
  on purpose, so reading the explanation does not cost the reader their place.

## The summary group

**`DashboardSummaryGroup` shows on every launch, empty or not.** Owner's rule. It
used to be gated on `hasAttacks`, which left a new install with a log button, a
row of shortcuts and a grid of links — nothing between the call to action and the
navigation, on the one screen that is supposed to be about the user. An empty
dashboard is a worse first impression than an honest zero.

- **Each card inside owns its own empty state; the group never branches.** The
  week card swaps its trend line for `dashboardWeekEmpty` when neither this week
  nor last week has an attack — a bare "0" with nothing under it reads as a card
  that failed to load.
- **Empty, the severity ring draws the scale instead of a reading:
  `SeverityBreakdownSlices.placeholder`.** Four equal arcs in the real
  `AppColors.intensity` band colours at 0.4 alpha, the band names in the legend
  without counts, and `dashboardSeverityEmpty` under them. A flat grey ring was
  tried first and rejected (owner: boring) — it only said "nothing here", where the
  empty slot's whole job is to say what is coming. **Three things at once mark it
  as a key rather than data**: the arcs are equal, the colours are faded, and no
  label carries a number. It lives beside `SeverityBreakdownSlices.of` because that
  class is where the app's severity vocabulary lives, so the placeholder cannot
  name or colour a band differently from the real chart.
- **Empty, the severity card does not open anything** — the History chart it leads
  to is as empty as the card, and a tap that lands on nothing is worse than a card
  that never offered one. It gets its `onTap` back with the first attack.

## Chevrons

**Every dashboard card that opens something wears a trailing chevron —
`DashboardChevron`.** Owner's rule: the cards read as readouts, so nothing but the
mark tells the user a card is also a door.

- **The two grids are exempt** — quick access and explore are already, visibly,
  lists of links, and a chevron in a half-screen cell would cost the label the
  room it needs.
- **It lives in `core/widgets/`, not in this feature.** `DailyCheckInCard` is
  owned by `daily_log` but drawn on this screen, and a feature may not import
  another feature's `presentation/` — so the shared mark sits in core and the
  name keeps saying which surface it belongs to.
- **One widget, not the recipe typed per card.** The three that already had a
  chevron had drifted — the next-reminder banner was on `AppColors.textSecondary`
  where the others were on `colorScheme.onSurfaceVariant`. `SdBannerV2` draws its
  own to the same spec, so a banner adds nothing.
- **No chevron where the tap is gone.** The severity card drops both together
  while it is empty: the mark promises a screen, so it must never sit above a tap
  that goes nowhere.
- **A card whose trailing slot already holds a button keeps the button** — an
  "Unlock" says what a chevron would, more loudly, and the two together leave the
  text beside them nothing to wrap into. Same for `DashboardLogButton`, which is a
  button, not a card.

## The next-reminder banner

- **It sits directly under the weather card** (owner's call). Both answer "what is
  happening now", so the next dose belongs beside the sky rather than below a
  block of readings the user may not have scrolled as far as.
- **Two lines: the medication name, then when.** It was one sentence with the name
  picked out in the accent colour, which left the name competing with the time
  beside it for the same glance. The name is what the user is looking for, so it
  gets the first line and the accent; `dashboardNextReminderWhen` is the second,
  muted.
