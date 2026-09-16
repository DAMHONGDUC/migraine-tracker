# History

- **`HistoryViewToggle`'s thumb is a solid `colorScheme.primary`, and the
  selected glyph inverts to `onPrimary`.** Owner's call. It was a 22%-alpha wash
  with a merely tinted glyph, which over a frosted track on a dark background
  left the two states nearly indistinguishable — and which view you are in is
  the only thing that control says. `onPrimary` is `#1C1C1E`, so the filled thumb
  stays a dark-mode surface rather than a bright one (hard rule 3).
  - The track carries a hairline edge too: frosted glass alone left its bounds
    guessable against the app bar.
  - **`SdSegmentedTabsV2` keeps the quieter 0.22 thumb.** Its segments are
    labelled text in content, where the label already says which is which; this
    one is icon-only chrome.

**The tab always opens on the list** (owner's rule). `AppShell` calls
`HistoryViewModeController.reset()` as the tab is tapped, before the branch is
shown. It has to be done from out there: the tabs are branches of an
`IndexedStack`, so `HistoryScreen` is never rebuilt on a switch and has no
arrival of its own to notice. The filters are untouched — a filter is a
question the user asked and is still asking; a view is where they happened to
leave the screen.

## The filter strip

**One chip per axis, pinned under the app bar** — the same shape as the
medications tab (owner's call, 2026-08-31, reversing a single sheet that held
all of them). Thirteen axes: period, intensity, medication, which medication,
whether it helped, aura, area, duration, symptom, trigger, exertion, notes,
pressure trend.

- **Each axis is ONE choice with its own "All" first**, and `_AxisChip` reads
  that first option as "not filtered" — so a chip is told neither which value
  means all nor whether it is on. `AttackFilters` is thirteen plain values, no
  sets: a chip says which one value is being asked for.
- **A chip shows its axis name while it rests, the picked value once there is
  one, and is highlighted the whole time it is on** (`SdFilterPillV2.active`).
  Thirteen chips all resting would otherwise read "All" thirteen times, and a
  strip where two are narrowing the list has to look different from one where
  none are.
- **The strip never lifts into the app bar** (owner's call):
  `collapsible: false` on `SdCollapsingFilterScaffoldV2`. The strip is where
  the filters are; a bar that takes them over moves them mid-scroll, in the
  middle of reading.
- **`ActiveFilterSummary` (`core/widgets/`) says how many are on, and clears
  them.** A highlighted chip says which axis; only the line says how many, and
  the strip scrolls sideways so the two that are on can both be off screen.
  It sits above the list and above the charts, under the free-plan meter where
  there is one. The medications tab draws the same widget.
- **The three free-text axes offer the user's own words** — medication names,
  symptoms, triggers, deduped case-insensitively by
  `AttackFilterer.textOptions` and matched the same way, since "Nausea" and
  "nausea" were one symptom. A chip whose sheet would hold only "All" is not
  drawn at all.
- **Area is coarse — left / right / front / back, not the fifteen
  `HeadRegion`s.** A single-choice sheet of fifteen areas is a list to scroll
  rather than a filter to read, and the question people ask their record is
  "is it always the left side?". The region lists come from `HeadLocation`, so
  the two cannot drift.
- **The bands are borrowed, never invented.** Intensity is `SeverityBand`, the
  same four the severity donut splits on. Duration splits on 4h and 72h, the
  band ICHD-3 defines a migraine by. The pressure steady band is
  `HomeWidgetConstant.trendThresholdHpa` — the app already draws one line
  between "steady" and "a direction", and a second number here would let the
  home screen widget and this filter disagree about the same reading.
- **"No aura", "not taken", "not recorded" and "no reading" are answers, not
  gaps.** Every axis that can be absent offers its absence, because an attack
  logged offline with no weather is exactly what someone filters for.
- **No strip at all until there is something to filter**, and the calendar
  ignores the filters whatever they are — it is a month, and a filtered month
  with holes in it says nothing.
