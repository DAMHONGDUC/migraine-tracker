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

## What a row shows

**The intensity avatar wears its band's colour, and a pressure tag stands
before the chevron** (2026-09-30 redesign). The tag is the 24h change with an
arrow (`↓ 6.8`): amber (`AppColors.warning`) when falling, muted otherwise, the
direction from `AttackFilterer.pressureTrendOf` so the row and the Pressure
filter cannot disagree. No reading, no tag — a dash would read as a zero.

## The rows the free plan cannot read

**Every attack gets a row; the ones behind the 90-day window are blurred, not
dropped** (owner's rule, 2026-09-21, reversing "hidden from History").
An absence says nothing — a free user could not tell a plan limit from a record
that had never been written. Blurred, the row says something is there, the
`Premium required` tag says what it would take, and the tap says why.
`docs/PREMIUM_RULES.md` is still the authority on the numbers.

- **`AttackTile` decides, off `freeHistoryStartProvider`** — not off a flag its
  callers pass. The list and the calendar both draw it, and a lock handed in
  twice is two places that can disagree about one row.
- **Three lists, and which one a view reads is the whole rule.**
  `attacksStreamProvider` is the whole record (list and calendar rows);
  `historyRowsProvider` is that under the filters (the list);
  `filteredAttacksProvider` is the readable ninety days under the same filters
  (the charts). **The charts stay on the readable window**: a chart averaging
  numbers the user cannot see is a number they cannot check.
- **A locked row is filtered like any other** — it is still a row — but
  `attackFilterOptionsProvider` still reads only the readable set. A chip
  naming a medication off a blurred row would print the very text the blur is
  hiding.
- **The blur and the veil are `PremiumChartLock`'s own numbers**
  (`blurSigma`, `scrimOpacity`), so the app's two locked surfaces read as one
  treatment. The row has no room for that card's centred unlock button — the
  tag carries it, and the veil is only there to stop blurred text reading as a
  render glitch.
- **`ExcludeSemantics` over the blurred row is load bearing.** VoiceOver would
  otherwise read out the intensity and the medication the blur is covering; the
  row's only accessible name is the tag's.
- **`LockedHistorySheet` says nothing about the attack.** The date, the
  intensity and the medication are what the blur covers, so naming any of them
  in the explanation would hand back what the row withholds. It names the
  window instead.
- **`FreeHistoryBanner` stays, AT the boundary rather than above the list**
  (owner's rule, 2026-09-21). Its sentence names a date and says everything
  before it is Premium — that is a statement about a boundary, so it is drawn
  where the boundary is: under the last readable row, over the first blurred
  one. At the top of the list it was a notice to scroll past; there it labels
  the rows beneath it. It is also **outlined** (`SdCardV2.borderColor`),
  which is the design system's own lever for the one banner in a stack to be
  seen first, so the prominence the owner asked for costs no new look.
  - **Compact, with `PremiumUnlockButton` trailing** (owner's rule,
    2026-09-24): a full `SdBannerV2` between rows was taller than the rows it
    labels, and its chevron promised more to read where the only offer is the
    paywall. The whole card still opens the paywall too.
  - **One `SliverList` with the banner as an item**, not three slivers with
    hand-padded seams: the separator then spaces the banner from the rows
    either side of it exactly as it spaces two rows.
  - **`attacks.indexWhere(locks)` is enough to place it** because the list is
    newest-first and the window cuts on time, so every locked row is
    contiguous from that index to the end. A filter that reorders the list
    would break this.
  - **It is gated on THIS list, not on the whole record.** A filter that hides
    every locked row takes the banner with it: a boundary marker with nothing
    under it points at nothing. The dashboard's copy still reads
    `hasHiddenHistoryProvider`, because it has no list to sit inside.

## The filter strip

**One chip per axis, pinned under the app bar** — the same shape as the
medications tab (owner's call, 2026-08-31, reversing a single sheet that held
all of them). Thirteen axes: period, intensity, medication, which medication,
whether it helped, aura, area, duration, symptom, trigger, exertion, notes,
pressure trend.

- **The strip opens with an all-filters pill** (owner's call, 2026-10-05):
  `AllFiltersPill` (`core/widgets/`) opens `AllFiltersSheet` — every axis as an
  `SdFilterSectionV2`, divided by `SdDividerV2`. It sits *beside* the chips,
  not instead of them: a chip is one tap for one axis, the sheet is several
  axes in one pass. Picks only move a highlight; Apply commits them all
  through `AttackFiltersController.apply`, Reset puts the draft back to "all"
  in the sheet.
  - **Reset and Apply sit on one row, halves of it: Reset outlined on the
    left, Apply primary on the right** (owner's rule, 2026-10-06). Both are
    the sheet's answer, so they share the pinned footer rather than stacking
    a text link over the commit; the fill says which one commits. Reset is
    disabled, not hidden, while the draft is already "all".
  - **Both are built from one `_Axis` list** (`_Axes.of`), so a new axis lands
    in the strip and the sheet at once and the two cannot disagree on a label,
    an option or its order.
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
