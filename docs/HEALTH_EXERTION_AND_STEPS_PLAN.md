# Physical exertion (self-report) + HealthKit step-count correlation

> **Status: not started.** This is an implementation plan only — no code has
> been written yet. Picked up later; see `PLAN.md` for how these two fit into
> the wider product scope once built.

## Context

Follow-up to the Health feature (`features/health`, sleep-only today). Two
additions, decided as follows:

1. **Physical exertion** — a self-reported field added to the attack log's
   "Add details" step, as a **3-level scale (light/moderate/severe)**, feeding
   a **free** correlation insight (no HealthKit involved at all).
2. **Step count** — a new HealthKit read (`HealthDataType.STEPS`), gated
   behind the **existing single "Apple Health" switch** (one authorization
   sheet covers sleep + steps together), feeding a **premium** correlation
   insight that compares **same-day** step count against attack days (not
   "the night before," which is the sleep engine's join).

Both insights follow patterns already proven in `features/insights`: the
pressure `CorrelationEngine` (simple % of attacks matching a condition — the
model for exertion, since self-report has no "rest day" baseline to compare
against) and the `SleepCorrelationEngine` (attack-day vs rest-day group
average — the model for steps, which does have a continuous background
dataset).

## Part A — Physical exertion (free, self-reported)

**Domain**
- `lib/features/attacks/domain/enums/exertion_level.dart`: `enum ExertionLevel { light, moderate, severe }`, mirrors `head_location.dart`.
- `lib/core/extensions/exertion_level_label.dart`: `label(AppLocalizations l10n)` extension, mirrors `head_location_label.dart`.
- `Attack` entity (`lib/features/attacks/domain/entities/attack.dart`): add `final ExertionLevel? exertionLevel;`, threaded through the constructor next to `notes`. No `copyWith` change needed (only `weather` uses `copyWith` today; this field is written via `updateDetails`, like `notes`).

**Data**
- `lib/features/attacks/data/tables/attack_tables.dart`: add `TextColumn get exertionLevel => textEnum<ExertionLevel>().nullable()();` to `Attacks`.
- `lib/core/db/app_database.dart`: bump `schemaVersion` 4 → 5; add `if (from < 5) await m.addColumn(attacks, attacks.exertionLevel);` to `onUpgrade`, with a one-line comment matching the style of the v3/v4 comments (existing rows get null — nobody reported exertion before this shipped).
- Regenerate migration snapshots: `test/db_migration/generated/schema_v5.dart` + `drift_schemas/drift_schema_v5.json`, via whatever `melos run gen` / `dart run drift_dev schema generate` + `schema dump` step the repo already uses for prior versions (check `tool/gen.sh` for the exact invocation).
- `AttackRepository` interface (`domain/repositories/attack_repository.dart`) + `DriftAttackRepository`: add `required ExertionLevel? exertionLevel` to `updateDetails(...)`; thread it through `_toDomain`/`_toRow` in `drift_attack_repository.dart`, same shape as `notes`.

**Presentation**
- `lib/features/attacks/presentation/widgets/exertion_level_picker.dart` (new, shared widget): a `Row` of 3 tiles, mirrors `location_grid.dart`'s `_LocationTile` visuals exactly (`SdPressableScaleV2` + `AnimatedContainer`, `AppColors.surfaceElevated`/`primary` fill, `AppTextStyle.labelTiny`) but nullable/single-select with **deselect on re-tap** (`onSelected(selected == level ? null : level)`) — this field is optional, so tapping the chosen level again must be able to clear it back to "not answered."
- `attack_details_sheet.dart`: add `initialExertionLevel` param, a `useState<ExertionLevel?>` hook, render `ExertionLevelPicker` (label `detailsExertionLabel` above it) alongside the existing symptoms/triggers/notes fields, pass the value into `updateDetails(...)`.
- `attack_detail_screen_details_section.dart`: extend the `isEmpty` check to include `attack.exertionLevel == null`; add a `_ReadOnlyRow` for it when present, using the new label extension.

**Insights**
- `lib/features/insights/domain/entities/exertion_correlation_result.dart`: sealed result, mirrors `correlation_result.dart` — `ExertionInsufficientData(attacksWithExertion, requiredAttacks)`, `ExertionNoVariation(attacksAnalyzed)`, `ExertionInsight(attacksAnalyzed, lightCount, moderateCount, severeCount)` with a `moderateOrSeverePercent` getter (the headline: "X% of attacks where you logged exertion involved moderate-to-severe activity").
- `lib/features/insights/domain/services/exertion_correlation_engine.dart`: mirrors `correlation_engine.dart`. Pool = `attacks.where((a) => a.exertionLevel != null)` (only attacks where the user actually answered — same idea as `attacksWithWeather`). `defaultMinAttacks = 15`. "No variation" = every attack in the pool has the identical level.
- `providers.dart` (insights): `exertionCorrelationEngineProvider` + `exertionCorrelationResultProvider` — copy `correlationResultProvider`'s shape exactly (`attacksStreamProvider.whenData(engine.analyze)`).
- `lib/features/insights/presentation/widgets/exertion_correlation_card.dart` (+ `_insight.dart`, `_no_variation.dart` parts): mirrors `correlation_card.dart` **minus the premium branch** — no `hasPremiumProvider` check, no `_Teaser`, no `PremiumBadge`. Just `InsightProgressBody` → `_NoVariation`/`_Insight`.
- `insights_screen.dart`: add `ExertionCorrelationCard(result: ref.watch(exertionCorrelationResultProvider))` near `CorrelationCard`, **not** wrapped in `PremiumGate`; add its provider to the pull-to-refresh invalidate list.

**ARB (both `app_en.arb` and `app_vi.arb`)**: `detailsExertionLabel`, `exertionLevelLight`/`Moderate`/`Severe`, `insightsExertionTitle`, `insightsExertionInsufficientData`, `insightsExertionProgressCaption`, `insightsExertionNoVariation`, `insightsExertionSentence`, `insightsExertionAnalyzedCaption` — mirror the existing `insightsCorrelation*`/`insightsDropShareSentence` key set and placement (`app_en.arb` around line 494–540).

## Part B — Step count via HealthKit (premium, same-day join)

**Data source**
- `lib/features/health/data/datasources/step_sample_source.dart` (new): `abstract interface class StepSampleSource { bool get isAvailable; Future<List<StepSample>> stepSamples({required DateTime from, required DateTime to}); }` + `HealthKitStepSampleSource` impl using `HealthDataType.STEPS`. Mirror `sleep_sample_source.dart`'s shape; verify the exact `HealthDataPoint.value` → numeric cast against the pinned `health: 3.0.6` API when writing the code (a `NumericHealthValue.numericValue` read is the expected shape but must be checked against the installed package source, not assumed).
- **Authorization moves from per-source to the repository**, to satisfy "one switch, one sheet": `SleepSampleSource`/`HealthKitSleepSampleSource` drop `requestAuthorization()` from the interface and instead expose a public `static const List<HealthDataType> types` (renamed from the current private `_sleepTypes`). `StepSampleSource`/`HealthKitStepSampleSource` do the same. `HealthKitRepository` owns one `HealthFactory` and implements `requestAuthorization()` itself as a single call: `_health.requestAuthorization([...HealthKitSleepSampleSource.types, ...HealthKitStepSampleSource.types])`. `HealthController.connect()` and everything above it is unaffected — it already just calls `healthRepositoryProvider.requestAuthorization()`.

**Domain**
- `lib/features/health/domain/entities/step_sample.dart`: `StepSample({required DateTime start, required DateTime end, required int count})`, mirrors `sleep_interval.dart`.
- `lib/features/health/domain/entities/step_day.dart`: `StepDay({required DateTime date, required int count})`, mirrors `sleep_night.dart`.
- `lib/features/health/domain/services/step_day_aggregator.dart`: sums `StepSample.count` grouped by the local calendar date of `sample.start`. No overlap-merge step (unlike `SleepNightAggregator`) — steps from HealthKit don't double-count across devices the way sleep sessions do; note this as a deliberate simplification in the doc comment.
- `HealthRepository` interface: add `Future<List<StepDay>> stepDays({required DateTime from, required DateTime to});`. `HealthKitRepository` composes the new source + aggregator alongside the existing sleep ones (constructor gains both).

**Providers**
- `lib/features/health/providers.dart`: add `stepSampleSourceProvider`; wire `HealthKitRepository` with both sources + both aggregators. `healthAvailableProvider`/`healthControllerProvider` stay exactly as they are — still one switch gating both insights.

**iOS config**
- `ios/Runner/Info.plist`: update `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` to mention steps alongside sleep, keeping the existing tone/length, e.g.:
  - Share: "BaroEase reads your sleep and step count from Apple Health to show whether short nights or low activity line up with your migraine attacks. It reads this data only, it stays on this device, and it is never uploaded or shared."
  - Update: unchanged wording pattern, just "sleep and steps" instead of "sleep."
- Flag (don't implement — owner's manual step per CLAUDE.md's "Pending setup" convention): the App Store Connect App Privacy label already declares Health & Fitness data; no new category is added, but re-review the copy against the new usage string before the next submission.

**Insights**
- `lib/features/insights/domain/entities/step_correlation_result.dart`: sealed result, mirrors `sleep_correlation_result.dart` 1:1 (`StepNotConnected`, `StepInsufficientData`, `StepNoVariation`, `StepInsight` with a `shortfall`/`movedLessOnAttackDays`-style getter).
- `lib/features/insights/domain/services/step_correlation_engine.dart`: mirrors `sleep_correlation_engine.dart`, **except the join is same-day**: `attackDates = attacks.map(a => localDate(a.startedAt))`, and a `StepDay` joins if `dateOnly(day.date)` is in that set — no night-cutoff shift. `defaultMinDays = 15`, `defaultMinDaysPerGroup = 3`, `defaultVariationEpsilonSteps` (e.g. 1000 steps), `defaultLookbackDays = 180`.
- `providers.dart` (insights): `stepCorrelationEngineProvider` + `stepCorrelationProvider` (`FutureProvider<StepCorrelationResult>`), mirrors `sleepCorrelationProvider` exactly — gated by `healthControllerProvider`, reads `attacksStreamProvider.future` + `healthRepositoryProvider.stepDays(...)`.
- `lib/features/insights/presentation/widgets/step_correlation_card.dart` (+ parts): mirrors `sleep_correlation_card.dart` exactly — fully premium, no free branch, renders nothing while the read is in flight.
- `insights_screen.dart`: inside the existing `if (ref.watch(healthAvailableProvider))` block, add a second `PremiumGate(lockedIcon: Symbols.directions_walk, lockedMessage: context.l10n.premiumLockedSteps, child: const StepCorrelationCard())` next to the sleep gate; add `stepCorrelationProvider` to the refresh-invalidate list.

**ARB**: `insightsStepsTitle`, `insightsStepsNotConnected`, `insightsStepsInsufficientData`, `insightsStepsProgressCaption`, `insightsStepsNoVariation`, `insightsStepsLessSentence`, `insightsStepsMoreSentence`, `insightsStepsAttackDays`, `insightsStepsRestDays`, `insightsStepsAnalyzedCaption`, `premiumLockedSteps` — mirror the full `insightsSleep*`/`premiumLockedSleep` key set.

## Tests

- `test/features/attacks/attack_repository_test.dart`: extend `fullAttack()` + round-trip assertion for `exertionLevel`.
- `test/db_migration/migration_test.dart`: `database is at schema version 5`, `migrates from v4 to current`, `v4 data survives migration` (existing rows read back with `exertionLevel == null`) — same pattern as the existing v3/v4 blocks.
- `test/features/insights/exertion_correlation_engine_test.dart`: mirrors `correlation_engine_test.dart`'s fixture/group style, one group per sealed state.
- `test/features/health/step_day_aggregator_test.dart`: pure unit test, mirrors `sleep_night_aggregator_test.dart`.
- `test/features/insights/step_correlation_engine_test.dart`: mirrors `sleep_correlation_engine_test.dart`'s fixture style (`attackOn`, a `day(daysAgo, count)` helper, `history({attackDaySteps, restDaySteps})`).
- `test/features/health/health_steps_test.dart`: widget-level, mirrors `health_sleep_test.dart`.

## PLAN.md update (do alongside implementation)

- MVP scope checklist: add a line for physical exertion (free) + HealthKit step correlation (premium), next to the existing `[x] HealthKit read: sleep hours` line.
- §3 Monetization table: Free row gains "physical exertion self-report + correlation"; Premium row's "HealthKit sleep correlation" becomes "HealthKit sleep + step-count correlation."

## Verification (once implemented)

- `melos run gen` (regenerates Drift + l10n), then `melos run analyze` (must be zero findings, both app and `packages/system_design` per CLAUDE.md).
- `melos run test`, scoped to the touched dirs: `test/features/attacks/`, `test/features/health/`, `test/features/insights/`, `test/db_migration/`.
- Manual: log an attack, open "Add details," pick an exertion level, save, reopen the attack detail screen and confirm it reads back. Steps card requires a real iOS device (HealthKit doesn't exist in the Simulator, per the existing CLAUDE.md note) — not verifiable in this environment, call it out rather than claiming it works.
