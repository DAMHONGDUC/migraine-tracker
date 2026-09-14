# Improvement plan

From a 30-day simulated run of the app as a chronic sufferer — 11 attacks a
month, Hanoi, free plan, signed out. Ordered by what makes the app *wrong*
first, what makes it *lose the user* second.

Every item is one before/after table of behaviour. `docs/REMAINING_WORK.md`
stays the release checklist; this file is product work.

| Status | Meaning |
|---|---|
| **Shipped** | Committed, analyzer clean, tests green |
| **Waiting** | Written, in the working tree, not committed — needs a yes |
| **Planned** | Not started |
| **Blocked / Not done** | Cannot be done here, or needs the owner — the reason is in the row |

## Decisions the owner has to make

### D1 — Save now, mid-flow · Shipped

| What | Before | After |
|---|---|---|
| Ways to save an attack | One: answer all four steps | Two: all four steps, or Save now from any step after the first |
| A 9/10 attack costs | 7 taps, or the record is lost | 2 taps — intensity, Save now |
| What an early save records | — | Intensity, plus whatever was answered; the rest editable on the detail screen |
| Location left unanswered | Impossible — the step waits for a pick | Stored empty, which History already filters as "not recorded" |
| Hard rule 5 | "Three taps, then one skippable step" | Same four steps; Save now is an exit, not a fifth step — the rule text has to say so |

**Why it matters**: the person the app is for is, at that moment, trying to put
the phone down.

### D2 — Where a trigger is analysed · Shipped

| What | Before | After |
|---|---|---|
| How a trigger is entered | Free text, comma-separated | Chips over the existing `DailyFactor` vocabulary, free text kept beside them |
| What the app can do with it | Show it back, filter on the exact words | Count it, and — through the day's factors — grade it |
| The denominator | None: an attack knows its triggers, a quiet day knows nothing | The check-in's factor list, which `FactorMapEngine` already compares both ways |
| Ticking a trigger | Touches the attack only | Offers one tap to tick the same factor on today's check-in |
| New factors beyond the 8 that exist | — | Four added: bright light, loud noise, neck tension, missed preventive |

**Why it matters**: "6 of 11 attacks followed wine" is not evidence until the
app also knows how many quiet days followed wine.

### D3 — The 40-attack lifetime cap · Shipped

| What | Before | After |
|---|---|---|
| Free attacks | 40, for life | Unlimited |
| What the free plan buys | Everything, until the 41st attack | Everything, and History reads the last 90 days |
| A chronic user (15/month) | Cannot log from month 2.7 | Never blocked |
| The dashboard banner | Counts down the last 5 logs | Says which date the readable history starts at |
| What is sold | The right to record | Long history, correlation, forecast, doctor report |

**Why it matters**: the record belongs to the user in every other sentence the
app says; a wall in front of it contradicts that, and the user who hits it
leaves rather than pays.

## Wave 1 — correctness

### 1.1 The start time is editable · Shipped

| What | Before | After |
|---|---|---|
| An attack's start | Whatever moment Save happened | Editable from the detail screen |
| A 3am attack logged at 9am | Recorded at 09:00 | Recorded at 03:00 |
| Yesterday's attack | Cannot be recorded at all | Recorded at yesterday's hour |
| How the time is entered | — | Presets: just now, 30m, 1h … 48h ago. No date picker |
| A preset landing after the recorded end | — | Shown, and refused |

### 1.2 The weather follows the start time · Shipped

| What | Before | After |
|---|---|---|
| The snapshot after an edit | Kept — a 09:00 reading on a 03:00 attack | Dropped in the same transaction as the edit |
| Re-fetch | — | The reading for the new instant, within the 7-day backfill window |
| A failed re-fetch | — | The attack rejoins the backfill queue, with no reading rather than a wrong one |

**Why it matters**: pressure at the wrong hour is the one error that corrupts
the correlation the app sells.

### 1.4 Logging an attack that already passed · Shipped

| What | Before | After |
|---|---|---|
| Recording an earlier attack | Log it now, then correct it on the detail screen | Say when, on the first step, before answering anything |
| Where the answer is shown | Nowhere | On the button that set it — "Started Sep 13, 03:00" |
| Default | Now | Now, unchanged |

### 1.5 A dead session heals itself · Shipped

| What | Before | After |
|---|---|---|
| Proof of a session | A cached user object | A token the server still honours |
| Server-side user deleted | Client reports signed in; every callable answers "unauthenticated" | Signed out and signed in again, anonymously |
| The weather feature in that state | Dead until the app is reinstalled | Works on the next launch |
| What the user sees | "Weather unavailable", no cause, no action | Weather |

### 1.6 The weather card's dead end · Shipped

| What | Before | After |
|---|---|---|
| A failed weather read | One line, and a silent auto-retry timer | The same line plus a retry control |
| A failure that is not transient | Waits forever | One tap re-runs it |

### 1.7 Chips for symptoms and triggers · Shipped

| What | Before | After |
|---|---|---|
| Entry | Two free-text fields | Chips, plus a free-text field for anything else |
| Typing during an attack | Required to record anything | Optional |
| Storage | A list of whatever was typed | The same list; chips write canonical ids, so no schema change |
| Filtering in History | Matches the exact words the user typed | Matches ids, and still offers the user's own words |

### 1.8 A trigger feeds the day's factors · Shipped

