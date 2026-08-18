# Premium rules

The authority on what Premium costs, what it unlocks, and what the free plan
holds. `CLAUDE.md` points here rather than restating any of it, so there is
one place to change when the offer changes.

Last updated: 2026-08-12.

## Prices

| Product | Type | Price |
|---|---|---|
| Premium Monthly | Auto-renewable subscription | $4.99/mo |
| Premium Yearly | Auto-renewable subscription (7-day free trial) | $29.99/yr |
| Premium Lifetime | Non-consumable | $44.99 |

Yearly is a 50% saving against monthly ($59.88/yr), which is the framing the
paywall and the store listing use.

**Prices are never formatted in Dart.** `PremiumOffer.priceLabel` is the
store's own string, because the currency, its position and the decimal
separator belong to the customer's storefront. The numbers above exist for
App Store Connect, the RevenueCat dashboard and marketing copy — the app
never reads them.

Entitlement state comes from RevenueCat and nothing else. There is no local
premium repository, and no client-writable premium flag.

## Free record limits

`lib/core/constants/premium_limit_constant.dart` is what the code reads.

| Limit | Value | Constant |
|---|---|---|
| Attacks logged | 40 | `PremiumLimitConstant.attacks` |
| Medications | 5 | `PremiumLimitConstant.medications` |
| Reminders (across every medication) | 2 | `PremiumLimitConstant.reminders` |
| Countdown starts at | 5 left | `PremiumLimitConstant.attacksWarnAt` |

### Why these numbers

**40 attacks.** `CorrelationEngine.minAttacks` is 15 — a free user sees
nothing from the correlation card until then. A wall anywhere near 15 lands
at the exact moment the product first proved itself, which reads as bait. 40
is ~2.5× that: every free user reaches a settled correlation figure, lives
with it for months, and meets the wall with a history worth protecting. At
typical episodic rates (5–8 attacks/month) that is 5–8 months of free use; a
chronic user (15/month, the segment most likely to pay) arrives in under
three.

**5 medications.** The ordinary regimen is two acute, a preventive, an
anti-nausea and a supplement. A limit that blocks the typical user in their
first week reads as broken rather than tiered — the same trap the reminder
limit already documents. Five only bites on someone cycling through many
drugs, which is itself a complex case that wants the doctor report.

**2 reminders.** A preventive taken morning and evening — or one preventive
plus a supplement — is the ordinary regimen, so a limit of 1 blocks the
typical user on day one. Reminders are also what brings someone back daily,
which is what produces the 15 attacks the correlation card needs; capping
them hard taxes the behaviour that feeds the best pitch.

### How a limit behaves

- **Only the add path asks.** A free user who already holds more — from before
  a limit existed, or pulled down by a sync from a device that had premium —
  keeps every record, and nothing is hidden or deleted. Taking back someone's
  own medical history is not a paywall, it is data loss.
- **The limit is named before the paywall opens.** Every record limit goes
  through `NavigationUtils.toPaywallFromLimit`, which shows
  `RecordLimitDialog` first and opens the paywall only if the user picks
  Unlock. The buttons that raise these say "Add medication", "Add reminder",
  or they are the log button — a purchase screen straight out of one reads as
  a bug rather than an offer. A gate whose surface already announces itself as
  premium (a locked card, a badged row) still goes straight to the paywall.
- **The attack wall is never a surprise.** It lands on the log button, which
  is tapped mid-attack. `AttackLimitBanner` counts down the last
  `attacksWarnAt` logs on the dashboard, where the user is calm.
- **How much is left is always visible, not only near the end.**
  `FreeLimitProgress` (`core/widgets/`) states it as a sentence plus a bar,
  from an `attacksUsedProvider` / `medicationsUsedProvider` that returns null
  while premium — which is what hides the whole block for a paying user.
  Three surfaces show one: History (logs, under the filter row), the
  medications tab (medications, above the first card), and a medication's
  detail screen (medications again, in the pinned footer beside the add
  button, from the same provider so the two can never disagree).
  Tapping it opens the paywall directly — the surface has already named the
  limit, which is the only job `RecordLimitDialog` does elsewhere.
- **The limits are lifetime totals, not a monthly allowance.** There is no
  reset. A cap that refilled every month would make 40 logs a rate limit on
  the one action the app exists for, and 40 was chosen as a *lifetime* number
  against `CorrelationEngine.minAttacks` — the reasoning above only holds if
  it is never topped up.
- **The medication limit applies inside the log flow too**, by the owner's
  call — the one gate that may appear there (hard rule 5). It never blocks the
  log itself: "No medication" and every medication already on file stay
  reachable, so the three taps still complete.
- **The reminder gate sits before the OS notification prompt**, so iOS is
  never asked on behalf of a reminder that will not be created.

## What Premium unlocks

Free forever, up to the limits above:

- Logging attacks (3-tap flow, works fully offline), and the weather snapshot
  attached to each one
- The severity donut, wherever it appears — the dashboard preview and
  History's copy draw the user's real counts
- The sleep and step readings themselves — the top half of `SleepCard` and
  `ActivityCard`, including the D / W / M / 6M range selector over each. They
  are the answer to "did connecting Apple Health work", so locking them would
  leave a user who just flipped the switch looking at nothing
- **The weather, in full, minus pressure**: the dashboard's
  `CurrentWeatherCard` gives every user the conditions they are standing in —
  the sky, the temperature and what it feels like, then humidity, wind, UV and
  visibility. It draws no pressure at all, so there is nothing on it to gate.
  `/pressure` still opens for everyone, but what it shows there is the pitch
- Physical exertion self-report (the answer is still asked for and stored;
  only the correlation drawn from it is premium — see below)
- Export to JSON/CSV, the export history, preview, and the GDPR wipe
- The notification list, and medication reminders up to the limit

Premium:

- **Everything pressure.** The 48h forecast chart (`PressureForecastBody`,
  which gates itself so a free user issues no WeatherKit call for it), the
  correlation, and the drop alert — the switch and the threshold both, on
  `/pressure` and on the bottom of `WeatherCard`. **A free user is shown
  neither control**, only a badge, one line on what the alert does, and
  Unlock: they were shown inert first, and a switch that will not switch
  reads as broken rather than as an offer.
  This is the line the free tier is drawn on now — weather is free, pressure
  is the product. It has flipped twice; see CLAUDE.md before flipping it
  again
- **The analysis half of `ActivityCard` and `SleepCard`** — the exertion
  correlation, the step correlation and the sleep correlation, together under
  one "Analysis" heading per card
- Every chart except the severity donut and the sleep and step readings — and any chart added later is covered unless the owner says
  otherwise
- The PDF doctor report
- Unlimited attacks, medications and reminders

### The exertion correlation moved to premium

It was free, on the grounds that exertion is the one insight the user supplies
by hand. The owner's Insights spec put it in the premium analysis half of
`ActivityCard` alongside the step correlation, so it is premium now.

What did **not** change: the exertion step in the log flow, which is still
free, still one tap, and still arrives on `ExertionLevel.none` so it can never
block (hard rule 5). Only the correlation drawn from the answers is gated —
the app still asks the question of everyone, because the data has to exist
before the paywall has anything to sell.

## Two rules that outrank the pitch

- **Buying premium unlocks it now.** A data threshold grades the answer, it
  never withholds it: no premium surface may sit empty behind a sample-size
  minimum. Every insight engine analyses from the first data point and reports
  how far along the sample is.
- **A free user's widget tree holds no real premium data.** `PremiumGate` and
  `PremiumChartLock` blur `SampleChartData`, never the user's own attacks — a
  cover over real numbers is one screenshot away from leaking them.
