# Premium rules

The authority on what Premium costs, what it unlocks and what the free plan
holds. `CLAUDE.md` points here rather than restating any of it, so there is one
place to change when the offer changes.

Last updated: 2026-08-26.

## Prices

| Product | Type | Price |
|---|---|---|
| Premium Monthly | Auto-renewable subscription | $4.99/mo |
| Premium Yearly | Auto-renewable subscription (7-day free trial) | $29.99/yr |
| Premium Lifetime | Non-consumable | $44.99 |

Yearly is a 50% saving against monthly ($59.88/yr), which is the framing the
paywall and the store listing use.

**Prices are never formatted in Dart.** `PremiumOffer.priceLabel` is the store's
own string: currency, position and decimal separator belong to the customer's
storefront. The numbers above exist for App Store Connect, the RevenueCat
dashboard and marketing copy — the app never reads them.

**Entitlement state comes from RevenueCat and nothing else.** No local premium
repository, no client-writable premium flag.

**And no account.** Buying, restoring and every unlocked surface work signed
out; `hasPremiumProvider` reads the entitlement alone. It used to also require
a signed-in user and submission 1.0(20) was rejected for it (App Store
5.1.1(v)): premium here unlocks the app's own features, which is not
account-based content, so registration cannot be its price. Signing in is
offered on the paywall for what it actually buys — the same subscription on a
second device — and nothing is withheld from whoever declines.

## Free record limits

`lib/core/constants/premium_limit_constant.dart` is what the code reads.

| Limit | Value | Constant |
|---|---|---|
| Attacks logged | 40 | `PremiumLimitConstant.attacks` |
| Medications | 5 | `PremiumLimitConstant.medications` |
| Reminders (across every medication) | 2 | `PremiumLimitConstant.reminders` |
| Countdown starts at | 5 left | `PremiumLimitConstant.attacksWarnAt` |

### Why these numbers

**40 attacks.** `CorrelationEngine.minAttacks` is 15, so a free user sees nothing
from the correlation card until then — and a wall anywhere near 15 lands at the
exact moment the product first proved itself, which reads as bait. 40 is ~2.5×
that: every free user reaches a settled correlation figure, lives with it for
months, and meets the wall with a history worth protecting. At episodic rates
(5–8/month) that is 5–8 months of free use; a chronic user (15/month, the segment
most likely to pay) arrives in under three.

**5 medications.** The ordinary regimen is two acute, a preventive, an
anti-nausea and a supplement. A limit that blocks the typical user in their first
week reads as broken rather than tiered. Five only bites on someone cycling
through many drugs — itself a complex case that wants the doctor report.

**2 reminders.** A preventive taken morning and evening, or one preventive plus a
supplement, is the ordinary regimen, so a limit of 1 blocks the typical user on
day one. Reminders are also what brings someone back daily, which is what
produces the 15 attacks the correlation card needs: capping them hard taxes the
behaviour that feeds the best pitch.

### How a limit behaves

- **Only the add path asks.** A free user who already holds more — from before a
  limit existed, or pulled down by a sync from a device that had premium — keeps
  every record, and nothing is hidden or deleted. Taking back someone's own
  medical history is not a paywall, it is data loss.
- **The limit is named before the paywall opens.** Every record limit goes
  through `NavigationUtils.toPaywallFromLimit`, which shows `RecordLimitDialog`
  first and opens the paywall only if the user picks Unlock. The buttons that
  raise these say "Add medication", "Add reminder", or they are the log button —
  a purchase screen straight out of one reads as a bug rather than an offer. A
  gate whose surface already announces itself as premium (a locked card, a badged
  row) still goes straight to the paywall.
- **The attack wall is never a surprise.** It lands on the log button, which is
  tapped mid-attack, so `AttackLimitBanner` counts down the last `attacksWarnAt`
  logs on the dashboard, where the user is calm.
- **How much is left is always visible, not only near the end.**
  `FreeLimitProgress` (`core/widgets/`) states it as a sentence plus a bar, from
  an `attacksUsedProvider` / `medicationsUsedProvider` that returns null while
  premium — which is what hides the whole block for a paying user. Three surfaces
  show one: History (logs, under the filter row), the medications tab
  (medications, above the first card) and a medication's detail screen
  (medications again, in the pinned footer beside the add button, from the same
  provider so the two cannot disagree). Tapping it opens the paywall directly —
  the surface has already named the limit, which is the only job
  `RecordLimitDialog` does elsewhere.
- **The limits are lifetime totals, not a monthly allowance.** There is no reset.
  A cap that refilled monthly would make 40 logs a rate limit on the one action
  the app exists for, and 40 was chosen as a *lifetime* number against
  `CorrelationEngine.minAttacks`.
- **The medication limit applies inside the log flow too**, by the owner's call —
  the one gate that may appear there (hard rule 5). It never blocks the log
  itself: "No medication" and every medication already on file stay reachable, so
  the three taps still complete.