| What | Before | After |
|---|---|---|
| Ticking "alcohol" on an attack | Recorded on the attack alone | Offers to tick the same factor on today's check-in |
| The factor map's sample | Grows only on days the user opens the check-in | Grows every time an attack is logged |

## Wave 2 — the 30-day cliff

### 2.1 + 2.2 An evening check-in reminder · Shipped

| What | Before | After |
|---|---|---|
| What reminds the user to check in | Nothing — reminders exist for medication only | A daily local notification, 20:30 by default, switchable |
| A day already answered | — | That day's reminder is cancelled, not fired |
| The free reminder budget (2) | Medication reminders only | Unchanged — the check-in reminder does not spend it |
| Where the scheduler lives | `medications/data/`, unreachable from `daily_log` | `notifications/`, shared by both |

**Why it matters**: the factor map needs 28 answered days, and today nothing
asks for them.

### 2.3 Answering a missed check-in · Shipped

| What | Before | After |
|---|---|---|
| Which day the screen writes | Always today | Today, or a named day up to 3 days back |
| A day spent lying down | A permanent hole in the control group | Answerable the next morning |
| Older than 3 days | — | Still closed: that answer would be invention, not memory |

### 2.4 Auto-advance on the single-choice steps · Shipped

| What | Before | After |
|---|---|---|
| Medication step | Pick, then Next | The pick advances |
| Exertion step | Pick, then Next | The pick advances |
| Location step | Pick, then Next | Unchanged — it takes several areas |
| A fully answered log | 7 taps | 5 taps |
| Existing tests | Encode the old sequence | Rewritten: `logAttack` and the flow walk drop the medication Next |

### 2.5 Alerts state their preconditions · Shipped

| What | Before | After |
|---|---|---|
| What the alert pitch says | What the alert does | What it does, and that it needs Premium and an account |
| A Premium user with no account | Flips the switch, then meets an error | Is taken to sign-in |
| When the user learns about the account | After paying, at the switch | Before tapping |

### 2.6 The free window replaces the cap · Shipped

See D3. One thing is worth writing down: **the window is applied in the widget
layer, never in a provider.**

| What | Before | After |
|---|---|---|
| Where a free user's history is trimmed | — | `HistoryScreen`, through `AttackWindow.within` |
| Providers that know about the entitlement | `canLogAttackProvider`, `attacksLeftProvider`, `attacksUsedProvider` | `freeHistoryStartProvider` and `hasHiddenHistoryProvider` only, both sync |
| What the analyses read | Every attack | Every attack, unchanged — each paid one is already behind `PremiumGate` |

**Why**: the premium flag arrives asynchronously, so a provider that filters by
it is recomputed while the first frames are still laying out — Riverpod reports
that as "setState called during build". Three shapes were tried and all three
threw it; `docs/PREMIUM_RULES.md` records the rule.

## Wave 3 — polish

### 3.1 One name · Shipped

| What | Before | After |
|---|---|---|
| The name in the permission dialog | "Migraine Tracker" | "BaroEase" |
| The name everywhere else | "BaroEase" | Unchanged |

### 3.2 The two empty steps · Partly shipped

| What | Before | After |
|---|---|---|
| The exertion step | Already centred | Unchanged — the 30-day run misread it |
| The primary action | In the app bar alone | Save now sits under the content, in the thumb zone, and the two single-choice steps need no Next at all |
| Centring the medication grid | Top-aligned | **Reverted.** `Center` inside its scroll view broke the grid-capacity test's no-scroll guarantee and the log flow's overflow test; the grid's fixed cells and the step's own insets are what that test pins |

### 3.3 Waiting analyses say how far along they are · Not done, on purpose

| What | Before | After |
|---|---|---|
| A PREMIUM user's waiting card | Already says how much is missing — `InsightProgressBody` on sleep, steps and exertion, `CorrelationBodyProgress` on pressure, two counters on the factor map | Unchanged; the 30-day run reported this wrongly |
| A FREE user's locked card | One pitch, no numbers | Unchanged — showing progress inside a locked card contradicts "locked, a tab collapses to one card with one pitch" (`lib/features/insights/CLAUDE.md`) |

**Needs the owner**, not a patch: it is a change to what a locked surface may
say, and that rule was set deliberately.

### 3.4 The device checklist · Blocked

| What | Before | After |
|---|---|---|
| HealthKit, push, the widget, Live Activity, both Siri phrases | Never verified on hardware | Still never — it needs an iPhone, per `docs/REMAINING_WORK.md` item 16 |

## Rules these changes rewrite

| Rule | Written in | What changes |
|---|---|---|
| Hard rule 5, the 3-tap flow | `lib/features/attacks/CLAUDE.md` | Two steps commit on pick; Save now is an exit, not a step |
| The fixed factor list | `lib/features/daily_log/CLAUDE.md`, `docs/rules/DECISIONS.md` | An attack's triggers and a day's factors share one vocabulary |
| Free limits | `docs/PREMIUM_RULES.md`, `PremiumLimitConstant` | The attack cap becomes a history window |

## Thresholds nothing here moves

| Number | Value | Why it stays |
|---|---:|---|
| `CorrelationEngine.defaultMinAttacks` | 15 | Below it a correlation claims what a thin sample cannot support |
| `defaultMinDaysPerSide` | 5 | One day's weather swings the rate 20 points |
| `FactorMapEngine.defaultRequiredDays` | 28 | A month is the shortest honest day-level window |
| Alert dedupe | 3 a day, 8h apart | This plan gives more reasons to open the app, never more pushes |
