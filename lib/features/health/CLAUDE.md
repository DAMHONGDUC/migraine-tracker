# Apple Health

**HealthKit is read-only, iOS-only, and nothing it returns is persisted.**

- **`health` reads `SLEEP_IN_BED` and only that.** This plugin version maps
  IN_BED / ASLEEP / AWAKE onto the same `HKCategoryType.sleepAnalysis` and drops
  the category value before Dart sees it, so asking for all three returns the
  same samples three times and none can be told apart. Take one type and union
  the intervals (`SleepNightAggregator`).
- **Sleep is queried on demand and never written to Drift.** HealthKit is
  already on-device storage, and a copy here would be one more pile of health
  data the wipe has to chase (hard rule 8).
- **An empty read is never an error.** iOS never reports a *read* denial — that
  would leak which conditions a user has — so `requestAuthorization` returning
  true proves only that the sheet was answered. Treat an empty read as "no
  access or no data".
- **Sleep, steps and the cycle connect separately, one switch and one sheet
  each** (`HealthDataKind`): someone happy to let the app read their nights may
  not want it counting their days, and a refused sheet must cost only the source
  it was asked about. `HealthConnections` holds the three flags,
  `HealthController` owns them, everything else reads
  `healthControllerProvider`.
- **The switches live on the cards they feed** — sleep on Insights' sleep tab,
  steps on its activity tab, at the top of the chart card — and those are the only
  places permission is asked for, never Settings. The detail screens they used to
  sit on are gone, and so is the Settings group: a switch away from the empty
  chart it fills is a switch nobody connects.
- **The cycle switch has NO legacy fallback, unlike the other two.** Sleep and
  steps fall back to `HealthController.connectedKey` so a user who connected
  under the old single switch is not silently disconnected; the cycle starts off
  for everybody, because nobody consented to a reproductive-health read under a
  switch that predates it. `PrefsKeyConstant.healthCycle` is its own key.
- **Cycle data never leaves the device**, and never reaches Drift either — it is
  read where a screen shows it and forgotten again. Not in a sync payload, not
  in an export, not in the doctor report. The sync key is server-held (hard rule
  12), so a synced cycle row is a reproductive-health record the backend could
  decrypt, and HealthKit already carries the data across the user's own devices.
  `docs/rules/DECISIONS.md` holds the reasoning; `docs/privacy/` declares it.
- **A period start is HealthKit's own `HKMenstrualCycleStart`, never inferred.**
  Guessing the start from a gap in the samples would invent a cycle out of a
  week the user simply did not log. A day with bleeding and no marker opens no
  window — `cycle_window_test.dart` pins that.
- **The window is day -2 to +3 around that start** (`CycleWindowCalculator`),
  the perimenstrual window menstrual migraine is defined by (ICHD-3 A1.1.1). It
  is deliberately narrow: widen it until most of the month qualifies and every
  attack looks hormonal.
- **The switch lives on the daily check-in**, which is the surface that shows
  what it reads — the same rule that put sleep on the sleep tab.
  `HealthConnectionTile` moved to `core/widgets/` when the third feature needed
  it, because no feature may import another's `presentation/`.
- `HealthController.connectedKey` is the single flag both sources shared before
  the split. It is still read as a fallback, so a user who connected under it is
  not silently disconnected, and the GDPR wipe clears it too (`disconnectAll`)
  so it cannot reconnect them on the next launch.