- **The reminder gate sits before the OS notification prompt**, so iOS is never
  asked on behalf of a reminder that will not be created.

## What Premium unlocks

**Free forever**, up to the limits above:

- Logging attacks (3-tap flow, fully offline), and the weather snapshot attached
  to each one.
- The severity donut wherever it appears — the dashboard preview and History's
  copy draw the user's real counts.
- The sleep and step readings themselves — the top half of `SleepCard` and
  `ActivityCard`, including the D / W / M / 6M range selector. They are the
  answer to "did connecting Apple Health work", so locking them would leave a
  user who just flipped the switch looking at nothing.
- **The weather in full, minus pressure**: `CurrentWeatherCard` gives every user
  the sky, the temperature and what it feels like, then humidity, wind, UV and
  visibility. It draws no pressure at all, so there is nothing on it to gate.
  Insights' pressure tab still opens for everyone, but what it shows there is
  the pitch.
- Physical exertion self-report — the answer is still asked for and stored; only
  the correlation drawn from it is premium.
- **The medication-overuse warning** (`MedicationOveruseBanner`). Owner's call,
  2026-08-26. The second thing in this app that can never be sold, and for the
  same shape of reason as the wipe below it: every other analysis is something
  the user *gains* by paying, and this one is a harm they avoid by being told.
  Selling it would mean a paying user is warned that their acute medication is
  starting to cause attacks and a free user is not. Rules and numbers:
  `lib/features/medications/CLAUDE.md`.
- **Migraine days this month** — `MonthDaysCard` on the dashboard, its
  month-on-month change included. Owner's call, 2026-08-26. It is a count of
  the user's own logs at the same altitude as the week count and the severity
  donut beside it, and those are free. The *report* it feeds is not: the PDF
  row stays behind the export screen with everything else there.
- **How well each medication works** — the relief figure on the medications
  list and the fuller reading on a medication's own screen. Owner's call,
  2026-08-26. It is not a chart, so the blanket chart rule below does not
  reach it, and the question "is this drug working" is the one a free user
  most needs answered before they trust the app with the rest.
- The GDPR wipe. The one half of hard rule 8 that can never be sold: deleting
  your own records is a right, not a feature.
- The notification list, and medication reminders up to the limit.

**Premium**:

- **Everything pressure, EXCEPT the plain reading in the weather detail sheet.**
  The owner asked for pressure and its 24-hour change in that sheet, and they are
  not gated there. What stays premium is everything that interprets them: the 48h
  forecast chart (`PressureForecastBody`, which gates itself so a free user
  issues no WeatherKit call for it), the correlation, and the drop alert — the
  switch and the threshold both, on the pressure card and at the bottom of
  `WeatherCard`. **A free user is shown neither control**, only a badge, one line
  on what the alert does, and Unlock: they were shown inert first, and a switch
  that will not switch reads as broken rather than as an offer.
  This is the line the free tier is drawn on now — weather is free, pressure is
  the product. It has flipped twice; see `docs/rules/DECISIONS.md` before
  flipping it again.
- **The analysis half of `ActivityCard` and `SleepCard`** — the exertion, step
  and sleep correlations, together under one "Analysis" heading per card.
- Every chart except the severity donut and the sleep and step readings. Any
  chart added later is covered unless the owner says otherwise.
- **The whole export screen** — JSON, CSV, the PDF doctor report, the export
  history and its preview alike (owner's call, 2026-08-19). It was free forever
  on data-portability grounds and is not any more; what replaces that promise is
  the support route in the privacy policy, which answers an export request by
  email at no cost. Both doors — the dashboard's explore card and the Settings
  row — wear a `PremiumBadge` and go through `NavigationUtils.toExport`, which is
  the one gate: **a surface that announces itself goes straight to the paywall**,
  so there is no `RecordLimitDialog` in front of it.
  - **The cost, stated rather than discovered**: a subscriber who exports and
    then lapses cannot reach their own past export files from the app any more,
    because the entrance is gated rather than the create button. The files stay on
    disk and the free wipe still deletes them. Revisit here first if that lands as
    a support ticket.
- Unlimited attacks, medications and reminders.

### The exertion correlation moved to premium

It was free, on the grounds that exertion is the one insight the user supplies by
hand. The owner's Insights spec put it in the premium analysis half of
`ActivityCard` alongside the step correlation, so it is premium now.

What did **not** change: the exertion step in the log flow is still free, still
one tap, and still arrives on `ExertionLevel.none` so it can never block (hard
rule 5). The app still asks the question of everyone, because the data has to
exist before the paywall has anything to sell.

## Two rules that outrank the pitch

- **Buying premium unlocks it now.** A data threshold grades the answer, it never
  withholds it: no premium surface may sit empty behind a sample-size minimum.
  Every insight engine analyses from the first data point and reports how far
  along the sample is.
- **A free user's widget tree holds no real premium data.** `PremiumGate` and
  `PremiumChartLock` blur `SampleChartData`, never the user's own attacks — a
  cover over real numbers is one screenshot away from leaking them.
