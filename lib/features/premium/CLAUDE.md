# Premium and the free plan

`docs/PREMIUM_RULES.md` is the authority on the numbers and on what each gate
does. This is how the surfaces behave.

## The free-limit readout

**A free user always knows how much of the plan is left, not only when it is
nearly gone.** `FreeLimitProgress` (`core/widgets/`) is the one widget for it:
the sentence, then the bar, then the counts. History shows the log budget and
the medications tab the medication budget, each from that record's one
`*UsedProvider`, never a second tally.

- **A surface shows the budget it can actually spend.** A medication's detail
  screen used to draw the MEDICATION budget in its footer — a number nothing on
  that screen could move, since it creates reminders. It shows
  `remindersUsedProvider` against `PremiumLimitConstant.reminders` now, at the
  top of the reminder section rather than in the footer, so the limit is read
  where the list it caps begins.
  - **Counted across every medication**, exactly as `canAddReminderProvider`
    gates it. The reminder limit is not per medication, and a per-medication
    screen must not draw it as though it were.
  - **The used figure can exceed the limit**, and that is not a bug: a free user
    who kept reminders from before the limit existed keeps them, so
    `FreeLimitProgress` clamps its bar rather than pretending they are not there.
- **The `*UsedProvider`s return null while premium, and that is what hides the
  block.** One place decides, so a new surface cannot forget and show a paying
  user a limit.
- **It taps straight through to the paywall, with no `RecordLimitDialog`.** That
  dialog names the limit before the pitch; this surface has already named it.
- **It is not `AttackLimitBanner` and does not replace it.** The banner is the
  near-the-end warning on the dashboard that hard rule 5's log button depends on;
  this is the always-on readout in the lists. Both stay.
- **On History it goes UNDER the filter row.** `_FilterRow.scrolledPastExtent`
  measures from offset 0, so anything above the pill makes the collapse fire
  while the pill is still on screen.

## The paywall

- **Two doors, and every gate uses one of them.** A locked surface opens the
  paywall sheet via `NavigationUtils.toPaywall`, signed in or not; the paywall
  itself asks the account question ("Sign in to continue" →
  `NavigationUtils.toLogin`, then back offering the purchase). The Settings
  sign-in row is the only other way in. Never `pushNamed(AppRoutes.paywall…)` at
  a call site, and **never put a login screen in front of a paywall the user has
  not been shown** — the pitch comes first.
- **The pitch is one framed card, centred in the space above the plans**
  (owner's call). The six benefits sit in an `SdCardV2` on
  `SdCardSurfaceV2.elevated` — a step up from the panel's glass, so what is being
  sold reads as one block rather than loose rows. The headline and that card are
  centred together in what is left over the plans. **The hero storm icon is
  gone**: at `r64` it was the largest thing on the sheet and said nothing the
  headline does not. The pitch scrolls (`SliverFillRemaining`,
  `hasScrollBody: false`) so a long locale or large text outgrows it without
  clipping, while the plans and CTA stay pinned.

## What is locked, and how

- **Every chart is premium except the severity donut**, which is free wherever
  it appears: it is the dashboard's preview, so History's copy draws the real
  counts too — locking it there would take back something the user has one tab
  away. The other four in History's deck are covered, and so is any chart added
  later unless the owner says otherwise.
  - The cover is `PremiumChartLock` (`core/widgets/premium_gate.dart`), one per
    card: the chart blurred under a scrim with the unlock button centred,
    tapping through to `NavigationUtils.toPaywall`.
  - **What it blurs is `SampleChartData`, never the user's own attacks.**
    `_Charts` picks each card's source before it builds anything — real for the
    donut, sample for the rest — so `PremiumGate`'s rule survives the visual
    cover: a free user's tree still holds no real premium data. A cover over real numbers is one screenshot, or one
    accessibility dump, away.
  - The sample runs through the SAME calculators as the real deck, so the locked
    preview cannot drift from what premium unlocks. It is `ExcludeSemantics`'d so
    VoiceOver never reads the made-up figures, and the card carries
    `premiumLockedCharts` as its label instead.
- **The sleep and step summary cards are the second chart exemption** (owner's
  call). `SleepSummaryCard` and `StepSummaryCard`
  (`insights/presentation/widgets/`) show what HealthKit actually handed over —
  last night / today, the 7-entry average, a bar of the window — and are free
  wherever they appear. The card *is* the answer to "did connecting work", so
  locking it would leave a user who just flipped the switch looking at nothing.
  They are absent entirely while the source is disconnected. The correlation card
  under each stays premium.
- **A gate must never sit between a user and a free surface — including the row
  that leads to one.** `SleepSettingsTile` used to wrap itself in
  `PremiumTileGate`, reasoning that the sleep *insight* is premium. But the
  screen behind that row also holds the Apple Health switch and the free
  `SleepSummaryCard`, so the gate locked a door onto a room the user owned. It
  cost a rejection: submission 1.0(11) came back under App Store 2.5.1 for not
  identifying HealthKit in the UI, because that locked row led to the app's only
  screen naming Apple Health — and with the paywall returning no offerings
  (2.1(b) on the same review) it could not even be unlocked. **Gate on what the
  destination's free half holds, not on its headline feature.** Settings now
  carries an Apple Health section of its own, which no gate can hide.

## Buying premium unlocks it now

A data threshold **grades** the answer, it never withholds it: no premium
surface may sit empty behind a sample-size minimum. All four insight engines —
pressure, exertion, sleep, steps — analyse from the first data point they can and
report how far along the sample is, via two flags on the result rather than an
early return.

- **`isCountOnly`** means the derived headline is not worth stating yet, so the
  card shows what was actually measured. For a share (pressure, exertion) that is
  the counts ("2/3"), because a percentage off 1–4 attacks can only be
  0/25/33/50/100 and every one reads as a claim; for a two-group comparison
  (sleep, steps) it is the two averages without the gap between them.
- **`isPreliminary`** means the figure still moves, and puts
  `InsightSettlingNote` under it — **one widget and one string for all four
  cards**, deliberately carrying no number, because sleep and steps can be
  unsettled from a thin *side* rather than a small total.
- The `NoVariation` verdict is only reached at a settled sample: "your weather is
  all the same" off three readings is not a finding.
- **`minAttacks` is 15** because the normal approximation behind any confidence
  claim wants ~5 attacks either side of the threshold, which lands at 15 when
  roughly a third of attacks fall during drops. Write that reason down wherever
  the number is copied — it used to be stated in `PLAN.md` and cited from the
  code with no argument anywhere.
- Free users keep the "keep logging" progress to 15 on the premium cards, which
  is the road to the value moment.
- **The only state that still withholds a result is a genuinely empty one** — no
  attack with weather, no attack with an exertion answer, or one whole side of a
  two-group comparison empty, where there is no comparison rather than a thin one.
- **A preliminary figure never reaches the doctor report** —
  `DoctorReportBuilder` matches `isPreliminary: false`, because a PDF is read as
  settled.
