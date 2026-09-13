# Improvement plan

Written 2026-09-14, after a 30-day simulated run of the app as a chronic
sufferer (11 attacks a month, Hanoi, free plan, signed out). Ordered by what
makes the app *wrong* first, what makes it *lose the user* second.

`docs/REMAINING_WORK.md` stays the release checklist; this file is product work.

## Decisions taken

| # | Question | Decision | Why |
|---:|---|---|---|
| 1 | Auto-advance in the log flow (hard rule 5) | Auto-advance the two single-choice steps, and add a persistent **Save now** | 7 taps → 5, and 2 for the worst attack. Location still waits, because it is multi-pick |
| 2 | Where trigger tags are analysed | Chips write `DailyFactor` names into the attack, and offer one tap to tick the same factor on today's check-in | A per-attack trigger has no denominator; a per-day factor has one, and `FactorMapEngine` already grades it |
| 3 | The 40-attack lifetime cap | Logging is never capped. The free plan reads and analyses the last 90 days | Blocking a log blocks a health record the app calls the user's own. The paywall moves to long history, correlation, forecast and the doctor report |

## Wave 1 — correctness (the numbers the app sells)

| # | Change | Files | Done when |
|---:|---|---|---|
| 1.1 | `updateStartedAt` on the repository, revision bumped | `features/attacks/domain/repositories/attack_repository.dart`, `data/repositories/drift_attack_repository.dart` | An edited attack pushes as dirty |
| 1.2 | Re-attach weather at the new instant; drop the snapshot when the new instant is older than the 7-day backfill window | `attacks/domain/services/weather_attach_service.dart` | A snapshot never belongs to an hour the attack did not happen in |
| 1.3 | Preset sheet — "just now / 1h / 2h / 4h / last night / yesterday" — from the attack detail header and the saved screen | `attacks/presentation/widgets/attack_start_sheet.dart` | No date picker anywhere; no new required step |
| 1.4 | Log an attack that already passed, from History | `features/history/presentation/…`, `core/router/navigation_utils.dart` | The flow opens on the start sheet, then runs unchanged |
| 1.5 | Recover a dead session: verify the token, sign in anonymously again, invalidate weather and sync | `core/bootstrap/app_bootstrap.dart`, `features/weather/data/datasources/backend_weather_data_source.dart` | A deleted server-side user heals on the next launch instead of killing weather |
| 1.6 | A retry control on the weather card's unavailable state | `core/widgets/weather/` | The card is never a dead end |
| 1.7 | Trigger chips over the same `DailyFactor` vocabulary, free text kept beside them | `attacks/presentation/widgets/attack_details_sheet.dart` | No schema change: ids go into the existing `triggers` list |
| 1.8 | One tap from an attack's trigger to today's check-in factors | `features/daily_log/…` | The map's denominator grows every time an attack is logged |

## Wave 2 — the 30-day retention cliff

| # | Change | Files | Done when |
|---:|---|---|---|
| 2.1 | Move `NotificationScheduler` out of `medications/` so `daily_log` may use it | `features/notifications/` | No feature imports another feature's `data/` |
| 2.2 | Evening check-in reminder, default 20:30, cancelled for a day already answered | `features/daily_log/`, `features/settings/` | It does not spend the free reminder budget, which is for medication |
| 2.3 | Answer a missed check-in, up to 3 days back | `features/daily_log/presentation/…` | The screen takes a `dayKey`; older than 3 days stays closed |
| 2.4 | Auto-advance + Save now (decision 1) | `attacks/presentation/controllers/log_controller.dart` | `log_flow_step` funnel is comparable before/after |
| 2.5 | Alerts state their two preconditions before the tap | `insights/presentation/…`, `core/widgets/sections/` | Nobody meets `accountRequired` as a surprise |
| 2.6 | Free window replaces the attack cap (decision 3) | `core/constants/premium_limit_constant.dart`, `attacks/providers.dart`, `core/router/navigation_utils.dart` | `canLogAttackProvider` is always true |

## Wave 3 — polish

| # | Change | Files |
|---:|---|---|
| 3.1 | `CFBundleDisplayName` → BaroEase | `ios/Runner/Info.plist` |
| 3.2 | Medication and exertion steps: content centred, primary action in the thumb zone | `attacks/presentation/widgets/` |
| 3.3 | Every waiting analysis says how much is still missing, like the factor map does | `insights/presentation/…` |
| 3.4 | Run the device checklist — HealthKit, push, widget, Live Activity, Siri | `docs/REMAINING_WORK.md` item 16 |

## Rules this plan changes

| Rule | Where it is written | What has to be rewritten with the code |
|---|---|---|
| Hard rule 5, the 3-tap flow | `lib/features/attacks/CLAUDE.md` | What "three taps" means once two steps commit on pick, and that Save now is not a fifth step |
| The fixed factor list | `lib/features/daily_log/CLAUDE.md`, `docs/rules/DECISIONS.md` | That an attack's triggers and a day's factors share one vocabulary |
| Free limits | `docs/PREMIUM_RULES.md`, `PremiumLimitConstant` | The attack cap becomes a history window; the access matrix row with it |

## Thresholds this plan does not move

| Number | Value | Why it stays |
|---|---:|---|
| `CorrelationEngine.defaultMinAttacks` | 15 | Below it a correlation makes claims a thin sample cannot support |
| `defaultMinDaysPerSide` | 5 | One day's weather swings the rate 20 points below it |
| `FactorMapEngine.defaultRequiredDays` | 28 | A month is the shortest honest window for a day-level comparison |
| Alert dedupe | 3/day, 8h apart | Wave 2 gives the user more reasons to open the app, never more pushes |
