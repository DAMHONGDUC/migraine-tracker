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
- **Sleep and steps connect separately, one switch and one sheet each**
  (`HealthDataKind`): someone happy to let the app read their nights may not
  want it counting their days, and a refused sheet must cost only the source it
  was asked about. `HealthConnections` holds the two flags, `HealthController`
  owns them, everything else reads `healthControllerProvider`.
- **The switches live on the cards they feed** — sleep on Insights' sleep tab,
  steps on its activity tab, at the top of the chart card — and those are the only
  places permission is asked for, never Settings. The detail screens they used to
  sit on are gone, and so is the Settings group: a switch away from the empty
  chart it fills is a switch nobody connects.
- `HealthController.connectedKey` is the single flag both sources shared before
  the split. It is still read as a fallback, so a user who connected under it is
  not silently disconnected, and the GDPR wipe clears it too (`disconnectAll`)
  so it cannot reconnect them on the next launch.
