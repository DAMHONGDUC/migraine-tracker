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
  paywall sheet via `NavigationUtils.toPaywall`, signed in or not; the Settings
  premium row is the only other way in. Never `pushNamed(AppRoutes.paywall…)` at
  a call site, and **never put a login screen in front of a paywall the user has
  not been shown** — the pitch comes first.
- **Nothing on it waits on an account.** The plans, the CTA and Restore are the
  same signed out as signed in, because premium unlocks the app's own features
  rather than account-based content — App Store 5.1.1(v), and submission
  1.0(20) was rejected for gating it. Under the CTA, and only signed out, one
  text link offers sign-in for what it is actually worth ("use Premium on your
  other devices"); it is an extra, never a step. The purchase lives on
  RevenueCat's anonymous id until then, and `logIn` carries it onto the account.
- **Buy and Restore share one busy flag, and both controls go dead while
  either runs.** A store call takes seconds with nothing on screen to show for
  it, so an impatient second tap is the normal case, not the edge one. Two
  restores landing together each called `context.pop()`, and the second pop took
  the screen *under* the paywall with it — the user saw a blank screen and had
  to kill the app, having in fact been granted the entitlement. Never give a
  store call a control that stays tappable while it is in flight. The CTA
  carries `SdButtonV2.loading` for the wait itself — the spinner is the only
  thing on screen saying the tap landed, which is what stopped the second tap
  from being the reasonable thing to do.
- **The sheet is a flat opaque panel on `AppColors.surfaceModal`** (owner's
  call). It used to be the app's one frosted Liquid Glass surface, on the card
  colour: the pitch, the plans and the CTA are all reading matter, and the
  screen moving behind them competed with the one sheet that has to be read.
  The modal colour is a step *darker* than `surface`, which is what lets the
  cards it holds — the benefits, the plans — read as cards rather than as more
  sheet. The close button carries no surface of its own.
- **A plan row is an `SdCardV2`, and selection is the card's own fill and
  edge**: `fillColor` at alpha 0.14 inside `borderColor`, both the accent.
  There is no radio glyph — the tint and the edge already say which one is
  chosen, and the circle said it a third time. Never reach for a 2px border to
  make it louder; `SdCardV2.borderWidth` is a hairline on purpose.
- **The pitch is one framed card, centred in the space above the plans**
  (owner's call). The six benefits sit in an `SdCardV2` on
  `SdCardSurfaceV2.elevated` — a step up from the panel, so what is being
  sold reads as one block rather than loose rows. The headline and that card are
  centred together in what is left over the plans. **The hero storm icon is
  gone**: at `r64` it was the largest thing on the sheet and said nothing the
  headline does not. **The pitch scrolls and the plans and CTA stay pinned** —
  `Expanded` + `SingleChildScrollView` around the headline and the benefits
  card, so a long locale or large text outgrows it without clipping. This file
  described that as `SliverFillRemaining`/`hasScrollBody: false` while the code
  held a plain `Column` that could not scroll at all, and the sheet overflowed
  by 49px at 393x852 — an iPhone 15, not an edge case. `screen_overflow_test.dart`
  is what would have caught it; it now covers this screen.

## The subscription screen

**The Settings row and the screen behind it are called "Subscriptions", not
"Premium"** (owner's call). The screen is `SubscriptionScreen`, under
`presentation/screens/subscription_screen/`. Its route is still
`AppRoutes.premium` at `/premium`, and `PremiumSettingsTile` still opens it —
a path is an identity, and renaming one to match a label is churn the user
never sees. Premium is the tier; the row is about the thing the
user bought and can cancel, which is what sends them to Settings in the first
place. The ARB keys keep their `premium*` names — the whole namespace is
`premium*`, and renaming two of them leaves the set less consistent, not more.

- **The manage button opens the store's own page and does nothing else.**
  `PurchaseRepository.managementUrl` hands back `CustomerInfo.managementURL`,
  and the screen opens it through `linkLauncherProvider`, the same way the
  paywall's legal links go out. Cancelling, refunds and plan changes are
  Apple's; an in-app control that acted otherwise would be lying about what it
  can do.
- **No URL means no button, and the note stays.** Loading, failure and "the
  store has nothing to manage" are deliberately one branch. An account premium
  by the allow-list has no purchase behind it, so its button would open nothing
  — and the note under it already says where to go.
- **It does not make a TestFlight cancel testable.** Apple's subscriptions page
  does not carry TestFlight purchases; only StoreKit's own
  `showManageSubscriptions` sheet does, and `purchases_flutter` 10 does not
  expose it — it offers `managementURL` and nothing more. Cancelling is
  testable with a Sandbox Apple Account on a directly installed build, never
  from TestFlight.

## The owner's premium account

**An address the owner puts in `app_config` is premium in every flavour**
(owner's rule). For the App Review account and the owner's device: a reviewer
has to reach every gated screen, and a build cannot hand them a real
subscription. `hasPremiumProvider` reads `hasGrantedPremiumProvider` ahead of
everything else.

It was `PREMIUM_EMAIL`, a `--dart-define` in `env/<flavor>.json`, and moved to
Firestore so that granting a reviewer premium no longer means a new binary
through review. The full shape, the rules that keep the list unreadable, and
what the cron does with it: `lib/features/app_config/CLAUDE.md`.

- **It is not the client-side premium flag this repo forbids.** That rule is
  about state the running app can *write*. `app_config` is `allow write: if
  false` for every client, and is matched against an address only Google or
  Apple sign-in can put on the session — so an anonymous session never matches
  and nothing on device can change the answer.
- **No grant is the normal state**, and an anonymous session cannot take the
  branch at all: the provider answers `none` without issuing a read, which is
  why no widget test had to learn about it.
- **Unlike `DevPremiumOverride`, it is deliberately live in prod** — a dev-only
  grant would be useless to the reviewer it exists for.

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
- **The sleep and step readings are the second chart exemption** (owner's call).
  The first card of each Insights tab shows what HealthKit actually handed over —
  last night / today, the average, a bar of the window — and is free. It *is* the
  answer to "did connecting work", so locking it would leave a user who just
  flipped the switch looking at nothing. While the source is disconnected the
  chart is absent and the switch is what stands there. The analysis card under it
  stays premium. (`SleepSummaryCard` / `StepSummaryCard` were the shells for this
  on the detail screens; both screens and both shells are gone.)
- **A gate must never sit between a user and a free surface — including the row
  that leads to one.** `SleepSettingsTile` used to wrap itself in
  `PremiumTileGate`, reasoning that the sleep *insight* is premium. But the tab
  behind that row also holds the Apple Health switch and the free reading, so the
  gate locked a door onto a room the user owned. It
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
