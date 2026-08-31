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

## The filter sheet

**One bottom sheet holds every filter, and the screen carries one pill**
(owner's call, 2026-08-31). The list can be narrowed twelve ways — period,
intensity, duration, aura, head area, medication, which medication, whether it
helped, symptoms, triggers, exertion, notes, pressure trend — and a chip per
axis on the screen would be a strip that scrolls sideways, which hides exactly
the filters nobody remembers leaving on.

- **Every axis is a `Set`, empty means off, values OR inside an axis and the
  axes AND across.** One shape for twelve axes is what lets `_ChipWrap` draw
  them all and `AttackFilterer` read them in one pass; the alternative was a
  tri-state enum per axis, reading differently in every one. **`period` is the
  exception** and stays a single choice — a window is one window, and "today OR
  this year" is just "this year". It moved out of `HistoryController`, which is
  the view toggle alone now.
- **The pill counts axes, not results.** How many attacks matched is what the
  list shows; what a pill has to say is that something is being hidden at all.
- **Nothing applies until the sheet's button**, which counts what the draft
  would leave ("Show 12 attacks") — a filter that empties the list says so
  before it is committed. **Reset clears the draft in place** rather than
  closing, so the button below it stays the only thing that writes.
- **The free-text sections offer the user's own words** — medication names,
  symptoms, triggers, deduped case-insensitively by `AttackFilterer.textOptions`
  and matched the same way, since "Nausea" and "nausea" were one symptom. A
  section with nothing behind it is not drawn: a heading over no chips reads as
  a screen that failed to load.
- **The bands are borrowed, never invented.** Intensity is `SeverityBand`, the
  same four the severity donut splits on. Duration splits on 4h and 72h, the
  band ICHD-3 defines a migraine by. The pressure steady band is
  `HomeWidgetConstant.trendThresholdHpa` — the app already draws one line
  between "steady" and "a direction", and a second number here would let the
  home screen widget and this filter disagree about the same reading.
- **"No aura", "not taken", "not recorded" and "no reading" are answers, not
  gaps.** Every axis that can be absent offers its absence as a chip, because an
  attack logged offline with no weather is exactly what someone filters for.
- **The calendar still ignores all of it** — it is a month, and a filtered month
  with holes in it says nothing.
