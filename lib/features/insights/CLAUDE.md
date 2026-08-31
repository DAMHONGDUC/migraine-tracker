# Insights

The three tabs, the two cards each one carries, and the doors that reach them.

**Weather is not here any more.** The live conditions moved to the dashboard as
`CurrentWeatherCard` (owner's call) — see `lib/features/dashboard/CLAUDE.md`.
The whole day-strip / metric-picker / hourly-chart card went with it: what
survived is the current reading, because that is what a glance is for and it did
not deserve a tab. `InsightsTab` has no `weather` member, the screen opens on
`pressure`, and `WeatherMetric`, `weatherMetricProvider` and `weatherDayProvider`
are gone entirely.

## Two cards per tab: the reading, then the analysis

**Every Insights tab is a chart card and an analysis card — owner's rule.** Each
tab used to be one card with a divider through it, which made a measurement and
the conclusion drawn from it read as one long section. A card is this app's unit
of "one subject", so the two get one each, separated by
`SdContentPaddingV2.sectionGap`.

| Tab | Chart card | Analysis card(s) |
|---|---|---|
| Pressure | `PressureForecastBody` + `_AlertControls` | "Analysis": `TriggerVerdictBody`, `CorrelationBody`, `PressureHistoryBody` |
| Activity | `_StepsSection` | "Physical exertion", then "Steps & attacks" — **one card each** |
| Sleep | `_NightsSection` | "Sleep & attacks" |

**Exertion and steps are two cards, not two sections of one** (owner's call).
They were under a single "Analysis" heading, which put a self-reported share
and a HealthKit comparison on one surface as if they answered the same
question. They do not: one has no baseline of days without an attack and the
other has two groups of days, and the explanation behind each says something
different.

**Every analysis card carries an info glyph that opens `InsightInfoSheet`**
(owner's rule). A correlation states a relationship in one sentence, and the
sentence alone never says what was compared against what, how the number was
arrived at, or why the card is still empty. Three paragraphs each, in this
order, and the third is the one that matters:

1. what the card compares,
2. where the data comes from and what it is waiting for,
3. **what it cannot claim** — a pattern is not a cause, and each card has its
   own reason. Exertion has no record of the days without an attack, so it is a
   share and never a comparison. A step difference can run either way: the
   attack can follow the hard day, or be the reason the day ended up quiet. A
   short night can be an early sign of the attack that was already coming.

- The sheet carries no commit — nothing to save, so the X is the only way out.
- `InsightCard.onInfo` draws the glyph, quiet, in the title row: it is there for
  the reader who stops, not a call to action.
- **Locked, a tab collapses to one card with one pitch** — pressure and activity
  alike. Two locked cards would be two pitches for one purchase.

- **The alert rides on the chart card**, not the analysis one: it fires on what
  the forecast above it draws.
- **`PressureHistoryBody` stays with the analysis** even though it is a chart —
  it is the working behind the sentence directly above it, not a reading of its
  own.
- **Locked, the pressure tab collapses back to one card.** One pitch for the
  whole tab, not one per card, so the locked branch returns a single titled
  `InsightCard` carrying the `PremiumBadge`.
- **`InsightCard.title` is nullable** for exactly this: a card the tab strip
  above already names skips the heading row entirely rather than opening on 16pt
  of empty.
- **Dividers inside these cards are `InsightCardDivider`, not `SdDividerV2`** —
  they cancel `InsightCard.gutter` and run to the card's own edges. A rule that
  stops 20pt short reads as a line under one column instead of the break between
  two sections.

## One card for everything pressure

`PressureCard` on the Insights pressure tab holds the 7-day forecast, the
correlation and the alert row together (`pressure_card_alert.dart`
is its part file). They were three places before — a card on Insights, another
beside it, and a Settings row two taps away — so the number and the alert it
drives never appeared together.

**There is no detail screen behind it.** `/pressure` existed to hold the alert
controls; they are on the card now, so the card is the destination rather than a
preview of one — which is why it takes no `onTap` and draws no chevron. Every
door that means "pressure" — the Settings row (`AlertsSettingsTile`), the
dashboard tile, the alert notification — selects this tab through
`NavigationUtils.toPressure`.

**The widgets live under `insights/`, not `alerts/`**, because they are insights'
own and anything in `alerts/` reaching into `insights/presentation/` would break
the feature dependency rule.

- **A door that means *alerts* opens the sheet, not a highlight:
  `NavigationUtils.toPressureAlert`** (owner's call). It used to land on the tab
  and light the alert row up — asking the user to find a highlight and then tap
  it, two steps to reach the thing the door was named after. The sheet over the
  tab is the same destination with neither, so `pressureAlertHighlightProvider`,
  the scroll-to-centre and the fading tint are all gone and `_AlertControls` is a
  plain `ConsumerWidget` again.
  - **Only with premium, and that check lives in `NavigationUtils`.** Without it
    the card renders one pitch and no controls, so a sheet over it would be
    editing something the user cannot have.
  - **`AlertThresholdEditor.open` is the one place that opens it and applies the
    answer**, because four doors reach it: the Settings row, the dashboard
    shortcut, the alerts section and the card's own row. A sheet opened without
    the apply discards the answer, which looks exactly like a save that worked.
- **The Apple Weather mark sits bottom-right of `PressureForecastBody`, and it is
  the `WeatherAttribution` widget, never a plain `Text`.** WeatherKit requires the
  mark to LINK to Apple's attribution page and App Review checks for it — a credit
  that only reads right is not compliance. It lives in `core/widgets/weather/`
  beside the shared weather card, whose own copy is drawn on the detail screen
  rather than on the card.
- **Bodies are cardless, and `InsightCard` is the only shell.** `CorrelationBody`
  and `PressureForecastBody` are the content; the tab's two cards place them. The
  per-body card shells (`CorrelationCard`, `StepSummaryCard`, `SleepSummaryCard`,
  the three `*CorrelationCard`s) went with the detail screens that were their
  only callers. `InsightCard` takes an `onTap` and draws the chevron itself —
  never add one at a call site.
- **The forecast is premium again, and this has flipped twice — do not flip it a
  third time without the owner saying so.** It shipped premium, was reversed to
  free ("seeing the pressure you live in is the app's own promise"), and is
  premium once more now that `CurrentWeatherCard` carries the free weather. The
  promise is kept by that card; the pressure chart is the paid reading.
  `premiumLockedForecast` is its pitch, and `PressureCard`'s `PremiumBadge` marks
  the whole card rather than just the alert.
- **The alert is ONE `_AlertRow`, and `AlertThresholdSheet` behind it owns both
  answers.** It was a switch row above a threshold row: two titles saying the same
  word, a control on one and a value on the other, and the number the alert
  actually runs on readable only by opening the second. The row now states both —
  `AlertsSettingsLabel.summary`, "On · 5 hPa" or "Off" — and one tap opens the
  sheet that sets them.
  - The row keeps its **chevron after the value**: without it the row reads as a
    readout and nothing says a sheet is one tap away. It takes the `onTap` for the
    whole row now, because there is no control inside it to fight over the tap.
  - `_AlertRow.height` stays fixed so the highlight the doors ask for lands on a
    row of a known height whatever it holds.
  - The section heading is gone: it said "Pressure-drop alerts" directly above a
    row whose title said the same thing. The sentence under the row explains what
    the alert does while it is on, and says what it would do while it is off.
- **Without premium, neither alert control is built — not the switch, not the
  threshold.** Owner's call, reversing the first version, which showed both inert
  with a lock glyph on the theory that a locked control still says what it would
  do. It does not: a switch that will not switch and a threshold row that will not
  open read as a broken screen rather than as an offer. Both surfaces follow this
  — the card returns its `_AlertPitch` (the badge, one line on what the alert
  does, one Unlock button), and `AlertsSettingsTile` returns `PremiumTileGate`'s
  locked row.
  - **The check comes before the settings are read**, so the locked branch never
    touches `alertsControllerProvider` — the same shape as `PremiumGate`, where
    the gate is the data and not the styling.
  - This is why the tab staying open to everyone is safe: the forecast is the
    free half, and the alert half is absent rather than half-operable.
- **Every Unlock button in the app is `PremiumUnlockButton`, and it takes no
  options** — filled, small, compact, no glyph. It used to take a `variant` so the
  blurred chart cover could be louder than the prompts, which is exactly the drift
  one widget exists to prevent. Filled because it is the one live action on a
  surface that is otherwise inert, and because it has to read against that cover's
  scrim; no padlock because the word is unambiguous and the glyph was a fifth of
  the button's width.

## The tabbed screen

**Insights shows ONE card at a time, behind a segmented switch under the app
bar** (owner's call). `SdSegmentedTabsV2` in the `Column` above the body, one tab
per card — Pressure, Activity, Sleep — with the selection in
`insightsTabProvider`. They used to stack in one scroll view, which made the
screen a long column of unrelated subjects and left the card a user came for
several screens down.

- **The strip is built from the tabs that exist, not from `InsightsTab.values`.**
  Sleep is absent off iOS, so it is three segments there and two elsewhere. The
  stored tab is checked against that list before use — a tab can leave it, and
  indexing a shorter strip would throw.
- **A tab's label is its card's name, from the same ARB key**
  (`insightsPressureTitle`, `activityCardTitle`, `sleepCardTitle`), so the segment
  and the card cannot come to disagree.
  - **Which is why no unlocked card carries a heading of its own.** All three
    tabs open straight onto their content: the tab above already says the word.
    The one exception is the pressure tab while it is locked, where the title row
    is also where its `PremiumBadge` sits.
- **Each tab waits only on what it draws.** The screen used to hold every card
  behind one `switch` on both correlation providers, so a card needing neither
  stayed blank until the engines had run.
- **Tabs are kept alive in an `IndexedStack` once opened, and built lazily until
  then.** A `switch` that built only the selected card unmounted the others, so
  returning rebuilt from nothing: the scroll offset was gone and every chart
  replayed its entry animation, which reads as reloading. None of these providers
  is `autoDispose`, so the data was never refetched — what was lost was widget
  state. Lazily, because mounting them all up front would fire a forecast fetch
  and two HealthKit reads on a screen showing one card.
- **Pull-to-refresh invalidates everything, not just the visible tab**: the
  gesture belongs to the screen rather than to the card in front of it.

## There are no insight detail screens

**`/activity` and `/sleep` are gone, and so is `/pressure` before them** (owner's
call). Each held the same reading and the same analysis as its tab, reachable
only from Settings — a second copy of one subject, and a second place for it to
drift. **The Settings rows are doors to the tab**:
`NavigationUtils.toInsights(context, ref, InsightsTab.activity | .sleep)`.

- **The Apple Health switch moved onto the card it fills.**
  `HealthConnectionTile` sits at the top of the activity and sleep chart cards,
  above the divider, with the privacy caption under the reading. A switch two
  screens away from the empty chart it fills is a switch nobody connects.
  - **It lives in `insights/presentation/widgets/` now**, not
    `core/widgets/sections/`: Insights is the only surface that draws it, and
    `health/presentation/` would be a forbidden import from here.
  - **`HealthConnectPrompt` is deleted with it.** Its Connect button and the
    switch above it were two ways to grant one permission; the disconnected state
    is now the switch plus the line saying what connecting would give.
  - **App Store 2.5.1 is why the copy names Apple Health, not the section
    header.** Submission 1.0(11) was rejected for not identifying HealthKit in
    the UI. The header that answered it is gone from Settings, and what carries
    the identification now is the switch's own title — "Apple Health sleep",
    "Apple Health steps" — plus the caption under it, on a tab in the main nav
    and behind no gate.
- **Each tab is a free reading over a premium analysis.** Owner's spec: the first
  card is what was measured and is free, the second is the correlation drawn from
  it, which is premium. `docs/PREMIUM_RULES.md` is the authority on which half is
  which.
- **No card takes a card-level `onTap`, and so none wears a chevron.** Each owns
  an interactive control — a range selector, a switch, an alert row — and a tap on
  the card would fight the control inside it.
- **The free half must never be gated, even when the analysis under it is.** It
  is the answer to "did connecting Apple Health work" and "what is the pressure
  doing"; locking it leaves a user who just flipped a switch looking at nothing.
- **What a locked analysis blurs is a sample, never the user's own data.**
  `PremiumChartLock` draws `sampleExertionCorrelationProvider` /
  `sampleSleepCorrelationProvider`, both running `SampleChartData` through the
  SAME engines as the real cards — so the preview cannot drift from what premium
  unlocks, and a free user's tree still holds no real premium data.
  `SleepCorrelationBody` takes an optional `result` for exactly this, and passing
  it means the provider is never watched, so no HealthKit read is issued for a
  free user.
- **Neither Settings row is premium-gated**, and the sleep one used to be. Same
  rule as the free half above: the tab behind the row holds the Apple Health
  switch and a free reading, so a locked row hides something the user already has.
  Submission 1.0(11) was rejected under App Store 2.5.1 partly because of that
  gate — with the paywall returning no offerings, the sleep row could not be
  unlocked, and it led to the app's only surface naming Apple Health. Inside the
  activity tab, the step half of the analysis shows `premiumLockedSteps` until
  premium, and is absent entirely off iOS (`healthAvailableProvider`).

## The health range selector

**The step and sleep charts share one selector: D / W / M / 6M**
(`HealthRangeSelector`, `HealthRange`), like Apple Health's own. One widget and
one enum for both, so a range cannot mean different things on the two cards.

- **Single letters, not words.** Four segments share a card's width, and "6
  months" spelled out does not fit at the 393pt design width in either locale.
- **Only half a year groups into weeks** (`HealthRange.isWeekly`). 182 bars on a
  card ~350pt wide is under 2pt each — a texture, not a chart. `HealthRangeBuckets`
  does the grouping, and **steps SUM while sleep AVERAGES**: "56 hours" for a week
  says nothing a reader can compare against a night, and every other sleep figure
  in the app is per-night.
- **A bucket with no data is absent, never a zero bar** — the rule the aggregators
  already follow, because "no record" is not "no steps" and not "no sleep".
- **The Day range for steps is hourly** (`StepHour`, `StepHourAggregator`,
  `HealthRepository.stepHours`): a day is one `StepDay`, and one bar is not a
  chart. A sample is credited to the hour it *starts* in, because splitting it
  would need a distribution HealthKit does not report.
- **The Day range for sleep is the one night, not its stages.** This `health`
  version collapses IN_BED / ASLEEP / AWAKE onto a single HealthKit type and drops
  the category value before Dart sees it, so a hypnogram would be invented. Don't
  add one without first checking the plugin can tell the stages apart.
- **Labels are dropped above `HealthRangeChart._maxLabelledBars` (14)** rather
  than overlapped: 30 day-of-month numbers do not fit, and a smear of digits under
  the axis is worse than none.

## The pressure correlation's denominator

**The share has a denominator, and it is the `DailyWeather` table.** It used to
answer only "what share of MY attacks fell during drops", never "do drops make me
more likely to attack", so a user in a stormy climate scored high for free.
`DailyPressureRecorder` writes one reading per local day whether or not an attack
happened, and `CorrelationEngine` compares the attack rate on drop days against
calm days (`PressureBaseline`).

- **It must never sync** (hard rule 1): a per-day trail of the weather where the
  user was is a location history, and every device recomputes its own. It IS in
  the GDPR wipe for the same reason — derived from their location, so it is theirs.
- **Days, not attacks**: three attacks in one day is one day that ended in an
  attack, or a single bad day carries the whole comparison.
- **Both sides need `minDaysPerSide` (5) or there is no baseline at all** — below
  it one day's weather swings the rate 20 points and the card flips between "twice
  as likely" and "no difference". `timesMoreLikely` is null when no calm day had an
  attack, because the alternative is printing "infinitely more likely".
- **A null baseline is the normal state for an existing user**, whose history
  predates the daily readings. The share still renders; nothing is taken away.
- **Recorded at most once per local day**, best-effort and silent like
  `WeatherAttachService` — launch and resume both fire it, and a day the app was
  never opened is simply a gap in the sample.

## The three analyses that are not correlations

`MedicationEffectivenessEngine`, `MigraineDaysEngine` and
`MedicationOveruseEngine` sit beside the four correlation engines and are
shaped differently on purpose.

- **They return plain summaries, not sealed results.** A correlation states a
  *relationship*, which a thin sample can make a false claim about, so those
  grade themselves and carry an insufficient-data variant. These three are
  counts. One month of logging gives a true count of one month, so there is
  nothing to withhold and no minimum to grade against.
  `MedicationEffectivenessResult` is the exception that proves it: it *is*
  sealed, because a relief *rate* is a claim, and under
  `minAnswersForShare` (5) a row states "2 of 3" instead.
- **`MedicationEffectivenessEngine` replaced `MedicationEffectTally`**, which
  lived in `attacks/domain/services/` and counted helped/partly/didNotHelp for
  one drug at a time. Nothing put two medications side by side, which is the
  question a prescription changes on. Ranking is by **doses taken, never by
  relief rate** — a rate puts the drug taken twice above the one taken forty
  times. `medianIntensity` rides along as the confound guard: the drug kept
  for the 9/10 attacks would otherwise read as the weaker one.
- **Every day count in all three is a LOCAL day.** `Attack.startedAt` is
  stored in UTC, so a 23:30 attack is the next UTC day and lands in the wrong
  month at the end of one. Same rule the sleep engine already followed.
- **A month with no attacks stays in the window as a zero.** It is not missing
  data — it is the best month the user had, and dropping it would hide exactly
  the result a preventive is meant to produce. This is the opposite of the
  health-range rule above, where an empty bucket is absent, and deliberately:
  "no steps recorded" is ignorance, "no attacks" is knowledge.
- **`MedicationOveruseEngine` needed no schema change**, and that is the whole
  reason it exists at this cost: ICHD-3 counts *days of intake*, which a
  medication name plus a start time already gives. Its numbers, the warning
  copy and why it is free are in `lib/features/medications/CLAUDE.md`.

## The verdict, and the chart under it

`PressureCard` now opens with `TriggerVerdictBody` and closes the correlation
section with `PressureHistoryBody`: the answer first, then the working.

- **`TriggerVerdictEngine` is allowed to say no**, and that is the whole
  reason it exists. Only a subset of sufferers are weather-sensitive and the
  published evidence on barometric pressure is suggestive rather than
  consistent, so an app that only ever confirms the reason it was installed
  is a horoscope.
- **Saying no is not the same as not knowing.** `weatherRuledOut` fires only
  when the pressure correlation is settled AND its baseline is reliable;
  every other state is `TriggerVerdictPending`, which says so. Getting this
  backwards would tell a user with four logs that weather is not their
  trigger.
- **Pressure needs the baseline, never the share alone.** "60% of your
  attacks fell during drops" is high for anyone in a stormy climate, so a
  verdict built on it would confirm the weather for half the people who ask.
- **`effect` is the gap as a share of the larger group** — a rough common
  footing so a rate, a duration and a step count can be ordered against each
  other. It is not a statistic and must never be printed as one.
- **Exertion is not ranked.** A self-report with no rest-day baseline has no
  second group to be measured against.
- **The verdict watches both health providers**, so opening the pressure tab
  can fire the HealthKit reads the tabbed screen otherwise defers. Both gate
  themselves on the Apple Health switch, so a user who never connected it
  issues no read at all — but this is a real departure from "each tab waits
  only on what it draws" above, and it was made knowingly.
- **`PressureHistoryBody` leaves a gap where a day has no reading** — never an
  interpolation, never a zero. A drawn point is a claim that a measurement
  happened. Attacks stranded on those days are counted and stated under the
  chart, because a user tallying dots against their own memory deserves to
  know why the two disagree.
- **Dots only on attack days**, coloured by that day's worst intensity. A dot
  on every point is a dotted line.

## The forecast reaches a week

`PressureForecast.forecastDays` is 7 and `contextHours` is 12; the data source
reads both rather than the bare `48` and `12` it used to carry.

- **It costs nothing.** WeatherKit returns the hourly series in ONE request
  whatever window is asked for, and `getWeather` already clamped
  `hoursForward` at 240 and already passed `hourlyStart`/`hourlyEnd`. There
  was no backend change and nothing to deploy.
- **The axis moved from clock times to weekdays.** Across a week the axis fits
  about six labels, and "14:00" six times says nothing about which day the
  drop lands on. The tooltip still names the hour, which is where a clock
  time earns its place.
- Every string that said "48h" says a week now, in all seven ARB files —
  including the paywall's, which was selling the old number.

